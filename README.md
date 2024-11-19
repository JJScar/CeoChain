# CeoChain: Decentralized CEO Voting Platform
## Overview
CeoChain is a blockchain-based governance platform designed to facilitate transparent and secure voting for CEO selection and board management. The project leverages Solidity smart contracts and Foundry for development and testing.

## Features
- Decentralized CEO voting mechanism
- Transparent candidate selection process
- Secure blockchain-based governance
- Immutable voting records
- MakeFile for easy use

## Background
**The platform manages CEO transitions through a structured, secure voting mechanism:**
- Admin receives a list of potential CEO candidates
- *Security Constraint*: Maximum of 10 candidates allowed
  
**Voting Cycle**
- Represents the time/epoch for the voting duration
- Duration: One month
- Each whitelisted voter can cast only one vote per cycle

**Administrative Controls**
- Admin kicks off the voting cycle and is separate from the voting
- Admin can add or remove voters from the whitelist
- Enables dynamic management of voting participants

**Voting Finalisation**
- After one month, any user can trigger vote finalization
- System calculates and determines the winning candidate
- Ensures transparent, democratic CEO selection process

### Example Scenario
1. The current CEO had either decided to leave, or perhaps needed to leave their position. 
2. The company will select a person to be the admin, who is external to the vote. 
3. Even before the cycle begins, employees (potential voters) can apply to become voters.
4. The admin will start a voting cycle when the company decides to do so.
5. The voters now have 30 days to cast their votes.
6. Upon the end of the cycle anyone can call finalise vote.
7. The new CEO is selected.

### Actors
- Admin - Manages the system. The admin is separate to the voting system so there is no bias. The admin cannot apply to the whitelist and cannot vote. The admin is the only address that can initiate a new voting cycle and approve or remove voters.
- Board Members - These are the board members of the company. They can vote as same as anyone else. In case of a tie in the vote, to settle the tie, we will calculate the results only by the board for these candidates. 
- Voters - Employees at the company. These addresses are users who will apply to become voters, after the admin approves them. They can cast votes. 
- Users - Can apply to become voters. They can also finalise a cycle. 

## Prerequisites 
- Foundry
- Solidity 0.8.25
- forge-std
- OpenZeppelin Contracts

## Installation
Clone the repo to your local machine
```bash
git clone https://github.com/JJScar/CeoChain.git
```
Install dependencies
```bash
make install
```
Compile 
```bash
make build
```
See tests
```bash
make test
```
Deploy Anvil local Blockchain
```bash
make anvil
```

## Usage
Deploy the CeoChain Contract
```bash
make deploy
```
*ONLY ADMIN* Initialise Vote
```bash
make initiateVote
```
*ONLY ADMIN* Approve User To Whitelist
```bash
make approveToWhitelist
```
*ONLY ADMIN* Remove User from Whitelist
```bash
make removeFromWhitelist
```
Apply to get whitelisted
```bash
make applyToWhitelist
```
Cast Vote
```bash
make castVote
```
Finalise Vote Cycle
```bash
make finaliseVote
```
