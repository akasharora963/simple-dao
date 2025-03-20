// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Timelock} from "src/Timelock.sol";
import {VoteToken} from "src/VoteToken.sol";
import {VoteGovernor} from "src/VoteGovernor.sol";
import {Store} from "src/Store.sol";

contract DeployDao is Script {
    // Deploy the dao
    Store store;
    VoteToken voteToken;
    Timelock timelock;
    VoteGovernor governor;
    uint256 private constant MIN_DELAY = 3600;

    address[] private proposers;
    address[] private executors;

    function run() external returns (VoteToken, Timelock, VoteGovernor, Store) {
        // Deploy Vote token

        voteToken = new VoteToken();

        //Deply Timelock
        proposers.push(msg.sender);
        timelock = new Timelock(MIN_DELAY, proposers, executors);

        //Deploy Governor
        governor = new VoteGovernor(voteToken, timelock);

        //Deploy Store
        store = new Store(address(timelock));

        console.log("Dao deployed");
        console.log("Vote Token", address(voteToken));
        console.log("Timelock deployed", address(timelock));
        console.log("Governor", address(governor));
        console.log("Store", address(store));
        return (voteToken, timelock, governor, store);
    }
}
