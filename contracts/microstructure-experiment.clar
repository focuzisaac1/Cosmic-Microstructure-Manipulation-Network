;; Microstructure Manipulation Experiment Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_EXPERIMENT (err u101))
(define-constant ERR_INVALID_STATUS (err u102))

;; Data variables
(define-data-var experiment-count uint u0)

;; Data maps
(define-map microstructure-experiments
  uint
  {
    creator: principal,
    protocol: (string-utf8 1000),
    target-region: (string-ascii 100),
    expected-outcome: (string-utf8 500),
    status: (string-ascii 20),
    risk-level: uint,
    approval-status: (string-ascii 20),
    results: (optional (string-utf8 1000)),
    creation-time: uint,
    execution-time: (optional uint)
  }
)

;; Public functions
(define-public (create-experiment (protocol (string-utf8 1000)) (target-region (string-ascii 100)) (expected-outcome (string-utf8 500)) (risk-level uint))
  (let
    (
      (experiment-id (+ (var-get experiment-count) u1))
    )
    (asserts! (and (>= risk-level u0) (<= risk-level u100)) ERR_NOT_AUTHORIZED)
    (map-set microstructure-experiments
      experiment-id
      {
        creator: tx-sender,
        protocol: protocol,
        target-region: target-region,
        expected-outcome: expected-outcome,
        status: "proposed",
        risk-level: risk-level,
        approval-status: "pending",
        results: none,
        creation-time: block-height,
        execution-time: none
      }
    )
    (var-set experiment-count experiment-id)
    (ok experiment-id)
  )
)

(define-public (approve-experiment (experiment-id uint))
  (let
    (
      (experiment (unwrap! (map-get? microstructure-experiments experiment-id) ERR_INVALID_EXPERIMENT))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get approval-status experiment) "pending") ERR_INVALID_STATUS)
    (ok (map-set microstructure-experiments
      experiment-id
      (merge experiment {
        approval-status: "approved",
        status: "ready"
      })
    ))
  )
)

(define-public (execute-experiment (experiment-id uint))
  (let
    (
      (experiment (unwrap! (map-get? microstructure-experiments experiment-id) ERR_INVALID_EXPERIMENT))
    )
    (asserts! (is-eq (get approval-status experiment) "approved") ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status experiment) "ready") ERR_INVALID_STATUS)
    (ok (map-set microstructure-experiments
      experiment-id
      (merge experiment {
        status: "in-progress",
        execution-time: (some block-height)
      })
    ))
  )
)

(define-public (update-experiment-results (experiment-id uint) (results (string-utf8 1000)))
  (let
    (
      (experiment (unwrap! (map-get? microstructure-experiments experiment-id) ERR_INVALID_EXPERIMENT))
    )
    (asserts! (is-eq tx-sender (get creator experiment)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status experiment) "in-progress") ERR_INVALID_STATUS)
    (ok (map-set microstructure-experiments
      experiment-id
      (merge experiment {
        status: "completed",
        results: (some results)
      })
    ))
  )
)

;; Read-only functions
(define-read-only (get-experiment (experiment-id uint))
  (map-get? microstructure-experiments experiment-id)
)

(define-read-only (get-experiment-count)
  (var-get experiment-count)
)

