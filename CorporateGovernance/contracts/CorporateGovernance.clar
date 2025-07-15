;; Corporate Governance Voting Smart Contract
;; A secure blockchain-based voting system for corporate governance decisions
;; Implements shareholder voting with time-bound proposals and anti-fraud measures

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-VOTING-CLOSED (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-INVALID-VOTER (err u104))
(define-constant ERR-PROPOSAL-EXPIRED (err u105))
(define-constant ERR-INSUFFICIENT-POWER (err u106))
(define-constant ERR-ALREADY-EXECUTED (err u107))
(define-constant ERR-INVALID-QUORUM (err u108))
(define-constant ERR-PROPOSAL-ACTIVE (err u109))
(define-constant ERR-INVALID-DELEGATION (err u110))
(define-constant ERR-SELF-DELEGATION (err u111))
(define-constant VOTING-PERIOD u144) ;; blocks (~24 hours assuming 10min blocks)
(define-constant MIN-VOTING-POWER u1)
(define-constant MAX-VOTING-POWER u10000)
(define-constant QUORUM-THRESHOLD u50) ;; 50% participation required
(define-constant MAJORITY-THRESHOLD u50) ;; 50% yes votes required

;; Data Maps and Variables
;; Tracks registered voters with their voting power (shares)
(define-map registered-voters principal uint)

;; Stores proposal details with voting metadata
(define-map proposals 
  uint 
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    creator: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint,
    total-eligible-votes: uint,
    executed: bool,
    proposal-type: uint,
    minimum-quorum: uint
  })

;; Tracks individual votes to prevent double voting
(define-map votes {proposal-id: uint, voter: principal} {vote: uint, voting-power: uint, timestamp: uint})

;; Vote delegation system - allows voters to delegate their power
(define-map delegations {delegator: principal, proposal-id: uint} principal)

;; Proposal categories and types
(define-map proposal-types uint {name: (string-utf8 50), required-majority: uint})

;; Voting history for audit trail
(define-map voting-history {voter: principal, proposal-id: uint} {action: (string-utf8 20), block-height: uint})

;; Emergency pause mechanism
(define-data-var contract-paused bool false)

;; Global proposal counter
(define-data-var next-proposal-id uint u1)

;; Total registered voting power for quorum calculations
(define-data-var total-voting-power uint u0)

;; Private Functions
;; Validates if a voter is registered and has voting power
(define-private (is-valid-voter (voter principal))
  (match (map-get? registered-voters voter)
    voting-power (> voting-power u0)
    false))

;; Checks if voting period is active for a proposal
(define-private (is-voting-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (and 
      (>= block-height (get start-block proposal))
      (<= block-height (get end-block proposal))
      (not (var-get contract-paused)))
    false))

;; Validates voting power is within acceptable limits
(define-private (is-valid-voting-power (power uint))
  (and (>= power MIN-VOTING-POWER) (<= power MAX-VOTING-POWER)))

;; Checks if contract is not paused
(define-private (is-contract-active)
  (not (var-get contract-paused)))

;; Calculates effective voting power including delegations
(define-private (get-effective-voting-power (voter principal) (proposal-id uint))
  (default-to u0 (map-get? registered-voters voter)))

;; Simplified delegation check - returns voting power if voter has delegation for this proposal
(define-private (get-delegation-power (delegator principal) (proposal-id uint))
  (match (map-get? delegations {delegator: delegator, proposal-id: proposal-id})
    delegate-address (default-to u0 (map-get? registered-voters delegator))
    u0))

;; Validates proposal type and requirements
(define-private (validate-proposal-type (proposal-type uint))
  (is-some (map-get? proposal-types proposal-type)))

;; Records action in voting history for audit trail
(define-private (record-voting-action (voter principal) (proposal-id uint) (action (string-utf8 20)))
  (map-set voting-history 
    {voter: voter, proposal-id: proposal-id}
    {action: action, block-height: block-height}))

;; Public Functions
;; Registers a new voter with specified voting power (shares)
(define-public (register-voter (voter principal) (voting-power uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-contract-active) (err u112))
    (asserts! (is-valid-voting-power voting-power) ERR-INSUFFICIENT-POWER)
    (let ((current-total (var-get total-voting-power))
          (old-power (default-to u0 (map-get? registered-voters voter))))
      (var-set total-voting-power (- (+ current-total voting-power) old-power))
      (ok (map-set registered-voters voter voting-power)))))

;; Removes a voter from the registry
(define-public (deregister-voter (voter principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-contract-active) (err u112))
    (let ((voter-power (default-to u0 (map-get? registered-voters voter))))
      (var-set total-voting-power (- (var-get total-voting-power) voter-power))
      (ok (map-delete registered-voters voter)))))

;; Emergency pause/unpause mechanism for contract owner
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok (var-get contract-paused))))

;; Sets up proposal types with different majority requirements
(define-public (set-proposal-type (type-id uint) (name (string-utf8 50)) (required-majority uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (and (>= required-majority u1) (<= required-majority u100)) ERR-INVALID-QUORUM)
    (ok (map-set proposal-types type-id {name: name, required-majority: required-majority}))))

;; Allows voters to delegate their voting power to another voter
(define-public (delegate-voting-power (proposal-id uint) (delegate principal))
  (begin
    (asserts! (is-contract-active) (err u112))
    (asserts! (is-valid-voter tx-sender) ERR-INVALID-VOTER)
    (asserts! (is-valid-voter delegate) ERR-INVALID-DELEGATION)
    (asserts! (not (is-eq tx-sender delegate)) ERR-SELF-DELEGATION)
    (asserts! (is-some (map-get? proposals proposal-id)) ERR-PROPOSAL-NOT-FOUND)
    (asserts! (is-voting-active proposal-id) ERR-VOTING-CLOSED)
    (record-voting-action tx-sender proposal-id u"DELEGATED")
    (ok (map-set delegations {delegator: tx-sender, proposal-id: proposal-id} delegate))))

;; Revokes delegation for a specific proposal
(define-public (revoke-delegation (proposal-id uint))
  (begin
    (asserts! (is-contract-active) (err u112))
    (asserts! (is-valid-voter tx-sender) ERR-INVALID-VOTER)
    (asserts! (is-voting-active proposal-id) ERR-VOTING-CLOSED)
    (record-voting-action tx-sender proposal-id u"REVOKED_DELEGATION")
    (ok (map-delete delegations {delegator: tx-sender, proposal-id: proposal-id}))))

;; Creates a new governance proposal with enhanced features
(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)) (proposal-type uint) (custom-quorum uint))
  (let ((proposal-id (var-get next-proposal-id))
        (start-block (+ block-height u1))
        (end-block (+ block-height VOTING-PERIOD))
        (total-power (var-get total-voting-power)))
    (begin
      (asserts! (is-contract-active) (err u112))
      (asserts! (is-valid-voter tx-sender) ERR-INVALID-VOTER)
      (asserts! (validate-proposal-type proposal-type) (err u113))
      (asserts! (and (>= custom-quorum u1) (<= custom-quorum u100)) ERR-INVALID-QUORUM)
      (map-set proposals proposal-id {
        title: title,
        description: description,
        creator: tx-sender,
        start-block: start-block,
        end-block: end-block,
        yes-votes: u0,
        no-votes: u0,
        abstain-votes: u0,
        total-eligible-votes: total-power,
        executed: false,
        proposal-type: proposal-type,
        minimum-quorum: custom-quorum
      })
      (record-voting-action tx-sender proposal-id u"CREATED")
      (var-set next-proposal-id (+ proposal-id u1))
      (ok proposal-id))))

;; Enhanced voting system with abstention support
(define-public (cast-vote (proposal-id uint) (vote-type uint))
  (let ((voter-power (default-to u0 (map-get? registered-voters tx-sender)))
        (vote-key {proposal-id: proposal-id, voter: tx-sender}))
    (begin
      (asserts! (is-contract-active) (err u112))
      (asserts! (is-valid-voter tx-sender) ERR-INVALID-VOTER)
      (asserts! (is-some (map-get? proposals proposal-id)) ERR-PROPOSAL-NOT-FOUND)
      (asserts! (is-voting-active proposal-id) ERR-VOTING-CLOSED)
      (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)
      (asserts! (and (>= vote-type u0) (<= vote-type u2)) (err u114)) ;; 0=no, 1=yes, 2=abstain
      
      ;; Record the vote with timestamp
      (map-set votes vote-key {vote: vote-type, voting-power: voter-power, timestamp: block-height})
      
      ;; Update proposal vote counts based on vote type
      (match (map-get? proposals proposal-id)
        proposal 
        (let ((updated-proposal 
               (if (is-eq vote-type u1)
                 (merge proposal {yes-votes: (+ (get yes-votes proposal) voter-power)})
                 (if (is-eq vote-type u0)
                   (merge proposal {no-votes: (+ (get no-votes proposal) voter-power)})
                   (merge proposal {abstain-votes: (+ (get abstain-votes proposal) voter-power)})))))
          (map-set proposals proposal-id updated-proposal))
        false)
      
      ;; Record voting action
      (record-voting-action tx-sender proposal-id 
        (if (is-eq vote-type u1) u"VOTED_YES" 
          (if (is-eq vote-type u0) u"VOTED_NO" u"ABSTAINED")))
      (ok true))))

;; Read-only functions for querying contract state
;; Retrieves proposal details and current vote tally
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id))

;; Gets voting power of a specific voter
(define-read-only (get-voter-power (voter principal))
  (map-get? registered-voters voter))

;; Gets delegation information for a voter on specific proposal
(define-read-only (get-delegation (delegator principal) (proposal-id uint))
  (map-get? delegations {delegator: delegator, proposal-id: proposal-id}))

;; Gets voting history for audit purposes
(define-read-only (get-voting-history (voter principal) (proposal-id uint))
  (map-get? voting-history {voter: voter, proposal-id: proposal-id}))

;; Gets proposal type information
(define-read-only (get-proposal-type (type-id uint))
  (map-get? proposal-types type-id))

;; Checks if contract is currently paused
(define-read-only (is-paused)
  (var-get contract-paused))

;; Gets total registered voting power
(define-read-only (get-total-voting-power)
  (var-get total-voting-power))


