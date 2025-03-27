;; Device Registration Contract
;; Tracks medical equipment available for sharing among rural clinics

(define-data-var last-device-id uint u0)

;; Device status: 1=available, 2=in-use, 3=maintenance, 4=decommissioned
(define-map devices
  { device-id: uint }
  {
    name: (string-ascii 64),
    device-type: (string-ascii 32),
    manufacturer: (string-ascii 64),
    model: (string-ascii 32),
    serial-number: (string-ascii 32),
    acquisition-date: uint,
    status: uint,
    current-location: principal,
    owner: principal
  }
)

;; Register a new device
(define-public (register-device
    (name (string-ascii 64))
    (device-type (string-ascii 32))
    (manufacturer (string-ascii 64))
    (model (string-ascii 32))
    (serial-number (string-ascii 32))
    (acquisition-date uint))
  (let
    ((new-id (+ (var-get last-device-id) u1)))
    (begin
      (var-set last-device-id new-id)
      (map-set devices
        { device-id: new-id }
        {
          name: name,
          device-type: device-type,
          manufacturer: manufacturer,
          model: model,
          serial-number: serial-number,
          acquisition-date: acquisition-date,
          status: u1, ;; Available by default
          current-location: tx-sender,
          owner: tx-sender
        }
      )
      (ok new-id)
    )
  )
)

;; Update device status
(define-public (update-device-status (device-id uint) (new-status uint))
  (let
    ((device (unwrap! (map-get? devices { device-id: device-id }) (err u404))))
    (if (or (is-eq tx-sender (get owner device)) (is-eq tx-sender (get current-location device)))
      (begin
        (map-set devices
          { device-id: device-id }
          (merge device { status: new-status })
        )
        (ok true)
      )
      (err u403)
    )
  )
)

;; Update device location
(define-public (update-device-location (device-id uint) (new-location principal))
  (let
    ((device (unwrap! (map-get? devices { device-id: device-id }) (err u404))))
    (if (or (is-eq tx-sender (get owner device)) (is-eq tx-sender (get current-location device)))
      (begin
        (map-set devices
          { device-id: device-id }
          (merge device {
            current-location: new-location,
            status: u2 ;; Set to in-use
          })
        )
        (ok true)
      )
      (err u403)
    )
  )
)

;; Get device details
(define-read-only (get-device (device-id uint))
  (map-get? devices { device-id: device-id })
)

;; Check if device is available
(define-read-only (is-device-available (device-id uint))
  (let
    ((device (unwrap! (map-get? devices { device-id: device-id }) (err u404))))
    (ok (is-eq (get status device) u1))
  )
)
