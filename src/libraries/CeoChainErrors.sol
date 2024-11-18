// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

/// @title Errors
/// @notice Library for ceo chain errors
library Errors {
    //===> General <===//

    /// @notice Thrown when the caller is not the admin
    error CeoChain__OnlyAdmin();

    /// @notice Thrown when address is the zero address
    error CeoChain__CannotBeZeroAddress();

    /// @notice Thrown if the admin passed an equal number of board members
    error CeoChain__NumberOfBoardCannotBeAnEvenNumber();

    // ----------------------------------------------------------------------------------------------- //

    //===> Whitelisting <===//

    /// @notice Thrown when the address is already whitelisted
    error CeoChain__AlreadyWhitelisted(address user);

    /// @notice Thrown when the address has already applied to the whitelist
    error CeoChain__AlreadyWaitingForApproval(address user);

    /// @notice Thrown when the admin tries to add themselves to the whitelist
    error CeoChain__AdminCannotBeWhitelisted();

    /// @notice Thrown when the address has not been given the WAITING_FOR_APPROVAL status
    error CeoChain__NotAppliedToBeApprovedToWhitelistOrAlreadyWhitelisted(address user);

    /// @notice Thrown when admin tries to remove a non existing user in whitelist
    error UserCannotBeRemovedIfNotWhitelisted(address user);

    // ----------------------------------------------------------------------------------------------- //

    //===> Initialising Cycle <===//

    /// @notice Thrown when admin passes a list of candidates that is too long
    error CeoChain__CandidatesListTooLong(uint256 length);

    /// @notice Thrown when admin tries to start another cycle when one is already active
    error CeoChain__CycleAlreadyActive();

    /// @notice Thrown when admin passes a candidate list with duplicates
    error CeoChain__CannotHaveDupliacteCandidates();

    /// @notice Thrown if the admin adds their address to the candidate list
    error CeoChain__AdminCannotBeElected();

    // ----------------------------------------------------------------------------------------------- //

    //===> Casting Votes <===//

    /// @notice Thrown when a user passes an ID that is bigger than the candidate array
    error CeoChain__CandidateIdNotWithinCandidateList();

    /// @notice Thrown when a user that is not whitelisted tries to vote
    error CeoChain__UserNotWhitelisted(address user);

    /// @notice Thrown when a voter that voted tries to vote again
    error CeoChain__VoterAlreadyVoted(address user);

    /// @notice Thrown when a voter tries to vote when there is no active cycle
    error CeoChain__CycleNotActive();

    // ----------------------------------------------------------------------------------------------- //

    //===> Finialising Vote <===/

    /// @notice Thrown when a user tries to finalise a vote too early
    error CeoChain__TooEarlyToFinaliseVote();

    /// @notice Thrown when a user tries to finalise when there is no active cycle
    error CeoChain__NoCycleToFinalise();

    /// @notice Thrown if the winner calculation goes wrong
    error CeoChain__WinnerCalculationWentWrong();

    /// @notice Thrown if the winner is address(0) or the votes amount is 0
    error CeoChain__WinnerSelectionWentWrong();
}
