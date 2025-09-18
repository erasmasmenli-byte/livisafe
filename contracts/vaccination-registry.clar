;; Vaccination Registry - Supporting contract for vaccination history and batch processing
;; Handles vaccination tracking, history management, and batch operations

;; Constants
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-INVALID-INPUT (err u201))
(define-constant ERR-BATCH-NOT-FOUND (err u202))
(define-constant ERR-VACCINATION-EXPIRED (err u203))
(define-constant ERR-ANIMAL-NOT-FOUND (err u204))
(define-constant ERR-BATCH-FULL (err u205))
(define-constant ERR-INVALID-STATUS (err u206))

(define-constant MAX-BATCH-SIZE u100)
(define-constant CONTRACT-OWNER tx-sender)

;; Data Variables
(define-data-var batch-id-counter uint u1)
(define-data-var total-registrations uint u0)

;; Vaccination Batch Information
(define-map vaccination-batches
  uint ;; batch-id
  {
    vaccine-type: (string-ascii 30),
    manufacturer: (string-ascii 40),
    lot-number: (string-ascii 25),
    expiry-date: uint,
    veterinarian: principal,
    created-at: uint,
    animals-count: uint,
    status: (string-ascii 10) ;; "active", "completed", "expired"
  }
)

;; Batch Animal Tracking
(define-map batch-animals
  { batch-id: uint, animal-id: uint }
  {
    vaccination-date: uint,
    status: (string-ascii 10), ;; "pending", "completed", "failed"
    notes: (string-ascii 100)
  }
)

;; Animal Vaccination Schedule
(define-map vaccination-schedules
  uint ;; animal-id
  {
    next-vaccination: uint,
    vaccination-type: (string-ascii 30),
    frequency-days: uint,
    last-updated: uint
  }
)

;; Vaccination Statistics
(define-map vaccination-stats
  (string-ascii 30) ;; vaccine-type
  {
    total-administered: uint,
    success-rate: uint,
    last-batch: uint
  }
)

;; Animal Health Status
(define-map animal-health-status
  uint ;; animal-id
  {
    current-status: (string-ascii 15), ;; "healthy", "vaccinated", "overdue", "quarantine"
    last-checkup: uint,
    vaccinations-count: uint,
    health-score: uint ;; 0-100
  }
)

;; Private Functions

;; Generate next batch ID
(define-private (get-next-batch-id)
  (let ((current-id (var-get batch-id-counter)))
    (var-set batch-id-counter (+ current-id u1))
    current-id
  )
)

;; Validate batch exists and is active
(define-private (validate-batch (batch-id uint))
  (let ((batch-data (map-get? vaccination-batches batch-id)))
    (asserts! (is-some batch-data) ERR-BATCH-NOT-FOUND)
    (let ((batch (unwrap-panic batch-data)))
      (asserts! (is-eq (get status batch) "active") ERR-INVALID-STATUS)
      (asserts! (> (get expiry-date batch) burn-block-height) ERR-VACCINATION-EXPIRED)
      (ok true)
    )
  )
)

;; Calculate health score based on vaccination history
(define-private (calculate-health-score (vaccinations-count uint) (days-since-last uint))
  (let ((base-score (if (> vaccinations-count u0) u80 u20)))
    (if (< days-since-last u30)
        (+ base-score u20)
        (if (< days-since-last u90)
            (+ base-score u10)
            base-score
        )
    )
  )
)

;; Update vaccination statistics
(define-private (update-vaccine-stats (vaccine-type (string-ascii 30)) (batch-id uint))
  (let ((current-stats (default-to { total-administered: u0, success-rate: u100, last-batch: u0 }
                                   (map-get? vaccination-stats vaccine-type))))
    (map-set vaccination-stats vaccine-type {
      total-administered: (+ (get total-administered current-stats) u1),
      success-rate: (get success-rate current-stats),
      last-batch: batch-id
    })
    (ok true)
  )
)

;; Public Functions

;; Create a new vaccination batch
(define-public (create-vaccination-batch 
  (vaccine-type (string-ascii 30))
  (manufacturer (string-ascii 40))
  (lot-number (string-ascii 25))
  (expiry-date uint)
)
  (begin
    (asserts! (> (len vaccine-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len manufacturer) u0) ERR-INVALID-INPUT)
    (asserts! (> (len lot-number) u0) ERR-INVALID-INPUT)
    (asserts! (> expiry-date burn-block-height) ERR-VACCINATION-EXPIRED)
    
    (let ((batch-id (get-next-batch-id)))
      (map-set vaccination-batches batch-id {
        vaccine-type: vaccine-type,
        manufacturer: manufacturer,
        lot-number: lot-number,
        expiry-date: expiry-date,
        veterinarian: tx-sender,
        created-at: burn-block-height,
        animals-count: u0,
        status: "active"
      })
      (ok batch-id)
    )
  )
)

;; Add animal to vaccination batch
(define-public (add-animal-to-batch (batch-id uint) (animal-id uint) (notes (string-ascii 100)))
  (begin
    (try! (validate-batch batch-id))
    (asserts! (> animal-id u0) ERR-ANIMAL-NOT-FOUND)
    
    (let ((batch-data (unwrap-panic (map-get? vaccination-batches batch-id))))
      (asserts! (< (get animals-count batch-data) MAX-BATCH-SIZE) ERR-BATCH-FULL)
      
      ;; Add animal to batch
      (map-set batch-animals { batch-id: batch-id, animal-id: animal-id } {
        vaccination-date: burn-block-height,
        status: "pending",
        notes: notes
      })
      
      ;; Update batch animals count
      (map-set vaccination-batches batch-id 
        (merge batch-data { animals-count: (+ (get animals-count batch-data) u1) })
      )
      
      (ok true)
    )
  )
)

;; Complete vaccination for animal in batch
(define-public (complete-vaccination (batch-id uint) (animal-id uint))
  (begin
    (try! (validate-batch batch-id))
    
    (let ((batch-animal-data (map-get? batch-animals { batch-id: batch-id, animal-id: animal-id })))
      (asserts! (is-some batch-animal-data) ERR-ANIMAL-NOT-FOUND)
      
      (let ((batch-animal (unwrap-panic batch-animal-data))
            (batch-data (unwrap-panic (map-get? vaccination-batches batch-id))))
        
        ;; Update batch animal status
        (map-set batch-animals { batch-id: batch-id, animal-id: animal-id }
          (merge batch-animal { status: "completed" })
        )
        
        ;; Update animal health status
        (let ((current-health (default-to 
                                { current-status: "healthy", last-checkup: u0, vaccinations-count: u0, health-score: u50 }
                                (map-get? animal-health-status animal-id))))
          (map-set animal-health-status animal-id {
            current-status: "vaccinated",
            last-checkup: burn-block-height,
            vaccinations-count: (+ (get vaccinations-count current-health) u1),
            health-score: (calculate-health-score (+ (get vaccinations-count current-health) u1) u0)
          })
        )
        
        ;; Update vaccine statistics
        (unwrap-panic (update-vaccine-stats (get vaccine-type batch-data) batch-id))
        
        (ok true)
      )
    )
  )
)

;; Set vaccination schedule for animal
(define-public (set-vaccination-schedule 
  (animal-id uint) 
  (next-vaccination uint) 
  (vaccination-type (string-ascii 30)) 
  (frequency-days uint)
)
  (begin
    (asserts! (> animal-id u0) ERR-ANIMAL-NOT-FOUND)
    (asserts! (> next-vaccination burn-block-height) ERR-INVALID-INPUT)
    (asserts! (> (len vaccination-type) u0) ERR-INVALID-INPUT)
    (asserts! (> frequency-days u0) ERR-INVALID-INPUT)
    
    (map-set vaccination-schedules animal-id {
      next-vaccination: next-vaccination,
      vaccination-type: vaccination-type,
      frequency-days: frequency-days,
      last-updated: burn-block-height
    })
    (ok true)
  )
)

;; Close vaccination batch
(define-public (close-batch (batch-id uint))
  (begin
    (let ((batch-data (map-get? vaccination-batches batch-id)))
      (asserts! (is-some batch-data) ERR-BATCH-NOT-FOUND)
      (let ((batch (unwrap-panic batch-data)))
        (asserts! (is-eq tx-sender (get veterinarian batch)) ERR-UNAUTHORIZED)
        
        (map-set vaccination-batches batch-id 
          (merge batch { status: "completed" })
        )
        (ok true)
      )
    )
  )
)

;; Read-only Functions

;; Get vaccination batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? vaccination-batches batch-id)
)

;; Get batch animal information
(define-read-only (get-batch-animal (batch-id uint) (animal-id uint))
  (map-get? batch-animals { batch-id: batch-id, animal-id: animal-id })
)

;; Get vaccination schedule for animal
(define-read-only (get-vaccination-schedule (animal-id uint))
  (map-get? vaccination-schedules animal-id)
)

;; Get animal health status
(define-read-only (get-animal-health-status (animal-id uint))
  (map-get? animal-health-status animal-id)
)

;; Get vaccination statistics
(define-read-only (get-vaccine-stats (vaccine-type (string-ascii 30)))
  (map-get? vaccination-stats vaccine-type)
)

;; Check if animal is overdue for vaccination
(define-read-only (is-vaccination-overdue (animal-id uint))
  (let ((schedule (map-get? vaccination-schedules animal-id)))
    (if (is-some schedule)
        (< (get next-vaccination (unwrap-panic schedule)) burn-block-height)
        false
    )
  )
)

;; Get registry statistics
(define-read-only (get-registry-stats)
  {
    total-batches: (- (var-get batch-id-counter) u1),
    total-registrations: (var-get total-registrations)
  }
)

