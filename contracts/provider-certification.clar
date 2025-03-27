;; Provider Certification Contract
;; Validates healthcare provider qualifications for specific equipment

;; Certification status: 1=pending, 2=approved, 3=expired, 4=revoked
(define-map certifications
  { provider: principal, device-type: (string-ascii 32) }
  {
    certification-id: (string-ascii 32),
    issuer: principal,
    issue-date: uint,
    expiry-date: uint,
    status: uint
  }
)

;; Authorized certification issuers
(define-map authorized-issuers
  { issuer: principal }
  { is-authorized: bool }
)

;; Initialize contract owner as authorized issuer
(define-data-var contract-owner principal tx-sender)

(begin
  (map-set authorized-issuers
    { issuer: tx-sender }
    { is-authorized: true }
  )
)

;; Add a new authorized issuer
(define-public (add-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (map-set authorized-issuers
      { issuer: issuer }
      { is-authorized: true }
    )
    (ok true)
  )
)

;; Issue a certification
(define-public (issue-certification
    (provider principal)
    (device-type (string-ascii 32))
    (certification-id (string-ascii 32))
    (issue-date uint)
    (expiry-date uint))
  (begin
    (asserts! (is-authorized-issuer tx-sender) (err u403))
    (asserts! (> expiry-date issue-date) (err u400))
    (map-set certifications
      { provider: provider, device-type: device-type }
      {
        certification-id: certification-id,
        issuer: tx-sender,
        issue-date: issue-date,
        expiry-date: expiry-date,
        status: u2 ;; Approved
      }
    )
    (ok true)
  )
)

;; Update certification status
(define-public (update-certification-status
    (provider principal)
    (device-type (string-ascii 32))
    (new-status uint))
  (begin
    (asserts! (is-authorized-issuer tx-sender) (err u403))
    (let
      ((cert (unwrap! (map-get? certifications { provider: provider, device-type: device-type }) (err u404))))
      (map-set certifications
        { provider: provider, device-type: device-type }
        (merge cert { status: new-status })
      )
      (ok true)
    )
  )
)

;; Check if a provider is certified for a device type
(define-read-only (is-certified (provider principal) (device-type (string-ascii 32)))
  (let
    ((cert (map-get? certifications { provider: provider, device-type: device-type })))
    (if (is-some cert)
      (let
        ((unwrapped-cert (unwrap! cert (err u404))))
        (ok (and
          (is-eq (get status unwrapped-cert) u2) ;; Status is approved
          (> (get expiry-date unwrapped-cert) block-height) ;; Not expired
        ))
      )
      (ok false)
    )
  )
)

;; Helper function to check if sender is an authorized issuer
(define-read-only (is-authorized-issuer (issuer principal))
  (default-to false (get is-authorized (map-get? authorized-issuers { issuer: issuer })))
)

;; Get certification details
(define-read-only (get-certification (provider principal) (device-type (string-ascii 32)))
  (map-get? certifications { provider: provider, device-type: device-type })
)
