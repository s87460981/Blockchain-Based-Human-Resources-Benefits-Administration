;; Benefits Administrator Verification Contract
;; Manages and validates HR benefits administrators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_NOT_FOUND (err u404))

;; Data structures
(define-map administrators
  { admin-id: principal }
  {
    name: (string-ascii 100),
    organization: (string-ascii 100),
    verified: bool,
    created-at: uint,
    verification-level: uint
  }
)

(define-map admin-permissions
  { admin-id: principal }
  {
    can-enroll: bool,
    can-process-claims: bool,
    can-manage-providers: bool,
    can-optimize-costs: bool
  }
)

(define-data-var total-admins uint u0)

;; Public functions
(define-public (register-administrator (name (string-ascii 100)) (organization (string-ascii 100)))
  (let ((admin-id tx-sender))
    (asserts! (is-none (map-get? administrators { admin-id: admin-id })) ERR_ALREADY_EXISTS)
    (map-set administrators
      { admin-id: admin-id }
      {
        name: name,
        organization: organization,
        verified: false,
        created-at: block-height,
        verification-level: u1
      }
    )
    (map-set admin-permissions
      { admin-id: admin-id }
      {
        can-enroll: false,
        can-process-claims: false,
        can-manage-providers: false,
        can-optimize-costs: false
      }
    )
    (var-set total-admins (+ (var-get total-admins) u1))
    (ok admin-id)
  )
)

(define-public (verify-administrator (admin-id principal) (verification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? administrators { admin-id: admin-id })) ERR_NOT_FOUND)
    (map-set administrators
      { admin-id: admin-id }
      (merge (unwrap-panic (map-get? administrators { admin-id: admin-id }))
        { verified: true, verification-level: verification-level }
      )
    )
    (update-permissions admin-id verification-level)
    (ok true)
  )
)

(define-private (update-permissions (admin-id principal) (level uint))
  (map-set admin-permissions
    { admin-id: admin-id }
    {
      can-enroll: (>= level u2),
      can-process-claims: (>= level u3),
      can-manage-providers: (>= level u4),
      can-optimize-costs: (>= level u5)
    }
  )
)

;; Read-only functions
(define-read-only (get-administrator (admin-id principal))
  (map-get? administrators { admin-id: admin-id })
)

(define-read-only (is-verified-admin (admin-id principal))
  (match (map-get? administrators { admin-id: admin-id })
    admin (get verified admin)
    false
  )
)

(define-read-only (get-admin-permissions (admin-id principal))
  (map-get? admin-permissions { admin-id: admin-id })
)

(define-read-only (get-total-admins)
  (var-get total-admins)
)
