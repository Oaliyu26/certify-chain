;; ------------------------------------------------------------
;; Contract: CertifyChain
;; Type: Decentralized Academic Credential Verification System
;; Network: Stacks Blockchain
;; Version: 1.0
;; Author: [Your Name]
;; ------------------------------------------------------------
;; Description:
;; CertifyChain enables accredited institutions to issue, verify,
;; and revoke academic certificates on-chain. 
;; Each certificate is tied to a student principal, course details,
;; and a unique certificate ID.
;; ------------------------------------------------------------

;; ------------------------------
;; DATA VARIABLES
;; ------------------------------

(define-data-var institution-count uint u0)
(define-data-var certificate-count uint u0)

;; ------------------------------
;; DATA MAPS
;; ------------------------------

;; Registered Institutions
(define-map institutions
  principal
  {
    name: (string-ascii 100),
    verified: bool
  }
)

;; Certificates issued to students
(define-map certificates
  uint
  {
    student: principal,
    institution: principal,
    course: (string-ascii 100),
    grade: (string-ascii 10),
    issue-date: (string-ascii 20),
    valid: bool
  }
)

;; ------------------------------
;; CONSTANTS & ERRORS
;; ------------------------------

(define-constant ERR-NOT-INSTITUTION (err u100))
(define-constant ERR-NOT-VERIFIED (err u101))
(define-constant ERR-CERT-NOT-FOUND (err u102))
(define-constant ERR-NOT-AUTHORIZED (err u103))
(define-constant ERR-ALREADY-REGISTERED (err u104))
(define-constant ERR-ALREADY-VERIFIED (err u105))
(define-constant ERR-NOT-VALID (err u106))

;; ------------------------------
;; INSTITUTION MANAGEMENT
;; ------------------------------

;; Register new institution (Admin only)
(define-public (register-institution (inst principal) (name (string-ascii 100)))
  (begin
    (if (is-some (map-get? institutions inst))
        ERR-ALREADY-REGISTERED
        (begin
          (map-set institutions inst { name: name, verified: false })
          (var-set institution-count (+ u1 (var-get institution-count)))
          (ok "Institution registered successfully")
        )
    )
  )
)

;; Verify an institution (Admin/DAO role in future)
(define-public (verify-institution (inst principal))
  (let ((institution (unwrap! (map-get? institutions inst) ERR-NOT-INSTITUTION)))
    (if (get verified institution)
        ERR-ALREADY-VERIFIED
        (begin
          (map-set institutions inst (merge institution { verified: true }))
          (ok "Institution verified successfully")
        )
    )
  )
)

;; ------------------------------
;; CERTIFICATE MANAGEMENT
;; ------------------------------

;; Issue certificate (Only verified institutions)
(define-public (issue-certificate 
    (student principal) 
    (course (string-ascii 100))
    (grade (string-ascii 10))
    (issue-date (string-ascii 20))
  )
  (let ((issuer (unwrap! (map-get? institutions tx-sender) ERR-NOT-INSTITUTION)))
    (if (not (get verified issuer))
        ERR-NOT-VERIFIED
        (let ((cert-id (+ u1 (var-get certificate-count))))
          (map-set certificates cert-id {
            student: student,
            institution: tx-sender,
            course: course,
            grade: grade,
            issue-date: issue-date,
            valid: true
          })
          (var-set certificate-count cert-id)
          (ok (concat "Certificate issued with ID: " (int-to-ascii cert-id)))
        )
    )
  )
)

;; Revoke a certificate (Institution only)
(define-public (revoke-certificate (cert-id uint))
  (let ((cert (unwrap! (map-get? certificates cert-id) ERR-CERT-NOT-FOUND)))
    (if (is-eq tx-sender (get institution cert))
        (begin
          (map-set certificates cert-id (merge cert { valid: false }))
          (ok "Certificate revoked successfully")
        )
        ERR-NOT-AUTHORIZED
    )
  )
)

;; ------------------------------
;; VERIFICATION FUNCTIONS
;; ------------------------------

(define-read-only (verify-certificate (cert-id uint))
  (let ((cert (map-get? certificates cert-id)))
    (match cert
      cert-data
        (if (get valid cert-data)
            (ok { 
              student: (get student cert-data),
              institution: (get institution cert-data),
              course: (get course cert-data),
              grade: (get grade cert-data),
              issue-date: (get issue-date cert-data),
              valid: (get valid cert-data)
            })
            ERR-NOT-VALID
        )
      (err u404) ;; certificate not found
    )
  )
)

(define-read-only (get-institution (inst principal))
  (map-get? institutions inst)
)

(define-read-only (get-certificate-count)
  (var-get certificate-count)
)

(define-read-only (get-institution-count)
  (var-get institution-count)
)

;; ------------------------------
;; ACCESS CONTROL (Admin Placeholder)
;; ------------------------------

;; In a future DAO or admin version, only an admin wallet 
;; or governance contract would verify institutions.
;; For demo purposes, any caller can register or verify.
;; ------------------------------

;; ------------------------------------------------------------
;; END OF CONTRACT
;; ------------------------------------------------------------
