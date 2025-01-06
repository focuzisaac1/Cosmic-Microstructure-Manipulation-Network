;; Experiment Voting System Contract

(define-fungible-token cosmic-token)

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_VOTE (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant VOTING_PERIOD u144) ;; Approximately 1 day in blocks

;; Data variables
(define-data-var vote-count uint u0)

;; Data maps
(define-map experiment-votes
  uint
  {
    experiment-id: uint,
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20)
  }
)

(define-map user-votes
  { vote-id: uint, voter: principal }
  { amount: uint, vote: (string-ascii 10) }
)

;; Public functions
(define-public (create-vote (experiment-id uint))
  (let
    (
      (vote-id (+ (var-get vote-count) u1))
    )
    (map-set experiment-votes
      vote-id
      {
        experiment-id: experiment-id,
        proposer: tx-sender,
        start-block: block-height,
        end-block: (+ block-height VOTING_PERIOD),
        yes-votes: u0,
        no-votes: u0,
        status: "active"
      }
    )
    (var-set vote-count vote-id)
    (ok vote-id)
  )
)

(define-public (cast-vote (vote-id uint) (amount uint) (vote-type (string-ascii 10)))
  (let
    (
      (vote (unwrap! (map-get? experiment-votes vote-id) ERR_INVALID_VOTE))
      (voter tx-sender)
    )
    (asserts! (< block-height (get end-block vote)) ERR_INVALID_VOTE)
    (asserts! (is-eq (get status vote) "active") ERR_INVALID_VOTE)
    (asserts! (or (is-eq vote-type "yes") (is-eq vote-type "no")) ERR_INVALID_VOTE)
    (asserts! (>= (ft-get-balance cosmic-token voter) amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-burn? cosmic-token amount voter))
    (map-set user-votes
      { vote-id: vote-id, voter: voter }
      { amount: amount, vote: vote-type }
    )
    (if (is-eq vote-type "yes")
      (map-set experiment-votes
        vote-id
        (merge vote { yes-votes: (+ (get yes-votes vote) amount) })
      )
      (map-set experiment-votes
        vote-id
        (merge vote { no-votes: (+ (get no-votes vote) amount) })
      )
    )
    (ok true)
  )
)

(define-public (end-vote (vote-id uint))
  (let
    (
      (vote (unwrap! (map-get? experiment-votes vote-id) ERR_INVALID_VOTE))
    )
    (asserts! (>= block-height (get end-block vote)) ERR_INVALID_VOTE)
    (asserts! (is-eq (get status vote) "active") ERR_INVALID_VOTE)
    (ok (map-set experiment-votes
      vote-id
      (merge vote {
        status: (if (> (get yes-votes vote) (get no-votes vote)) "approved" "rejected")
      })
    ))
  )
)

;; Read-only functions
(define-read-only (get-vote (vote-id uint))
  (map-get? experiment-votes vote-id)
)

(define-read-only (get-user-vote (vote-id uint) (voter principal))
  (map-get? user-votes { vote-id: vote-id, voter: voter })
)

(define-read-only (get-vote-count)
  (var-get vote-count)
)

