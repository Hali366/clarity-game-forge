;; GameForge - Multiplayer Game Platform Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-game (err u101))
(define-constant err-game-full (err u102))
(define-constant err-not-player (err u103))
(define-constant err-invalid-move (err u104))

;; Data Variables
(define-data-var next-game-id uint u0)

;; Data Maps
(define-map games
    uint 
    {
        creator: principal,
        game-type: (string-ascii 20),
        max-players: uint,
        current-players: uint,
        state: (string-ascii 20),
        created-at: uint
    }
)

(define-map game-players
    { game-id: uint, player: principal }
    {
        joined-at: uint,
        score: uint,
        last-move: uint
    }
)

;; Public Functions

;; Create a new game
(define-public (create-game (game-type (string-ascii 20)) (max-players uint))
    (let
        (
            (game-id (var-get next-game-id))
        )
        (map-set games game-id {
            creator: tx-sender,
            game-type: game-type,
            max-players: max-players,
            current-players: u1,
            state: "active",
            created-at: block-height
        })
        (map-set game-players 
            { game-id: game-id, player: tx-sender }
            {
                joined-at: block-height,
                score: u0,
                last-move: u0
            }
        )
        (var-set next-game-id (+ game-id u1))
        (ok game-id)
    )
)

;; Join an existing game
(define-public (join-game (game-id uint))
    (let
        (
            (game (unwrap! (map-get? games game-id) (err err-invalid-game)))
            (current-players (get current-players game))
            (max-players (get max-players game))
        )
        (asserts! (< current-players max-players) (err err-game-full))
        (map-set games game-id (merge game {
            current-players: (+ current-players u1)
        }))
        (map-set game-players
            { game-id: game-id, player: tx-sender }
            {
                joined-at: block-height,
                score: u0,
                last-move: u0
            }
        )
        (ok true)
    )
)

;; Make a move in a game
(define-public (make-move (game-id uint) (move-data uint))
    (let
        (
            (player-data (unwrap! (map-get? game-players { game-id: game-id, player: tx-sender }) (err err-not-player)))
            (game (unwrap! (map-get? games game-id) (err err-invalid-game)))
        )
        (asserts! (is-eq (get state game) "active") (err err-invalid-move))
        (map-set game-players
            { game-id: game-id, player: tx-sender }
            (merge player-data {
                last-move: move-data
            })
        )
        (ok true)
    )
)

;; Update player score
(define-public (update-score (game-id uint) (player principal) (new-score uint))
    (let
        (
            (game (unwrap! (map-get? games game-id) (err err-invalid-game)))
        )
        (asserts! (is-eq tx-sender (get creator game)) (err err-owner-only))
        (map-set game-players
            { game-id: game-id, player: player }
            (merge (unwrap! (map-get? game-players { game-id: game-id, player: player }) (err err-not-player))
                { score: new-score }
            )
        )
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-game (game-id uint))
    (ok (map-get? games game-id))
)

(define-read-only (get-player-data (game-id uint) (player principal))
    (ok (map-get? game-players { game-id: game-id, player: player }))
)

(define-read-only (get-current-game-id)
    (ok (var-get next-game-id))
)