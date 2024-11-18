// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {Test, console} from "@forge-std/Test.sol";
import {CeoChain} from "../../src/core/CeoChain.sol";
import {Errors} from "../../src/libraries/CeoChainErrors.sol";
import {CeoChainDeployer} from "../../script/CeoChainDeployer.s.sol";

enum UserStatus {
    NOT_WHITELISTED,
    WAITING_FOR_APPROVAL,
    WHITELISTED
}

struct Candidate {
    address candidateAddress;
    uint256 numberOfVotes;
}

contract CeoChainTest is Test {
    // => Events <= //
    event VoterWhitelistApplicationSubmitted(address indexed voter);
    event VoterWhitelisted(address indexed voter);
    event VoterRemovedFromWhitelist(address indexed voter);
    event VoteCycleInitiated(uint256 indexed voteCycle);
    event VoteCasted();
    event VoteFinalised(uint256 indexed voteCycle, address indexed winner, uint256 votes);

    // => General <= //
    CeoChainDeployer public deployer;
    address public admin;
    address[] public theBoard;
    CeoChain public ceoChain;

    // => Variables <= //
    uint256 public constant CYCLE_LENGTH = 30 days;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() external {
        admin = makeAddr("admin");
        console.log(admin);
        deployer = new CeoChainDeployer();
        (ceoChain, theBoard) = deployer.run(admin);
    }

    //===> initiateVote + _checkCandidateList Tests <===//

    function testOnlyAdminCanInitialiseCycle() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        vm.prank(user);
        vm.expectRevert(Errors.CeoChain__OnlyAdmin.selector);
        ceoChain.initiateVote(candidates);
    }

    function testOnlyInitialiseWhenACycleIsntActive() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        vm.startPrank(admin);
        ceoChain.initiateVote(candidates);
        vm.expectRevert(Errors.CeoChain__CycleAlreadyActive.selector);
        ceoChain.initiateVote(candidates);
        vm.stopPrank();
    }

    function testRevertsIfCandidateListTooLong() public {
        address[] memory candidates = new address[](11);
        candidates[0] = user;
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.CeoChain__CandidatesListTooLong.selector, 11));
        ceoChain.initiateVote(candidates);
    }

    function testRevertsIfThereIsAddressZeroInCandidateList() public {
        address[] memory candidates = new address[](2);
        candidates[0] = address(0);
        candidates[1] = user;
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotBeZeroAddress.selector);
        ceoChain.initiateVote(candidates);
    }

    function testRevertsIfAdminAddressIsInCandidateList() public {
        address[] memory candidates = new address[](2);
        candidates[0] = admin;
        candidates[1] = user;
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__AdminCannotBeElected.selector);
        ceoChain.initiateVote(candidates);
    }

    function testRevertsIfDuplicateAddressesInCandidateList() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user;
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotHaveDupliacteCandidates.selector);
        ceoChain.initiateVote(candidates);
    }

    function testRevertsIfLastAddressInCandidateListIsValid() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = address(0);
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotBeZeroAddress.selector);
        ceoChain.initiateVote(candidates);

        candidates[1] = admin;
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__AdminCannotBeElected.selector);
        ceoChain.initiateVote(candidates);
    }

    function testVoteCycleInitiatedisEmitted() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        vm.prank(admin);
        vm.expectEmit(true, false, false, false);
        emit VoteCycleInitiated(0);
        ceoChain.initiateVote(candidates);
    }

    function testActiveCycleIdStoresCorrectly() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        vm.prank(admin);
        ceoChain.initiateVote(candidates);
        assertEq(ceoChain.getActiveCycleId(), 0);
    }

    function testActiveCycleStartTimeStoredCorrectly() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        uint64 actualTime = uint64(block.timestamp);
        vm.prank(admin);
        ceoChain.initiateVote(candidates);
        assertEq(ceoChain.getActiveCycleStartTime(), actualTime);
    }

    function testActiveCycleCandidateListStoredCorrectly() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        vm.prank(admin);
        ceoChain.initiateVote(candidates);
        assertEq(ceoChain.getActiveCycleCandidateList(), candidates);
    }

    //===> applyToWhitelist Tests <===//

    function testZeroAddressCannotApplyToWhitelist() public {
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotBeZeroAddress.selector);
        ceoChain.applyToWhitelist(address(0));
    }

    function testAddressAlreadyWhitelisted() public {
        vm.startPrank(admin);
        ceoChain.applyToWhitelist(user);
        ceoChain.approveToWhitelist(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CeoChain__AlreadyWhitelisted.selector, user));
        ceoChain.applyToWhitelist(user);
        vm.stopPrank();
    }

    function testAddressHasAlreadyAppliedToBeApprovedToWhitelist() public {
        vm.startPrank(admin);
        ceoChain.applyToWhitelist(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CeoChain__AlreadyWaitingForApproval.selector, user));
        ceoChain.applyToWhitelist(user);
        vm.stopPrank();
    }

    function testAdminTriesToApplyToWhitelist() public {
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__AdminCannotBeWhitelisted.selector);
        ceoChain.applyToWhitelist(admin);
    }

    function testApplicantIsWaitingEventHasBeenEmitted() public {
        vm.startPrank(user);
        vm.expectEmit(true, false, false, false);
        emit VoterWhitelistApplicationSubmitted(user);
        ceoChain.applyToWhitelist(user);
    }

    function testStatusHasChangedAfterApplyingToWhitelist() public {
        vm.prank(user);
        ceoChain.applyToWhitelist(user);
        assertEq(ceoChain.getUserStatus(user), 1);
    }

    //===> approveToWhitelist Tests <===//

    function testOnlyAdminCanCallApproveToWhitelist() public {
        vm.startPrank(user);
        ceoChain.applyToWhitelist(user);
        vm.expectRevert(Errors.CeoChain__OnlyAdmin.selector);
        ceoChain.approveToWhitelist(user);
        vm.stopPrank();
    }

    function testZeroAddressCannotBeApprovedToWhitelist() public {
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotBeZeroAddress.selector);
        ceoChain.approveToWhitelist(address(0));
    }

    function testOnlyWaitingForApprovalUsersCanBeAddedToWhitelist() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.CeoChain__NotAppliedToBeApprovedToWhitelistOrAlreadyWhitelisted.selector, user
            )
        );
        ceoChain.approveToWhitelist(user);
    }

    function testVoterWhitelistedEventIsEmitted() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        vm.expectEmit(true, false, false, false);
        emit VoterWhitelisted(user);
        ceoChain.approveToWhitelist(user);
    }

    function removeFromWhitelist() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        ceoChain.approveToWhitelist(user);
        assertEq(ceoChain.getUserStatus(user), 2);
    }

    //===> removeFromWhitelist Tests <===//

    function testOnlyAdminCanRemoveVoterFromWhitelist() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        ceoChain.approveToWhitelist(user);
        vm.prank(user);
        vm.expectRevert(Errors.CeoChain__OnlyAdmin.selector);
        ceoChain.removeFromWhitelist(user);
    }

    function testZeroAddressCannotBeRemovedFromWhitelist() public {
        vm.prank(admin);
        vm.expectRevert(Errors.CeoChain__CannotBeZeroAddress.selector);
        ceoChain.removeFromWhitelist(address(0));
    }

    function testUserToBeRemovedHasToHaveWhitelistedStatus() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.UserCannotBeRemovedIfNotWhitelisted.selector, user));
        ceoChain.removeFromWhitelist(user);
    }

    function testVoterRemovedFromWhitelistIsEmitted() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        ceoChain.approveToWhitelist(user);
        vm.prank(admin);
        vm.expectEmit(true, false, false, false);
        emit VoterRemovedFromWhitelist(user);
        ceoChain.removeFromWhitelist(user);
    }

    function testStatusIsNotWhitelistedAnymore() public {
        ceoChain.applyToWhitelist(user);
        vm.startPrank(admin);
        ceoChain.approveToWhitelist(user);
        ceoChain.removeFromWhitelist(user);
        vm.stopPrank();
        assertEq(ceoChain.getUserStatus(user), 0);
    }

    //===> castVote + _findCandidate + _canUserVote Tests <===//

    modifier whitelistingAndInitialisingCycle() {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        ceoChain.applyToWhitelist(user);
        vm.startPrank(admin);
        ceoChain.approveToWhitelist(user);
        ceoChain.initiateVote(candidates);
        vm.stopPrank();
        _;
    }

    function testRevertsIfVoterThatVotedVotesAgain() public whitelistingAndInitialisingCycle {
        vm.startPrank(user);
        ceoChain.castVote(user);
        vm.expectRevert(abi.encodeWithSelector(Errors.CeoChain__VoterAlreadyVoted.selector, user));
        ceoChain.castVote(user);
        vm.stopPrank();
    }

    function testRevertsWhenNonWhitelistedUserTriesToVote() public whitelistingAndInitialisingCycle {
        address unknown = makeAddr("unkown");
        vm.prank(unknown);
        vm.expectRevert(abi.encodeWithSelector(Errors.CeoChain__UserNotWhitelisted.selector, unknown));
        ceoChain.castVote(user);
    }

    function testRevertsIfCandidateNotFound() public whitelistingAndInitialisingCycle {
        address unknown = makeAddr("unkown");
        vm.prank(user);
        vm.expectRevert(Errors.CeoChain__CandidateIdNotWithinCandidateList.selector);
        ceoChain.castVote(unknown);
    }

    function testVoterTriesToVoteWhenCycleIsNotActive() public {
        ceoChain.applyToWhitelist(user);
        vm.prank(admin);
        ceoChain.approveToWhitelist(user);
        vm.prank(user);
        vm.expectRevert(Errors.CeoChain__CycleNotActive.selector);
        ceoChain.castVote(user);
    }

    function testVoteCastedIsEmitted() public whitelistingAndInitialisingCycle {
        vm.prank(user);
        vm.expectEmit(false, false, false, false);
        emit VoteCasted();
        ceoChain.castVote(user);
    }

    function testVoterStatusChangedCorrectly() public whitelistingAndInitialisingCycle {
        vm.prank(user);
        ceoChain.castVote(user);
        assertEq(ceoChain.getUserStatus(user), 3);
    }

    function testVoteAddedSuccessfully() public whitelistingAndInitialisingCycle {
        vm.prank(user);
        ceoChain.castVote(user);
        assertEq(ceoChain.getCandidateTotalVoteAtThisTime(user), 1);
    }

    function testBoardVoteAddedSuccessfully() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        ceoChain.applyToWhitelist(theBoard[0]);
        vm.startPrank(admin);
        ceoChain.approveToWhitelist(theBoard[0]);
        ceoChain.initiateVote(candidates);
        vm.stopPrank();

        vm.prank(theBoard[0]);
        ceoChain.castVote(user);
        assertEq(ceoChain.getCandidateVotesFromBoard(user), 1);
    }

    //===> finaliseVote + _calculateResult + _boardSettleTies Tests <===//

    modifier settingUpVotingBeforeFinalising() {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        ceoChain.applyToWhitelist(user);
        vm.startPrank(admin);
        ceoChain.approveToWhitelist(user);
        ceoChain.initiateVote(candidates);
        vm.stopPrank();
        vm.prank(user);
        ceoChain.castVote(user);
        vm.warp(CYCLE_LENGTH + 1);
        _;
    }

    function testCannotFinaliseVoteBeforeTimeIsUp() public whitelistingAndInitialisingCycle {
        vm.expectRevert(Errors.CeoChain__TooEarlyToFinaliseVote.selector);
        ceoChain.finaliseVote();
    }

    function testCannotFinaliseVoteIfThereIsNoActiveVote() public {
        vm.warp(CYCLE_LENGTH);
        vm.expectRevert(Errors.CeoChain__NoCycleToFinalise.selector);
        ceoChain.finaliseVote();
    }

    function testCalculatingResultsSuccessfullyNoTie() public settingUpVotingBeforeFinalising {
        (address winner, uint256 votes) = ceoChain.finaliseVote();
        assert(winner == user);
        assert(votes == 1);
    }

    function testCalculatingResultsSuccessfullyWithTie() public {
        address[] memory candidates = new address[](2);
        candidates[0] = user;
        candidates[1] = user2;
        ceoChain.applyToWhitelist(user);
        ceoChain.applyToWhitelist(user2);
        ceoChain.applyToWhitelist(user3);
        ceoChain.applyToWhitelist(theBoard[0]);
        vm.startPrank(admin);
        ceoChain.approveToWhitelist(user);
        ceoChain.approveToWhitelist(user2);
        ceoChain.approveToWhitelist(user3);
        ceoChain.approveToWhitelist(theBoard[0]);
        ceoChain.initiateVote(candidates);
        vm.stopPrank();
        vm.prank(user);
        ceoChain.castVote(user);
        vm.prank(user2);
        ceoChain.castVote(user2);
        vm.prank(user3);
        ceoChain.castVote(user2);
        vm.prank(theBoard[0]);
        ceoChain.castVote(user);
        vm.warp(CYCLE_LENGTH + 1);
        (address winner, uint256 votes) = ceoChain.finaliseVote();
        assert(winner == user);
        assert(votes == 1);
    }

    function testVoteFinalisedEmitSuccessfully() public settingUpVotingBeforeFinalising {
        vm.expectEmit(true, true, true, false);
        emit VoteFinalised(0, user, 1);
        ceoChain.finaliseVote();
    }
}
