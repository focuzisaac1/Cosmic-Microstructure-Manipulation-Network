;; Spacetime Configuration NFT Contract

(define-non-fungible-token spacetime-config-nft uint)

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_NFT (err u101))

;; Data variables
(define-data-var last-token-id uint u0)

;; Data maps
(define-map token-metadata
  uint
  {
    creator: principal,
    config-type: (string-ascii 50),
    description: (string-utf8 500),
    complexity: uint,
    stability: uint,
    dimensions: uint,
    creation-time: uint
  }
)

;; Public functions
(define-public (mint-spacetime-config (config-type (string-ascii 50)) (description (string-utf8 500)) (complexity uint) (stability uint) (dimensions uint))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (and (>= stability u0) (<= stability u100)) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= complexity u0) (<= complexity u100)) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= dimensions u1) (<= dimensions u11)) ERR_NOT_AUTHORIZED)
    (try! (nft-mint? spacetime-config-nft token-id tx-sender))
    (map-set token-metadata
      token-id
      {
        creator: tx-sender,
        config-type: config-type,
        description: description,
        complexity: complexity,
        stability: stability,
        dimensions: dimensions,
        creation-time: block-height
      }
    )
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

(define-public (transfer-spacetime-config (token-id uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? spacetime-config-nft token-id) ERR_INVALID_NFT)) ERR_NOT_AUTHORIZED)
    (try! (nft-transfer? spacetime-config-nft token-id tx-sender recipient))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-spacetime-config-metadata (token-id uint))
  (map-get? token-metadata token-id)
)

(define-read-only (get-spacetime-config-owner (token-id uint))
  (nft-get-owner? spacetime-config-nft token-id)
)

(define-read-only (get-last-token-id)
  (var-get last-token-id)
)

