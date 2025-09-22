;; PixelCraft - Procedural Pixel Art Generation Platform Smart Contract
;; A decentralized platform for creating and minting procedurally generated pixel art NFTs on Stacks

;; Note: This contract implements SIP-009 NFT standard functions
;; For production, you would typically use: (use-trait nft-trait .nft-trait)

;; Constants
(define-constant PLATFORM_ADMIN tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u402))
(define-constant ERR_NOT_FOUND (err u403))
(define-constant ERR_INSUFFICIENT_FUNDS (err u404))
(define-constant ERR_ALGORITHM_UNAVAILABLE (err u405))
(define-constant ERR_MAX_SUPPLY_REACHED (err u406))

;; Data Variables
(define-data-var next-pixel-id uint u1)
(define-data-var platform-fee-rate uint u500) ;; 5% in basis points
(define-data-var max-supply uint u10000)

;; Data Maps
(define-map artist-pixel-count principal uint)
(define-map pixel-art-uri uint (string-ascii 256))
(define-map pixel-algorithm-key uint (string-ascii 64))
(define-map pixel-generation-seed uint uint)
(define-map pixel-art-creator uint principal)
(define-map pixel-creator-royalty uint uint) ;; Royalty percentage in basis points

;; Pixel Art Algorithm registry
(define-map pixel-algorithms (string-ascii 64) {
    developer: principal,
    algorithm-name: (string-ascii 64),
    algorithm-description: (string-ascii 256),
    generation-fee: uint,
    is-active: bool
})

(define-map algorithm-usage-count (string-ascii 64) uint)

;; NFT Implementation
(define-non-fungible-token pixelcraft-nft uint)

;; Get last token ID
(define-read-only (get-latest-pixel-id)
    (ok (- (var-get next-pixel-id) u1))
)

;; Get token URI
(define-read-only (get-pixel-art-uri (pixel-id uint))
    (ok (map-get? pixel-art-uri pixel-id))
)

;; Get NFT owner
(define-read-only (get-pixel-owner (pixel-id uint))
    (ok (nft-get-owner? pixelcraft-nft pixel-id))
)

;; Transfer NFT
(define-public (transfer-pixel-art (pixel-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
        (asserts! (is-some (nft-get-owner? pixelcraft-nft pixel-id)) ERR_NOT_FOUND)
        (nft-transfer? pixelcraft-nft pixel-id sender recipient)
    )
)

;; Register a new pixel art generation algorithm
(define-public (register-pixel-algorithm 
    (algorithm-id (string-ascii 64))
    (algorithm-name (string-ascii 64))
    (algorithm-description (string-ascii 256))
    (generation-fee uint))
    (let ((existing-algorithm (map-get? pixel-algorithms algorithm-id)))
        (asserts! (is-none existing-algorithm) ERR_ALREADY_EXISTS)
        (ok (map-set pixel-algorithms algorithm-id {
            developer: tx-sender,
            algorithm-name: algorithm-name,
            algorithm-description: algorithm-description,
            generation-fee: generation-fee,
            is-active: true
        }))
    )
)

;; Get pixel algorithm details
(define-read-only (get-pixel-algorithm (algorithm-id (string-ascii 64)))
    (map-get? pixel-algorithms algorithm-id)
)

;; Mint a new procedural pixel art NFT
(define-public (craft-pixel-art 
    (algorithm-id (string-ascii 64))
    (generation-seed uint)
    (metadata-uri (string-ascii 256))
    (artist-royalty-rate uint))
    (let (
        (pixel-id (var-get next-pixel-id))
        (algorithm-data (unwrap! (map-get? pixel-algorithms algorithm-id) ERR_ALGORITHM_UNAVAILABLE))
        (algorithm-fee (get generation-fee algorithm-data))
        (algorithm-dev (get developer algorithm-data))
        (platform-cut (/ (* algorithm-fee (var-get platform-fee-rate)) u10000))
        (developer-cut (- algorithm-fee platform-cut))
    )
        ;; Check if max supply reached
        (asserts! (< pixel-id (var-get max-supply)) ERR_MAX_SUPPLY_REACHED)
        
        ;; Check if algorithm is active
        (asserts! (get is-active algorithm-data) ERR_ALGORITHM_UNAVAILABLE)
        
        ;; Check if royalty rate is valid (max 10%)
        (asserts! (<= artist-royalty-rate u1000) ERR_UNAUTHORIZED)
        
        ;; Process payment to algorithm developer and platform
        (if (> algorithm-fee u0)
            (begin
                (try! (stx-transfer? developer-cut tx-sender algorithm-dev))
                (try! (stx-transfer? platform-cut tx-sender PLATFORM_ADMIN))
            )
            true
        )
        
        ;; Mint the NFT pixel art
        (try! (nft-mint? pixelcraft-nft pixel-id tx-sender))
        
        ;; Store pixel art metadata
        (map-set pixel-art-uri pixel-id metadata-uri)
        (map-set pixel-algorithm-key pixel-id algorithm-id)
        (map-set pixel-generation-seed pixel-id generation-seed)
        (map-set pixel-art-creator pixel-id tx-sender)
        (map-set pixel-creator-royalty pixel-id artist-royalty-rate)
        
        ;; Update tracking counters
        (var-set next-pixel-id (+ pixel-id u1))
        (map-set algorithm-usage-count algorithm-id 
            (+ (default-to u0 (map-get? algorithm-usage-count algorithm-id)) u1))
        (map-set artist-pixel-count tx-sender 
            (+ (default-to u0 (map-get? artist-pixel-count tx-sender)) u1))
        
        (ok pixel-id)
    )
)

;; Get pixel art metadata and details
(define-read-only (get-pixel-art-info (pixel-id uint))
    (let (
        (algorithm-id (map-get? pixel-algorithm-key pixel-id))
        (generation-seed (map-get? pixel-generation-seed pixel-id))
        (art-creator (map-get? pixel-art-creator pixel-id))
        (creator-royalty (map-get? pixel-creator-royalty pixel-id))
    )
        (ok {
            algorithm: algorithm-id,
            seed: generation-seed,
            creator: art-creator,
            royalty: creator-royalty
        })
    )
)

;; Get artist's pixel art count
(define-read-only (get-artist-creation-count (artist principal))
    (default-to u0 (map-get? artist-pixel-count artist))
)

;; Get algorithm usage statistics
(define-read-only (get-algorithm-stats (algorithm-id (string-ascii 64)))
    (default-to u0 (map-get? algorithm-usage-count algorithm-id))
)

;; Admin function to update platform fee rate
(define-public (update-platform-fee (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender PLATFORM_ADMIN) ERR_UNAUTHORIZED)
        (asserts! (<= new-rate u2000) ERR_UNAUTHORIZED) ;; Max 20%
        (ok (var-set platform-fee-rate new-rate))
    )
)

;; Admin function to toggle algorithm availability
(define-public (toggle-algorithm-status (algorithm-id (string-ascii 64)))
    (let ((algorithm-data (unwrap! (map-get? pixel-algorithms algorithm-id) ERR_ALGORITHM_UNAVAILABLE)))
        (asserts! (or 
            (is-eq tx-sender PLATFORM_ADMIN) 
            (is-eq tx-sender (get developer algorithm-data))
        ) ERR_UNAUTHORIZED)
        (ok (map-set pixel-algorithms algorithm-id 
            (merge algorithm-data { is-active: (not (get is-active algorithm-data)) })
        ))
    )
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    (ok {
        total-pixels-crafted: (- (var-get next-pixel-id) u1),
        max-supply: (var-get max-supply),
        current-platform-fee: (var-get platform-fee-rate)
    })
)