;; Automation Provider Verification Contract
;; Validates and manages industrial automation providers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_NOT_FOUND (err u101))
(define-constant ERR_PROVIDER_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_CERTIFICATION (err u103))

;; Provider data structure
(define-map providers
  { provider-id: uint }
  {
    address: principal,
    name: (string-ascii 50),
    certification-level: uint,
    verified: bool,
    registration-block: uint,
    reputation-score: uint
  }
)

(define-data-var next-provider-id uint u1)

;; Register a new automation provider
(define-public (register-provider (name (string-ascii 50)) (certification-level uint))
  (let ((provider-id (var-get next-provider-id)))
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) ERR_PROVIDER_ALREADY_EXISTS)
    (asserts! (and (>= certification-level u1) (<= certification-level u5)) ERR_INVALID_CERTIFICATION)

    (map-set providers
      { provider-id: provider-id }
      {
        address: tx-sender,
        name: name,
        certification-level: certification-level,
        verified: false,
        registration-block: block-height,
        reputation-score: u50
      }
    )

    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

;; Verify a provider (only contract owner)
(define-public (verify-provider (provider-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { verified: true })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Update reputation score
(define-public (update-reputation (provider-id uint) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-score u100) (err u104))
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { reputation-score: new-score })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Get provider information
(define-read-only (get-provider (provider-id uint))
  (map-get? providers { provider-id: provider-id })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id uint))
  (match (map-get? providers { provider-id: provider-id })
    provider-data (get verified provider-data)
    false
  )
)
