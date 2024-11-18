// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {Errors} from "../libraries/CeoChainErrors.sol";

/// @title CeoChain
/// @notice Main contract that contains the logic for choosing a new CEO.
contract CeoChain {
    ////////////
    // Events //
    ////////////

    /// @notice Will be emitted when a new voting cycle is initiated.
    /// @param voteCycle The vote cycle that was initiated.
    event VoteCycleInitiated(uint256 indexed voteCycle);

    /// @notice Will be emitted when a user applies to the whitelist.
    /// @param voter The address that applied to the whitelist.
    event VoterWhitelistApplicationSubmitted(address indexed voter);

    /// @notice Will be emitted when a user is approved to the whitelist.
    /// @param voter The address that got whitelisted
    event VoterWhitelisted(address indexed voter);

    /// @notice Will be emitted when a user is removed from the whitelist.
    /// @param voter The address that got removed from the whitelist.
    event VoterRemovedFromWhitelist(address indexed voter);

    /// @notice Will be emitted when a user casts a vote.
    event VoteCasted();

    /// @notice Will be emitted when a vote cycle is finalized.
    /// @param voteCycle The number of vote cycle that was finalized
    /// @param winner The address of the winner
    /// @param votes Number of winner votes
    event VoteFinalised(uint256 indexed voteCycle, address indexed winner, uint256 votes);

    ///////////////
    // Variables //
    ///////////////

    /// @notice Represents the status of a user in the whitelist
    enum UserStatus {
        NOT_WHITELISTED,
        WAITING_FOR_APPROVAL,
        WHITELISTED,
        VOTED // Whitelisted and already voted

    }

    /// @notice Data for a candidate
    struct Candidate {
        address candidateAddress;
        uint256 numberOfVotes;
    }

    /// @notice Data structure for an active cycleActive
    struct ActiveCycleData {
        uint16 cycleId;
        uint64 startTime;
        address[] candidates;
    }

    /// @notice Data structure for a finished cycle
    struct FinishedCycleData {
        uint16 cycleId;
        uint64 startTime;
        uint64 endTime;
        Candidate[] candidates;
        address winner;
    }

    // State Variables //
    /// @notice The number of the vote cycle
    uint16 public s_currentCycleId;

    /// @notice A flag to help check whether a cycle is active. Used to decide if starting another cycle is needed, or to let voters vote
    bool public s_cycleActive;

    /// @notice When the cycle is finished, all the data should be moved to FinishedCycleData and deleted for the active
    ActiveCycleData s_activeCycleData;

    /// @notice Keeps track of the votes for the active cycle
    uint256[] public s_activeVotes;

    /// @notice Contains the data of the user and their status regarding the whitelist
    mapping(address => UserStatus) public s_whitelist;

    /// @notice List of all board members
    address[] public s_board;

    /// @notice List candidates and the number of votes they got from the board
    mapping(address candidate => uint256 boardVotes) public s_boardVotes;

    /// @notice List of all the winners
    mapping(uint16 cycleId => address winner) public s_winnerList;

    /// @notice All the data of past cycles
    mapping(uint16 cycleId => FinishedCycleData) public s_finishedCyclesData;

    // Constant Variables //
    /// @notice The length of the vote cycle
    uint256 public constant CYCLE_LENGTH = 30 days;

    // Immutable Variables //
    /// @notice The address of the admin. Someone that cannot vote, they only manage the contract.
    address public immutable i_admin;

    ///////////////
    // Modifiers //
    ///////////////

    /// @notice Checks msg.sender is the admin
    modifier onlyAdmin() {
        if (msg.sender != i_admin) revert Errors.CeoChain__OnlyAdmin();
        _;
    }

    /// @notice Checks the address is not address(0)
    modifier notZeroAddress(address user) {
        if (user == address(0)) revert Errors.CeoChain__CannotBeZeroAddress();
        _;
    }

    constructor(address _admin, address[] memory _board) {
        i_admin = _admin;
        s_cycleActive = false;
        s_board = _board;
        if (_board.length % 2 == 0) revert Errors.CeoChain__NumberOfBoardCannotBeAnEvenNumber();
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /// @notice Lets the admin initiate a new voting cycle
    /// @param _candidatesAddresses List of candidates. Has to be less than 10.
    function initiateVote(address[] memory _candidatesAddresses) external onlyAdmin {
        if (s_cycleActive) revert Errors.CeoChain__CycleAlreadyActive();
        uint256 length = _candidatesAddresses.length;
        if (length > 10) {
            revert Errors.CeoChain__CandidatesListTooLong(_candidatesAddresses.length);
        }

        // Checking the validity of the candidate list
        _checkCandidateList(_candidatesAddresses, length);

        for (uint256 i = 0; i < length; ++i) {
            s_activeVotes.push(0);
        }

        emit VoteCycleInitiated(s_currentCycleId);

        s_cycleActive = true;
        s_activeCycleData = ActiveCycleData({
            cycleId: s_currentCycleId,
            startTime: uint64(block.timestamp),
            candidates: _candidatesAddresses
        });
    }

    /// @notice Lets any user apply to be added to the whitelist.
    /// @param _applicant The address of the applicant
    function applyToWhitelist(address _applicant) external notZeroAddress(_applicant) {
        if (s_whitelist[_applicant] == UserStatus.WHITELISTED) revert Errors.CeoChain__AlreadyWhitelisted(_applicant);

        if (s_whitelist[_applicant] == UserStatus.WAITING_FOR_APPROVAL) {
            revert Errors.CeoChain__AlreadyWaitingForApproval(_applicant);
        }

        if (_applicant == i_admin) revert Errors.CeoChain__AdminCannotBeWhitelisted();

        emit VoterWhitelistApplicationSubmitted(_applicant);

        s_whitelist[_applicant] = UserStatus.WAITING_FOR_APPROVAL;
    }

    /// @notice Lets the admin approve a user to be added to the whitelist
    /// @param _voter The address of the voter
    function approveToWhitelist(address _voter) external onlyAdmin notZeroAddress(_voter) {
        if (s_whitelist[_voter] != UserStatus.WAITING_FOR_APPROVAL) {
            revert Errors.CeoChain__NotAppliedToBeApprovedToWhitelistOrAlreadyWhitelisted(_voter);
        }

        emit VoterWhitelisted(_voter);

        s_whitelist[_voter] = UserStatus.WHITELISTED;
    }

    /// @notice Lets the admin remove a user from the whitelist
    /// @param _voter The address to be removed
    function removeFromWhitelist(address _voter) external onlyAdmin notZeroAddress(_voter) {
        if (s_whitelist[_voter] != UserStatus.WHITELISTED) {
            revert Errors.UserCannotBeRemovedIfNotWhitelisted(_voter);
        }

        emit VoterRemovedFromWhitelist(_voter);

        s_whitelist[_voter] = UserStatus.NOT_WHITELISTED;
    }

    /// @notice Lets any whitelisted voter to cast their vote
    /// @param _candidateAddress The address of the candidate
    function castVote(address _candidateAddress) external {
        if (!s_cycleActive) revert Errors.CeoChain__CycleNotActive();
        _canUserVote(msg.sender); // checks user can vote
        _findCandidate(_candidateAddress); // checks ID is within the candidate array

        emit VoteCasted();

        s_whitelist[msg.sender] = UserStatus.VOTED;

        uint256 length = s_board.length;
        for (uint256 i = 0; i < length; ++i) {
            if (msg.sender == s_board[i]) {
                s_boardVotes[_candidateAddress]++;
            }
        }

        uint256 candidateLength = s_activeCycleData.candidates.length;
        for (uint256 i = 0; i < candidateLength; ++i) {
            if (s_activeCycleData.candidates[i] == _candidateAddress) {
                s_activeVotes[i]++;
            }
        }
    }

    /// @notice Finishes the voting cycle, and calculates the results. Callable by anyone.
    function finaliseVote() external returns (address winner, uint256 winnerVoteAmount) {
        if (block.timestamp < s_activeCycleData.startTime + CYCLE_LENGTH) {
            revert Errors.CeoChain__TooEarlyToFinaliseVote();
        }
        if (!s_cycleActive) revert Errors.CeoChain__NoCycleToFinalise();

        uint256 length = s_activeCycleData.candidates.length;
        uint256[] memory votes = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            votes[i] = s_activeVotes[i];
        }

        if (votes.length != s_activeCycleData.candidates.length) {
            revert Errors.CeoChain__WinnerCalculationWentWrong();
        }

        // Calculate results of vote. Designed this way in case the vote has a draw
        (address[] memory winner_s, uint256 mostVotes) = _calculateResult(votes);

        // Clearing data for the next vote
        for (uint256 i = 0; i < length; ++i) {
            s_activeVotes[i] = 0;
            s_activeCycleData.candidates[i] = address(0);
        }

        if (winner_s.length > 1) {
            (winner, winnerVoteAmount) = _boardSettleTies(winner_s);
        } else {
            winner = winner_s[0];
            winnerVoteAmount = mostVotes;
        }

        if (winner == address(0)) revert Errors.CeoChain__WinnerSelectionWentWrong();
        if (winnerVoteAmount == 0) revert Errors.CeoChain__WinnerSelectionWentWrong();

        emit VoteFinalised(s_currentCycleId, winner, winnerVoteAmount);

        s_currentCycleId++;
        s_cycleActive = false;
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /// @notice Checks that the candiate list does not contain zero addresses, duplicates or the admin
    /// @param _candidatesAddresses Candidate list
    /// @param _length Length of the candidate list
    function _checkCandidateList(address[] memory _candidatesAddresses, uint256 _length) internal view {
        for (uint256 i = 0; i < _length - 1; ++i) {
            if (_candidatesAddresses[i] == address(0)) revert Errors.CeoChain__CannotBeZeroAddress();
            if (_candidatesAddresses[i] == i_admin) revert Errors.CeoChain__AdminCannotBeElected();
            for (uint256 j = i + 1; j < _length; ++j) {
                if (_candidatesAddresses[i] == _candidatesAddresses[j]) {
                    revert Errors.CeoChain__CannotHaveDupliacteCandidates();
                }
            }
        }
        // Becasue of the way we check for duplicates, we do not want to miss the last address in the array
        if (_candidatesAddresses[_length - 1] == address(0)) revert Errors.CeoChain__CannotBeZeroAddress();
        if (_candidatesAddresses[_length - 1] == i_admin) revert Errors.CeoChain__AdminCannotBeElected();
    }

    /// @notice Checks if the candidate position has an actual candidate in it
    /// @param _candidateAddress The address of the candidate
    function _findCandidate(address _candidateAddress) internal view {
        for (uint256 i = 0; i < s_activeCycleData.candidates.length; ++i) {
            if (s_activeCycleData.candidates[i] == _candidateAddress) {
                return;
            }
        }
        revert Errors.CeoChain__CandidateIdNotWithinCandidateList();
    }

    /// @notice Checks whether the msg.sender is on the whitelist and has not voted
    /// @param _user The user to check status for
    function _canUserVote(address _user) internal view {
        if (s_whitelist[_user] == UserStatus.VOTED) revert Errors.CeoChain__VoterAlreadyVoted(_user);
        if (s_whitelist[_user] != UserStatus.WHITELISTED) revert Errors.CeoChain__UserNotWhitelisted(_user);
    }

    /// @notice Calcualtes results and chooses winner
    function _calculateResult(uint256[] memory votes) internal view returns (address[] memory, uint256) {
        address[] memory _candidates = s_activeCycleData.candidates;

        uint8 length = uint8(_candidates.length);
        uint256 mostVotes;
        uint8 winnerCount;
        address[] memory potentialWinners = new address[](length);

        for (uint8 i = 0; i < length; ++i) {
            if (mostVotes < votes[i]) {
                mostVotes = votes[i];
            }
        }

        for (uint8 i = 0; i < length; ++i) {
            if (votes[i] == mostVotes) {
                potentialWinners[winnerCount] = _candidates[i];
                winnerCount++;
            }
        }

        address[] memory winner_s = new address[](winnerCount);

        for (uint256 i = 0; i < winnerCount; ++i) {
            if (votes[i] == mostVotes) {
                winner_s[i] = potentialWinners[i];
            }
        }

        return (winner_s, mostVotes);
    }

    /// @notice In case of a tie within the whitelisted votes, we turn to the votes of the board members
    /// @param _winners The candidates that were tied
    function _boardSettleTies(address[] memory _winners) internal view returns (address winner, uint256 maxVotes) {
        uint256 length = _winners.length;
        for (uint256 i = 0; i < length; ++i) {
            if (s_boardVotes[_winners[i]] > maxVotes) {
                maxVotes = s_boardVotes[_winners[i]];
                winner = _winners[i];
            }
        }
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /// @notice Retrieves user status by a number identifier
    function getUserStatus(address _user) external view returns (uint256) {
        if (s_whitelist[_user] == UserStatus.NOT_WHITELISTED) {
            return 0;
        }
        if (s_whitelist[_user] == UserStatus.WAITING_FOR_APPROVAL) {
            return 1;
        }
        if (s_whitelist[_user] == UserStatus.WHITELISTED) {
            return 2;
        }
        return 3; // Means they are a whitelisted and have voted
    }

    function getActiveCycleId() external view returns (uint16) {
        return s_activeCycleData.cycleId;
    }

    function getActiveCycleStartTime() external view returns (uint64) {
        return s_activeCycleData.startTime;
    }

    function getActiveCycleCandidateList() external view returns (address[] memory) {
        return s_activeCycleData.candidates;
    }

    function getCandidateTotalVoteAtThisTime(address _candidateAddress) external view returns (uint256 numberOfVotes) {
        for (uint256 i = 0; i < s_activeVotes.length; ++i) {
            if (s_activeCycleData.candidates[i] == _candidateAddress) {
                numberOfVotes = s_activeVotes[i];
            }
        }
    }

    function getCandidateVotesFromBoard(address _candidateAddress) external view returns (uint256) {
        return s_boardVotes[_candidateAddress];
    }

    function getCycleLength() external pure returns (uint256) {
        return CYCLE_LENGTH;
    }

    function getBoardMembers() external view returns (address[] memory) {
        return s_board;
    }

    function getCurrentCycleId() external view returns (uint16) {
        return s_currentCycleId;
    }
}
