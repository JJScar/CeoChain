// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {Test, console} from "@forge-std/Test.sol";
import {CeoChain} from "../../src/core/CeoChain.sol";
import {Errors} from "../../src/libraries/CeoChainErrors.sol";
import {CeoChainDeployer} from "../../script/CeoChainDeployer.s.sol";
import {
    InitateVoteScript,
    ApplyToWhiteListScript,
    ApproveToWhiteListScript,
    RemoveFromWhiteListScript,
    CastVoteScript,
    FinaliseVoteScript
} from "../script/Interactions.s.sol";

contract CeoChainTest is Test {
    // => Events <= //
    event VoterWhitelistApplicationSubmitted(address indexed voter);
    event VoterWhitelisted(address indexed voter);
    event VoterRemovedFromWhitelist(address indexed voter);
    event VoteCycleInitiated(uint256 indexed voteCycle);
    event VoteCasted();
    event VoteFinalised(uint256 indexed voteCycle, address indexed winner, uint256 votes);

    // => Scripts <= //
    CeoChainDeployer public deployer;
    InitateVoteScript public initateVoteScript;
    ApplyToWhiteListScript public applyToWhiteListScript;
    ApproveToWhiteListScript public approveToWhiteListScript;
    RemoveFromWhiteListScript public removeFromWhiteListScript;
    CastVoteScript public castVoteScript;
    FinaliseVoteScript public finaliseVoteScript;

    // => General <= //
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

        initateVoteScript = new InitateVoteScript();
        applyToWhiteListScript = new ApplyToWhiteListScript();
        approveToWhiteListScript = new ApproveToWhiteListScript();
        removeFromWhiteListScript = new RemoveFromWhiteListScript();
        castVoteScript = new CastVoteScript();
        finaliseVoteScript = new FinaliseVoteScript();
    }

    // ==> Initate Vote <== //
    function testInitateVoteScript() public {
        address[] memory candidates = new address[](3);
        candidates[0] = user;
        candidates[1] = user2;
        candidates[2] = user3;
        vm.expectEmit(true, false, false, false);
        emit VoteCycleInitiated(0);
        uint64 time = uint64(block.timestamp);
        initateVoteScript.initateVoteScriptFunction(address(ceoChain), candidates, admin);

        assert(ceoChain.getActiveCycleId() == 0);
        assert(ceoChain.getActiveCycleStartTime() == time);
        assert(ceoChain.getActiveCycleCandidateList()[0] == candidates[0]);
        assert(ceoChain.getActiveCycleCandidateList()[1] == candidates[1]);
        assert(ceoChain.getActiveCycleCandidateList()[2] == candidates[2]);
    }

    // ==> Apply To Whitelist <== //
    function testApplyToWhitelistScript() public {
        vm.expectEmit(true, false, false, false);
        emit VoterWhitelistApplicationSubmitted(user);
        applyToWhiteListScript.applyToWhitelistScriptFunction(address(ceoChain), user, user);

        assert(ceoChain.getUserStatus(user) == 1);
    }

    // ==> Approve To Whitelist <== //
    function testApproveToWhitelistScript() public {
        applyToWhiteListScript.applyToWhitelistScriptFunction(address(ceoChain), user, user);

        vm.expectEmit(true, false, false, false);
        emit VoterWhitelisted(user);
        approveToWhiteListScript.approveToWhiteListScriptFunction(address(ceoChain), user, admin);

        assert(ceoChain.getUserStatus(user) == 2);
    }

    // ==> Remove From Whitelist <== //
    function testRemoveFromWhitelistScript() public {
        applyToWhiteListScript.applyToWhitelistScriptFunction(address(ceoChain), user, user);
        approveToWhiteListScript.approveToWhiteListScriptFunction(address(ceoChain), user, admin);

        vm.expectEmit(true, false, false, false);
        emit VoterRemovedFromWhitelist(user);
        removeFromWhiteListScript.removeFromWhitelistScriptFunction(address(ceoChain), user, admin);

        assert(ceoChain.getUserStatus(user) == 0);
    }

    // ==> Cast Vote <== //
    function testCastVoteScript() public {
        applyToWhiteListScript.applyToWhitelistScriptFunction(address(ceoChain), user, user);
        approveToWhiteListScript.approveToWhiteListScriptFunction(address(ceoChain), user, admin);

        address[] memory candidates = new address[](3);
        candidates[0] = user;
        candidates[1] = user2;
        candidates[2] = user3;
        initateVoteScript.initateVoteScriptFunction(address(ceoChain), candidates, admin);

        vm.expectEmit(false, false, false, false);
        emit VoteCasted();
        castVoteScript.castVoteScriptFunction(address(ceoChain), user, user);

        assert(ceoChain.getUserStatus(user) == 3);
        assert(ceoChain.getCandidateTotalVoteAtThisTime(user) == 1);
    }

    function testFinaliseVoteScript() public {
        applyToWhiteListScript.applyToWhitelistScriptFunction(address(ceoChain), user, user);
        approveToWhiteListScript.approveToWhiteListScriptFunction(address(ceoChain), user, admin);

        address[] memory candidates = new address[](3);
        candidates[0] = user;
        candidates[1] = user2;
        candidates[2] = user3;
        initateVoteScript.initateVoteScriptFunction(address(ceoChain), candidates, admin);
        castVoteScript.castVoteScriptFunction(address(ceoChain), user, user);

        vm.warp(CYCLE_LENGTH + 1);
        vm.expectEmit(true, true, true, false);
        emit VoteFinalised(0, user, 1);
        finaliseVoteScript.finaliseVoteScriptFunction(address(ceoChain));

        assert(ceoChain.getCurrentCycleId() == 1);
    }
}
