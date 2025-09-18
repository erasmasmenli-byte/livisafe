;; Livisafe Core - Tokenized Livestock Vaccination System
;; Main contract for managing animal registration and vaccination records

;; Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ANIMAL-NOT-FOUND (err u101))
(define-constant ERR-ANIMAL-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-VETERINARIAN (err u103))
(define-constant ERR-VACCINATION-NOT-FOUND (err u104))
(define-constant ERR-CERTIFICATE-NOT-FOUND (err u105))
(define-constant ERR-INVALID-INPUT (err u106))
(define-constant ERR-SYSTEM-PAUSED (err u107))
(define-constant ERR-INVALID-DATE (err u108))
(define-constant ERR-DUPLICATE-VACCINATION (err u109))

(define-constant CONTRACT-OWNER tx-sender)

;; Data Variables
(define-data-var animal-id-counter uint u1)
(define-data-var vaccination-id-counter uint u1)
(define-data-var certificate-id-counter uint u1)
(define-data-var system-paused bool false)

;; Data Maps
;; Animal registry: stores animal information
(define-map animals
  uint ;; animal-id
  {
    owner: principal,
    species: (string-ascii 20),
    age: uint,
    gender: (string-ascii 10),
    registration-date: uint,
    active: bool
  }
)

;; Vaccination records: stores vaccination information
(define-map vaccinations
  uint ;; vaccination-id
  {
    animal-id: uint,
    vaccine-type: (string-ascii 30),
    vaccine-batch: (string-ascii 20),
    veterinarian: principal,
    vaccination-date: uint,
    expiry-date: uint,
    notes: (string-ascii 100),
    active: bool
  }
)

;; Vaccination certificates: stores certificate information
(define-map certificates
  uint ;; certificate-id
  {
    animal-id: uint,
    vaccination-id: uint,
    issue-date: uint,
    valid-until: uint,
    issued-by: principal,
    verified: bool
  }
)

;; Authorized veterinarians
(define-map veterinarians
  principal ;; vet-address
  {
    name: (string-ascii 50),
    license-number: (string-ascii 30),
    authorized: bool,
    registration-date: uint
  }
)

;; Animal vaccination history tracking
(define-map animal-vaccination-history
  { animal-id: uint, vaccination-id: uint }
  bool
)

;; Private Functions

;; Check if system is paused
(define-private (check-system-active)
  (if (var-get system-paused)
    ERR-SYSTEM-PAUSED
    (ok true)
  )
)

;; Validate animal exists and is active
(define-private (validate-animal (animal-id uint))
  (let ((animal-data (map-get? animals animal-id)))
    (asserts! (is-some animal-data) ERR-ANIMAL-NOT-FOUND)
    (asserts! (get active (unwrap-panic animal-data)) ERR-ANIMAL-NOT-FOUND)
    (ok true)
  )
)

;; Validate veterinarian is authorized
(define-private (validate-veterinarian (vet principal))
  (let ((vet-data (map-get? veterinarians vet)))
    (asserts! (is-some vet-data) ERR-INVALID-VETERINARIAN)
    (asserts! (get authorized (unwrap-panic vet-data)) ERR-INVALID-VETERINARIAN)
    (ok true)
  )
)

;; Generate next animal ID
(define-private (get-next-animal-id)
  (let ((current-id (var-get animal-id-counter)))
    (var-set animal-id-counter (+ current-id u1))
    current-id
  )
)

;; Generate next vaccination ID
(define-private (get-next-vaccination-id)
  (let ((current-id (var-get vaccination-id-counter)))
    (var-set vaccination-id-counter (+ current-id u1))
    current-id
  )
)

;; Generate next certificate ID
(define-private (get-next-certificate-id)
  (let ((current-id (var-get certificate-id-counter)))
    (var-set certificate-id-counter (+ current-id u1))
    current-id
  )
)

;; Public Functions

;; Register a new animal
(define-public (register-animal (species (string-ascii 20)) (age uint) (gender (string-ascii 10)))
  (begin
    (try! (check-system-active))
    (asserts! (> (len species) u0) ERR-INVALID-INPUT)
    (asserts! (> (len gender) u0) ERR-INVALID-INPUT)
    (asserts! (> age u0) ERR-INVALID-INPUT)
    
    (let ((animal-id (get-next-animal-id)))
      (map-set animals animal-id {
        owner: tx-sender,
        species: species,
        age: age,
        gender: gender,
        registration-date: burn-block-height,
        active: true
      })
      (ok animal-id)
    )
  )
)

;; Register a new veterinarian (only contract owner)
(define-public (register-veterinarian (vet principal) (name (string-ascii 50)) (license (string-ascii 30)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len license) u0) ERR-INVALID-INPUT)
    
    (map-set veterinarians vet {
      name: name,
      license-number: license,
      authorized: true,
      registration-date: burn-block-height
    })
    (ok true)
  )
)

;; Record a vaccination
(define-public (record-vaccination 
  (animal-id uint) 
  (vaccine-type (string-ascii 30)) 
  (vaccine-batch (string-ascii 20)) 
  (expiry-date uint) 
  (notes (string-ascii 100))
)
  (begin
    (try! (check-system-active))
    (try! (validate-animal animal-id))
    (try! (validate-veterinarian tx-sender))
    (asserts! (> (len vaccine-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len vaccine-batch) u0) ERR-INVALID-INPUT)
    (asserts! (> expiry-date burn-block-height) ERR-INVALID-DATE)
    
    (let ((vaccination-id (get-next-vaccination-id)))
      (map-set vaccinations vaccination-id {
        animal-id: animal-id,
        vaccine-type: vaccine-type,
        vaccine-batch: vaccine-batch,
        veterinarian: tx-sender,
        vaccination-date: burn-block-height,
        expiry-date: expiry-date,
        notes: notes,
        active: true
      })
      ;; Track in animal's vaccination history
      (map-set animal-vaccination-history { animal-id: animal-id, vaccination-id: vaccination-id } true)
      (ok vaccination-id)
    )
  )
)

;; Issue a vaccination certificate
(define-public (issue-certificate (animal-id uint) (vaccination-id uint) (valid-until uint))
  (begin
    (try! (check-system-active))
    (try! (validate-animal animal-id))
    (try! (validate-veterinarian tx-sender))
    (asserts! (> valid-until burn-block-height) ERR-INVALID-DATE)
    
    (let ((vaccination-data (map-get? vaccinations vaccination-id)))
      (asserts! (is-some vaccination-data) ERR-VACCINATION-NOT-FOUND)
      (asserts! (is-eq (get animal-id (unwrap-panic vaccination-data)) animal-id) ERR-INVALID-INPUT)
      
      (let ((certificate-id (get-next-certificate-id)))
        (map-set certificates certificate-id {
          animal-id: animal-id,
          vaccination-id: vaccination-id,
          issue-date: burn-block-height,
          valid-until: valid-until,
          issued-by: tx-sender,
          verified: true
        })
        (ok certificate-id)
      )
    )
  )
)

;; Verify a certificate
(define-public (verify-certificate (certificate-id uint))
  (let ((cert-data (map-get? certificates certificate-id)))
    (asserts! (is-some cert-data) ERR-CERTIFICATE-NOT-FOUND)
    (let ((cert (unwrap-panic cert-data)))
      (asserts! (get verified cert) ERR-CERTIFICATE-NOT-FOUND)
      (asserts! (> (get valid-until cert) burn-block-height) ERR-CERTIFICATE-NOT-FOUND)
      (ok cert)
    )
  )
)

;; Transfer animal ownership
(define-public (transfer-animal (animal-id uint) (new-owner principal))
  (begin
    (try! (check-system-active))
    (let ((animal-data (map-get? animals animal-id)))
      (asserts! (is-some animal-data) ERR-ANIMAL-NOT-FOUND)
      (let ((animal (unwrap-panic animal-data)))
        (asserts! (is-eq tx-sender (get owner animal)) ERR-UNAUTHORIZED)
        (map-set animals animal-id (merge animal { owner: new-owner }))
        (ok true)
      )
    )
  )
)

;; Pause/unpause system (only contract owner)
(define-public (toggle-system-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set system-paused (not (var-get system-paused)))
    (ok (var-get system-paused))
  )
)

;; Read-only Functions

;; Get animal information
(define-read-only (get-animal (animal-id uint))
  (map-get? animals animal-id)
)

;; Get vaccination information
(define-read-only (get-vaccination (vaccination-id uint))
  (map-get? vaccinations vaccination-id)
)

;; Get certificate information
(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates certificate-id)
)

;; Get veterinarian information
(define-read-only (get-veterinarian (vet principal))
  (map-get? veterinarians vet)
)

;; Check if vaccination exists for animal
(define-read-only (has-vaccination (animal-id uint) (vaccination-id uint))
  (default-to false (map-get? animal-vaccination-history { animal-id: animal-id, vaccination-id: vaccination-id }))
)

;; Get system status
(define-read-only (get-system-status)
  {
    paused: (var-get system-paused),
    total-animals: (- (var-get animal-id-counter) u1),
    total-vaccinations: (- (var-get vaccination-id-counter) u1),
    total-certificates: (- (var-get certificate-id-counter) u1)
  }
)

