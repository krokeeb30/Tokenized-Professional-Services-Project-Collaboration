;; Service Provider Verification Contract
;; Manages verification and registration of professional service providers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_RATING (err u103))

;; Data structures
(define-map service-providers
  { provider: principal }
  {
    verified: bool,
    specialization: (string-ascii 50),
    rating: uint,
    total-projects: uint,
    registration-block: uint
  }
)

(define-map verification-requests
  { provider: principal }
  {
    requested-at: uint,
    documents-hash: (string-ascii 64),
    status: (string-ascii 20)
  }
)

;; Public functions
(define-public (register-provider (specialization (string-ascii 50)))
  (let ((provider tx-sender))
    (asserts! (is-none (map-get? service-providers { provider: provider })) ERR_ALREADY_VERIFIED)
    (map-set service-providers
      { provider: provider }
      {
        verified: false,
        specialization: specialization,
        rating: u0,
        total-projects: u0,
        registration-block: block-height
      }
    )
    (ok true)
  )
)

(define-public (request-verification (documents-hash (string-ascii 64)))
  (let ((provider tx-sender))
    (asserts! (is-some (map-get? service-providers { provider: provider })) ERR_NOT_FOUND)
    (map-set verification-requests
      { provider: provider }
      {
        requested-at: block-height,
        documents-hash: documents-hash,
        status: "pending"
      }
    )
    (ok true)
  )
)

(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? service-providers { provider: provider })) ERR_NOT_FOUND)
    (map-set service-providers
      { provider: provider }
      (merge (unwrap-panic (map-get? service-providers { provider: provider }))
             { verified: true })
    )
    (map-set verification-requests
      { provider: provider }
      (merge (unwrap-panic (map-get? verification-requests { provider: provider }))
             { status: "approved" })
    )
    (ok true)
  )
)

(define-public (update-provider-rating (provider principal) (new-rating uint))
  (begin
    (asserts! (and (>= new-rating u1) (<= new-rating u5)) ERR_INVALID_RATING)
    (asserts! (is-some (map-get? service-providers { provider: provider })) ERR_NOT_FOUND)
    (map-set service-providers
      { provider: provider }
      (merge (unwrap-panic (map-get? service-providers { provider: provider }))
             { rating: new-rating })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-provider-info (provider principal))
  (map-get? service-providers { provider: provider })
)

(define-read-only (is-verified-provider (provider principal))
  (match (map-get? service-providers { provider: provider })
    provider-data (get verified provider-data)
    false
  )
)

(define-read-only (get-verification-status (provider principal))
  (map-get? verification-requests { provider: provider })
)
