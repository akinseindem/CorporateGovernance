CorporateGovernance
===================

A secure, blockchain-based voting system for corporate governance decisions, implemented as a Clarity smart contract on the Stacks blockchain. This contract enables shareholder voting with time-bound proposals, anti-fraud measures, and robust governance compliance.

Overview
--------

The `CorporateGovernance` smart contract provides a decentralized platform for corporate voting, ensuring transparency, security, and auditability. It supports shareholder registration, proposal creation, vote casting (including abstention), vote delegation, and automated proposal finalization with governance compliance checks. Key features include quorum thresholds, majority requirements, and an emergency pause mechanism.

Features
--------

-   **Voter Registration**: Contract owner can register/deregister voters with specified voting power (shares).
-   **Proposal Management**: Create proposals with customizable titles, descriptions, types, and quorum requirements.
-   **Voting System**: Supports yes/no/abstain votes, prevents double voting, and tracks voting history.
-   **Vote Delegation**: Shareholders can delegate voting power to others for specific proposals.
-   **Governance Compliance**: Ensures quorum and majority thresholds are met for proposal execution.
-   **Security Measures**: Includes emergency pause, anti-fraud checks, and comprehensive audit trail.
-   **Flexibility**: Configurable proposal types with varying majority requirements (e.g., simple majority, super majority).

Prerequisites
-------------

-   **Stacks Blockchain**: Deployed on Stacks, requiring a compatible wallet (e.g., Hiro Wallet).
-   **Clarity**: Written in Clarity, the Stacks smart contract language.
-   **Environment**: Requires Stacks CLI or a similar tool for deployment and interaction.

Installation
------------

1.  **Clone the Repository**:

    ```
    git clone https://github.com/your-org/corporate-governance.git
    cd corporate-governance

    ```

2.  **Install Dependencies**:\
    Ensure you have the Stacks CLI installed:

    ```
    npm install -g @stacks/cli

    ```

3.  **Deploy the Contract**:\
    Deploy the contract using the Stacks CLI or a Stacks-compatible deployment tool:

    ```
    stx deploy corporate-governance.clar

    ```

Usage
-----

### Contract Owner Actions

-   **Register a Voter**:

    ```
    (contract-call? .corporate-governance register-voter 'SP123... u100)

    ```

    Assigns 100 voting power (shares) to a voter.

-   **Create a Proposal Type**:

    ```
    (contract-call? .corporate-governance set-proposal-type u1 u"BoardElection" u67)

    ```

    Defines a proposal type requiring a 67% majority.

-   **Toggle Contract Pause**:

    ```
    (contract-call? .corporate-governance toggle-contract-pause)

    ```

    Pauses/unpauses the contract in emergencies.

### Voter Actions

-   **Create a Proposal**:

    ```
    (contract-call? .corporate-governance create-proposal u"New CEO Election" u"Proposal to elect a new CEO" u1 u50)

    ```

    Creates a proposal with a 50% quorum requirement.

-   **Cast a Vote**:

    ```
    (contract-call? .corporate-governance cast-vote u1 u1)

    ```

    Casts a "yes" vote (vote-type: 1) for proposal ID 1.

-   **Delegate Voting Power**:

    ```
    (contract-call? .corporate-governance delegate-voting-power u1 'SP456...)

    ```

    Delegates voting power for proposal ID 1 to another voter.

-   **Finalize a Proposal**:

    ```
    (contract-call? .corporate-governance finalize-and-execute-proposal u1)

    ```

    Finalizes the proposal and returns governance results.

### Read-Only Queries

-   **Get Proposal Details**:

    ```
    (contract-call? .corporate-governance get-proposal u1)

    ```

-   **Check Voter Power**:

    ```
    (contract-call? .corporate-governance get-voter-power 'SP123...)

    ```

-   **View Voting History**:

    ```
    (contract-call? .corporate-governance get-voting-history 'SP123... u1)

    ```

Contract Functions
------------------

### Public Functions

-   **`register-voter (voter principal) (voting-power uint)`**\
    Registers a voter with specified voting power. Only callable by the contract owner. Updates total voting power.\
    **Parameters**: `voter` (principal), `voting-power` (uint).\
    **Returns**: `(ok bool)` or error (e.g., `ERR-UNAUTHORIZED`, `ERR-INSUFFICIENT-POWER`).

-   **`deregister-voter (voter principal)`**\
    Removes a voter from the registry, subtracting their voting power from the total. Only callable by the contract owner.\
    **Parameters**: `voter` (principal).\
    **Returns**: `(ok bool)` or error (e.g., `ERR-UNAUTHORIZED`).

-   **`toggle-contract-pause`**\
    Toggles the contract's paused state. Only callable by the contract owner.\
    **Returns**: `(ok bool)` indicating the new paused state or `ERR-UNAUTHORIZED`.

-   **`set-proposal-type (type-id uint) (name (string-utf8 50)) (required-majority uint)`**\
    Defines a proposal type with a specific majority requirement. Only callable by the contract owner.\
    **Parameters**: `type-id` (uint), `name` (string-utf8), `required-majority` (uint, 1--100).\
    **Returns**: `(ok bool)` or `ERR-UNAUTHORIZED`, `ERR-INVALID-QUORUM`.

-   **`delegate-voting-power (proposal-id uint) (delegate principal)`**\
    Delegates the caller's voting power to another voter for a specific proposal.\
    **Parameters**: `proposal-id` (uint), `delegate` (principal).\
    **Returns**: `(ok bool)` or error (e.g., `ERR-INVAIID-VOTER`, `ERR-SELF-DELEGATION`).

-   **`revoke-delegation (proposal-id uint)`**\
    Revokes delegation for a specific proposal.\
    **Parameters**: `ECHOproposal-id` (uint).\
    **Returns**: `(ok bool)` or error (e.g., `ERR-INVALID-VOTER`, `ERR-VOTING-CLOSED`).

-   **`create-proposal (title (string-utf8 100)) (description (string-utf8 500)) (proposal-type uint) (custom-quorum uint)`**\
    Creates a new proposal with specified attributes. Only callable by registered voters.\
    **Parameters**: `title` (string-utf8), `description` (string-utf8), `proposal-type` (uint), `custom-quorum` (uint, 1--100).\
    **Returns**: `(ok uint)` (proposal ID) or error (e.g., `ERR-INVALID-VOTER`, `ERR-INVALID-QUORUM`).

-   **`cast-vote (proposal-id uint) (vote-type uint)`**\
    Casts a vote (0 = no, 1 = yes, 2 = abstain) for a proposal. Prevents double voting.\
    **Parameters**: `proposal-id` (uint), `vote-type` (uint, 0--2).\
    **Returns**: `(ok bool)` or error (e.g., `ERR-ALREADY-VOTED`, `ERR-VOTING-CLOSED`).

-   **`finalize-and-execute-proposal (proposal-id uint)`**\
    Finalizes a proposal, calculates results, and checks governance compliance (quorum, majority). Only callable by the proposal creator or contract owner.\
    **Parameters**: `proposal-id` (uint).\
    **Returns**: `(ok {tuple})` with detailed results (passed, yes-votes, quorum-met, etc.) or error (e.g., `ERR-PROPOSAL-NOT-FOUND`, `ERR-ALREADY-EXECUTED`).

### Private Functions

-   **`is-valid-voter (voter principal)`**\
    Checks if a voter is registered and has non-zero voting power.\
    **Parameters**: `voter` (principal).\
    **Returns**: `bool`.

-   **`is-voting-active (proposal-id uint)`**\
    Verifies if a proposal's voting period is active and the contract is not paused.\
    **Parameters**: `proposal-id` (uint).\
    **Returns**: `bool`.

-   **`is-valid-voting-power (power uint)`**\
    Ensures voting power is within the allowed range (1--10,000).\
    **Parameters**: `power` (uint).\
    **Returns**: `bool`.

-   **`is-contract-active`**\
    Checks if the contract is not paused.\
    **Returns**: `bool`.

-   **`get-effective-voting-power (voter principal) (proposal-id uint)`**\
    Retrieves a voter's effective voting power (excluding delegation logic in this version).\
    **Parameters**: `voter` (principal), `proposal-id` (uint).\
    **Returns**: `uint`.

-   **`get-delegation-power (delegator principal) (proposal-id uint)`**\
    Returns the voting power of a delegator for a specific proposal, if delegated.\
    **Parameters**: `delegator` (principal), `proposal-id` (uint).\
    **Returns**: `uint`.

-   **`validate-proposal-type (proposal-type uint)`**\
    Verifies if a proposal type exists in the `proposal-types` map.\
    **Parameters**: `proposal-type` (uint).\
    **Returns**: `bool`.

-   **`record-voting-action (voter principal) (proposal-id uint) (action (string-utf8 20))`**\
    Records a voter's action (e.g., voting, delegation) in the audit trail with the block height.\
    **Parameters**: `voter` (principal), `proposal-id` (uint), `action` (string-utf8).\
    **Returns**: None (updates `voting-history` map).

### Read-Only Functions

-   **`get-proposal (proposal-id uint)`**\
    Retrieves details of a proposal (title, votes, status, etc.).\
    **Returns**: `(optional {tuple})` or none if not found.

-   **`get-voter-power (voter principal)`**\
    Returns the voting power of a specified voter.\
    **Returns**: `(optional uint)` or none if not registered.

-   **`get-delegation (delegator principal) (proposal-id uint)`**\
    Retrieves delegation details for a voter and proposal.\
    **Returns**: `(optional principal)` or none if no delegation exists.

-   **`get-voting-history (voter principal) (proposal-id uint)`**\
    Retrieves a voter's action history (e.g., voted, delegated) for a proposal.\
    **Returns**: `(optional {tuple})` with action and block height or none.

-   **`get-proposal-type (type-id uint)`**\
    Returns details of a proposal type (name, required majority).\
    **Returns**: `(optional {tuple})` or none if not defined.

-   **`is-paused`**\
    Checks if the contract is paused.\
    **Returns**: `bool`.

-   **`get-total-voting-power`**\
    Returns the total registered voting power across all voters.\
    **Returns**: `uint`.

Contract Details
----------------

### Key Constants

-   `VOTING-PERIOD`: ~24 hours (144 blocks, assuming 10-minute blocks).
-   `QUORUM-THRESHOLD`: 50% participation required by default.
-   `MAJORITY-THRESHOLD`: 50% yes votes required by default.
-   `MIN-VOTING-POWER` / `MAX-VOTING-POWER`: Limits voting power to 1--10,000 units.

### Data Structures

-   `registered-voters`: Maps voter principals to their voting power.
-   `proposals`: Stores proposal details (title, description, votes, etc.).
-   `votes`: Tracks individual votes to prevent double voting.
-   `delegations`: Manages vote delegation per proposal.
-   `voting-history`: Maintains an audit trail of all actions.
-   `proposal-types`: Defines proposal categories with specific majority requirements.

### Security Features

-   **Access Control**: Only the contract owner can register voters, set proposal types, or toggle pause.
-   **Anti-Fraud**: Prevents double voting, self-delegation, and invalid voter actions.
-   **Audit Trail**: Records all actions (voting, delegation, finalization) with timestamps.
-   **Emergency Pause**: Allows contract owner to pause operations in critical situations.

Error Codes
-----------

-   `ERR-UNAUTHORIZED (u100)`: Unauthorized access (e.g., non-owner action).
-   `ERR-PROPOSAL-NOT-FOUND (u101)`: Proposal ID does not exist.
-   `ERR-VOTING-CLOSED (u102)`: Voting period has ended or is not active.
-   `ERR-ALREADY-VOTED (u103)`: Voter has already cast a vote.
-   `ERR-INVALID-VOTER (u104)`: Voter is not registered or lacks voting power.
-   `ERR-PROPOSAL-EXPIRED (u105)`: Proposal voting period has expired.
-   `ERR-INSUFFICIENT-POWER (u106)`: Invalid voting power specified.
-   `ERR-ALREADY-EXECUTED (u107)`: Proposal has already been finalized.
-   `ERR-INVALID-QUORUM (u108)`: Invalid quorum percentage specified.
-   `ERR-PROPOSAL-ACTIVE (u109)`: Proposal is still active and cannot be modified.
-   `ERR-INVALID-DELEGATION (u110)`: Invalid delegate address.
-   `ERR-SELF-DELEGATION (u111)`: Voter attempted to delegate to themselves.
-   `u112`: Contract is paused.
-   `u113`: Invalid proposal type.
-   `u114`: Invalid vote type.

License
-------

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2025 Akinseinde Ebenezer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

Contributing
------------

Contributions are welcome! Please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature`).
3.  Make your changes and commit (`git commit -m "Add your feature"`).
4.  Push to the branch (`git push origin feature/your-feature`).
5.  Open a pull request with a detailed description of your changes.

Please ensure your code adheres to the Clarity style guide and includes appropriate tests.

Testing
-------

To test the contract:

1.  Use the Stacks Clarinet tool for local testing:

    ```
    clarinet test

    ```

2.  Write test cases for voter registration, proposal creation, voting, delegation, and finalization.
3.  Simulate edge cases like double voting, invalid voters, or expired proposals.

Security Considerations
-----------------------

-   **Contract Pause**: Use the pause mechanism only in emergencies to avoid disrupting active proposals.
-   **Voter Registration**: Ensure only trusted principals are registered by the contract owner.
-   **Delegation**: Verify delegate addresses to prevent invalid delegations.
-   **Audit Trail**: Regularly review `voting-history` for transparency and compliance.

Relevant Resources
----------------

-   **[Clarity Language](https://docs.stacks.co/docs/clarity)**: Official documentation for Clarity smart contracts.
-   **[Hiro Wallet](https://www.hiro.so/wallet)**: A wallet for interacting with Stacks contracts.

Contact
-------

For questions or support, contact the maintainer at <ebendttl@gmail.com> or open an issue on GitHub.
