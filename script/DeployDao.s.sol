// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {TimeLock} from "src/TimelockController.sol";
import {VoteToken} from "src/VoteToken.sol";
import {VoteGovernor} from "src/VoteGovernor.sol";

contract DeployDao is Script {
    // Deploy the dao

    VoteToken voteToken;
    TimeLock timelock;
    VoteGovernor governor;
    uint256 private constant MIN_DELAY = 3600;

    address[] private proposers;
    address[] private executors;

    function run() external {
        // Deploy Vote token
        voteToken = new VoteToken();

        //Deply Timelock
        timelock = new TimeLock(MIN_DELAY, proposers, executors);

        //Deploy Governor
        governor = new VoteGovernor(voteToken, timelock);
    }
}
