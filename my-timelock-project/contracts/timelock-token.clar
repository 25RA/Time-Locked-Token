;; Time-Locked Fungible Token
;; This is a simple fungible token with a key feature:
;; it cannot be transferred until a certain block height has been reached.

;; --- Constants and Data Types ---

;; Define the error codes that the contract can return.
;; An error code is just a number that tells the user what went wrong.
(define-constant ERR_NOT_LOCKED u1)
(define-constant ERR_NOT_OWNER u2)
(define-constant ERR_NOT_UNLOCKED u3)
(define-constant ERR_INSUFFICIENT_FUNDS u4)
(define-constant ERR_INVALID_BLOCK_HEIGHT u5)

;; Define the fungible token trait. This is a standard for all fungible tokens.
;; It defines the functions a token must have.
(define-trait ft-trait
  (
    (ft-transfer? (uint principal principal) (response bool uint))
  )
)

;; The block height at which the token will become transferable.
;; For a real-world project, you would set this to a block height in the future.
;; For testing, you can set it to a low number, like u0.
(define-constant lock-block-height u2000)

;; --- Fungible Token Definition ---

;; Define the fungible token itself. We'll call it "timelock-token".
(define-fungible-token timelock-token)

;; --- Public Functions ---

;; This is the core transfer function for the token.
;; It overrides the standard transfer to add our time-lock logic.
;; It takes the amount to transfer, the sender, and the recipient.
(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    ;; First, check if the current block height is greater than or equal to the lock height.
    ;; The contract will fail if this condition is not met.
    (asserts! (>= block-height lock-block-height)
              (err ERR_NOT_UNLOCKED))

    ;; Then, perform the actual token transfer.
    ;; The `try!` macro will stop execution if the transfer fails (e.g., insufficient funds).
    (try! (ft-transfer? timelock-token amount sender recipient))

    ;; If the transfer is successful, return a response with 'ok' and a 'true' value.
    (ok true)
  )
)

;; A function to mint the initial supply of tokens.
;; This function is only callable by the contract owner.
(define-public (mint (amount uint) (recipient principal))
  (begin
    ;; Check that the transaction sender is the contract owner.
    (asserts! (is-eq tx-sender (as-contract tx-sender)) (err ERR_NOT_OWNER))

    ;; Mint the tokens and send them to the recipient.
    (try! (ft-mint? timelock-token amount recipient))

    (ok true)
  )
)

;; --- Read-Only Functions ---

;; A read-only function to check the current total supply of tokens.
(define-read-only (get-total-supply)
  (ok (ft-get-supply timelock-token))
)

;; A read-only function to get a user's balance.
(define-read-only (get-balance (owner principal))
  (ok (ft-get-balance timelock-token owner))
)

;; A read-only function to get the lock block height.
(define-read-only (get-lock-block-height)
  (ok lock-block-height)
)

;; A read-only function to get the current block height.
(define-read-only (get-current-block-height)
  (ok block-height)
)

