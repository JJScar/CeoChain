// SPDX-License-Identifier: GPL-3 only
pragma solidity 0.8.25;

import {Script, console} from "@forge-std/Script.sol";
import {CeoChain} from "../src/core/CeoChain.sol";

contract CeoChainDeployer is Script {
    CeoChain ceoChain;
    address[] boardMembers = new address[](3);

    function run(address _admin) public returns (CeoChain, address[] memory) {
        boardMembers[0] = 0x1234567890123456789012345678901234567890;
        boardMembers[1] = 0x0987654321098765432109876543210987654321;
        boardMembers[2] = 0xabCDeF0123456789AbcdEf0123456789aBCDEF01;
        vm.startBroadcast();
        ceoChain = new CeoChain(_admin, boardMembers);
        vm.stopBroadcast();

        return (ceoChain, boardMembers);
    }
}
