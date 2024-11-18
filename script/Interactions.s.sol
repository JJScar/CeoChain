// SPDX-License-Identifier: GPL-3 only
pragma solidity 0.8.25;

import {Script} from "@forge-std/Script.sol";
import {CeoChain} from "../src/core/CeoChain.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract InitateVoteScript is Script {
    function initateVoteScriptFunction(address mostRecentlyDeployed, address[] memory _candidates, address admin)
        public
    {
        vm.startBroadcast(admin);
        CeoChain(mostRecentlyDeployed).initiateVote(_candidates);
        vm.stopBroadcast();
    }

    function run(address[] memory _candidates, address admin) public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        initateVoteScriptFunction(mostRecentlyDeployed, _candidates, admin);
    }
}

contract ApplyToWhiteListScript is Script {
    function applyToWhitelistScriptFunction(address mostRecentlyDeployed, address _applicant, address admin) public {
        vm.startBroadcast(admin);
        CeoChain(mostRecentlyDeployed).applyToWhitelist(_applicant);
        vm.stopBroadcast();
    }

    function run(address _applicant, address admin) public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        applyToWhitelistScriptFunction(mostRecentlyDeployed, _applicant, admin);
    }
}

contract ApproveToWhiteListScript is Script {
    function approveToWhiteListScriptFunction(address mostRecentlyDeployed, address _voter, address user) public {
        vm.startBroadcast(user);
        CeoChain(mostRecentlyDeployed).approveToWhitelist(_voter);
        vm.stopBroadcast();
    }

    function run(address _voter, address user) public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        approveToWhiteListScriptFunction(mostRecentlyDeployed, _voter, user);
    }
}

contract RemoveFromWhiteListScript is Script {
    function removeFromWhitelistScriptFunction(address mostRecentlyDeployed, address _voter, address user) public {
        vm.startBroadcast(user);
        CeoChain(mostRecentlyDeployed).removeFromWhitelist(_voter);
        vm.stopBroadcast();
    }

    function run(address _voter, address user) public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        removeFromWhitelistScriptFunction(mostRecentlyDeployed, _voter, user);
    }
}

contract CastVoteScript is Script {
    function castVoteScriptFunction(address mostRecentlyDeployed, address candidateAddress, address user) public {
        vm.startBroadcast(user);
        CeoChain(mostRecentlyDeployed).castVote(candidateAddress);
        vm.stopBroadcast();
    }

    function run(address candidateAddress, address user) public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        castVoteScriptFunction(mostRecentlyDeployed, candidateAddress, user);
    }
}

contract FinaliseVoteScript is Script {
    function finaliseVoteScriptFunction(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        CeoChain(mostRecentlyDeployed).finaliseVote();
        vm.stopBroadcast();
    }

    function run() public {
        // address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("CeoChain", block.chainid);
        address mostRecentlyDeployed = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        finaliseVoteScriptFunction(mostRecentlyDeployed);
    }
}
