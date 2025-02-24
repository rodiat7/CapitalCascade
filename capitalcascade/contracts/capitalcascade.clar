;; CapitalCascade - Decentralized P2P Lending Protocol
;; A decentralized lending platform on Stacks blockchain for STX lending

;; Error codes
(define-constant ERROR-NOT-AUTHORIZED (err u100))
(define-constant ERROR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERROR-NO-LOAN (err u102))
(define-constant ERROR-LOAN-EXISTS (err u103))
(define-constant ERROR-INSUFFICIENT-COLLATERAL (err u104))
(define-constant ERROR-LOAN-ACTIVE (err u105))
(define-constant ERROR-DEFAULTED (err u106))
(define-constant ERROR-BAD-AMOUNT (err u107))
(define-constant ERROR-PAYMENT-TOO-SMALL (err u108))
(define-constant ERROR-LOAN-HEALTHY (err u109))

;; Constants
(define-constant BLOCKS-PER-DAY u144) ;; Approximate number of blocks per day
(define-constant PENALTY-RATE u10) ;; 10% fee rate for late payments
(define-constant THRESHOLD-RATIO u130) ;; 130% minimum collateral ratio before liquidation

;; Status constants
(define-constant STATUS-PENDING "PENDING")
(define-constant STATUS-ACTIVE "ACTIVE")
(define-constant STATUS-FINISHED "FINISHED")
(define-constant STATUS-LIQUIDATED "LIQUIDATED")
(define-constant STATUS-CANCELED "CANCELED")

;; Data variables
(define-data-var collateral-ratio uint u150) ;; 150% collateralization ratio
(define-data-var platform-owner principal tx-sender)

;; Loan data structure
(define-map loans
    {loan-id: uint}
    {
        borrower: principal,
        lender: (optional principal),
        loan-amount: uint,
        collateral-amount: uint,
        interest-rate: uint,
        duration: uint,
        start-block: uint,
        last-payment-block: uint,
        payment-interval: uint,
        payment-amount: uint,
        remaining-debt: uint,
        status: (string-ascii 20)
    }
)

;; Payment tracking
(define-map payment-schedule
    {loan-id: uint}
    {
        due-block: uint,
        missed-payments: uint,
        accumulated-fees: uint
    }
)

;; Protocol state variables
(define-data-var loan-counter uint u1)
(define-data-var platform-holdings uint u0)

;; Read-only functions
(define-read-only (get-loan (loan-id uint))
    (map-get? loans {loan-id: loan-id})
)

(define-read-only (get-payment-schedule (loan-id uint))
    (map-get? payment-schedule {loan-id: loan-id})
)

(define-read-only (calculate-collateral-ratio (collateral uint) (debt uint))
    (let
        (
            (ratio (* (/ collateral debt) u100))
        )
        ratio
    )
)

(define-read-only (get-loan-health (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) u0))
            (ratio (calculate-collateral-ratio (get collateral-amount loan) (get remaining-debt loan)))
        )
        ratio
    )
)

(define-read-only (should-liquidate (loan-id uint))
    (let
        (
            (current-ratio (get-loan-health loan-id))
        )
        (< current-ratio THRESHOLD-RATIO)
    )
)

;; Private functions
(define-private (calculate-penalty (payment uint))
    (/ (* payment PENALTY-RATE) u100)
)

(define-private (initialize-schedule (loan-id uint) (initial-block uint) (period uint))
    (begin
        (map-set payment-schedule
            {loan-id: loan-id}
            {
                due-block: (+ initial-block period),
                missed-payments: u0,
                accumulated-fees: u0
            }
        )
        true
    )
)

;; Public functions
(define-public (request-loan (amount uint) (collateral uint) (rate uint) (term uint) (frequency uint))
    (let
        (
            (loan-id (var-get loan-counter))
            (collateral-check (calculate-collateral-ratio collateral amount))
            (installment (/ (+ amount (* amount rate)) term))
        )
        (asserts! (>= collateral-check (var-get collateral-ratio)) ERROR-INSUFFICIENT-COLLATERAL)
        (asserts! (> amount u0) ERROR-BAD-AMOUNT)
        (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
        
        (var-set platform-holdings (+ (var-get platform-holdings) collateral))
        
        (map-set loans
            {loan-id: loan-id}
            {
                borrower: tx-sender,
                lender: none,
                loan-amount: amount,
                collateral-amount: collateral,
                interest-rate: rate,
                duration: term,
                start-block: u0,
                last-payment-block: u0,
                payment-interval: frequency,
                payment-amount: installment,
                remaining-debt: amount,
                status: STATUS-PENDING
            }
        )
        (var-set loan-counter (+ loan-id u1))
        (ok loan-id)
    )
)

(define-public (fund-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERROR-NO-LOAN))
            (amount (get loan-amount loan))
        )
        (asserts! (is-eq (get status loan) STATUS-PENDING) ERROR-LOAN-EXISTS)
        (try! (stx-transfer? amount tx-sender (get borrower loan)))
        
        (map-set loans
            {loan-id: loan-id}
            (merge loan {
                lender: (some tx-sender),
                start-block: block-height,
                last-payment-block: block-height,
                status: STATUS-ACTIVE
            })
        )
        
        (asserts! (initialize-schedule loan-id block-height (get payment-interval loan)) ERROR-NO-LOAN)
        
        (ok true)
    )
)

(define-public (make-payment (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERROR-NO-LOAN))
            (schedule (unwrap! (get-payment-schedule loan-id) ERROR-NO-LOAN))
            (payment (get payment-amount loan))
            (lender (unwrap! (get lender loan) ERROR-NO-LOAN))
            (fee (if (>= block-height (get due-block schedule))
                    (calculate-penalty payment)
                    u0))
            (total-payment (+ payment fee))
        )
        (asserts! (is-eq (get status loan) STATUS-ACTIVE) ERROR-NO-LOAN)
        (asserts! (is-eq (get borrower loan) tx-sender) ERROR-NOT-AUTHORIZED)
        
        (try! (stx-transfer? total-payment tx-sender lender))
        
        (map-set loans
            {loan-id: loan-id}
            (merge loan {
                last-payment-block: block-height,
                remaining-debt: (- (get remaining-debt loan) payment)
            })
        )
        
        (map-set payment-schedule
            {loan-id: loan-id}
            (merge schedule {
                due-block: (+ block-height (get payment-interval loan)),
                accumulated-fees: (+ (get accumulated-fees schedule) fee)
            })
        )
        
        (ok true)
    )
)

(define-public (execute-liquidation (loan-id uint))
    (let
        (
            (loan (unwrap! (get-loan loan-id) ERROR-NO-LOAN))
            (schedule (unwrap! (get-payment-schedule loan-id) ERROR-NO-LOAN))
            (lender (unwrap! (get lender loan) ERROR-NO-LOAN))
            (needs-liquidation (should-liquidate loan-id))
        )
        (asserts! needs-liquidation ERROR-LOAN-HEALTHY)
        
        (as-contract
            (try! (stx-transfer? (get collateral-amount loan) lender tx-sender))
        )
        
        (var-set platform-holdings (- (var-get platform-holdings) (get collateral-amount loan)))
        
        (map-set loans
            {loan-id: loan-id}
            (merge loan {
                status: STATUS-LIQUIDATED
            })
        )
        
        (ok true)
    )
)

;; Admin functions
(define-public (update-collateral-ratio (new-ratio uint))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-owner)) ERROR-NOT-AUTHORIZED)
        (var-set collateral-ratio new-ratio)
        (ok true)
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-owner)) ERROR-NOT-AUTHORIZED)
        (var-set platform-owner new-owner)
        (ok true)
    )
)