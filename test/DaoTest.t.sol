// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployDao} from "script/DeployDao.s.sol";
import {Timelock} from "src/Timelock.sol";
import {VoteToken} from "src/VoteToken.sol";
import {VoteGovernor} from "src/VoteGovernor.sol";
import {Store} from "src/Store.sol";

contract DaoTest is Test {
    DeployDao deployDao;
    VoteToken token;
    Timelock timelock;
    VoteGovernor governor;
    Store store;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        deployDao = new DeployDao();

        (token, timelock, governor, store) = deployDao.run();

        token.mint(VOTER, 100e18);

        vm.prank(VOTER);
        token.delegate(VOTER);

        vm.startPrank(address(timelock));
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.CANCELLER_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, address(timelock));
        vm.stopPrank();
    }

    function testCantUpdatestoreWithoutGovernance() public {
        vm.expectRevert();
        store.store(1);
    }

    function testGovernanceUpdatesstore() public {
        uint256 valueToStore = 777;
        string memory description = "Store 1 in store";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "store(uint256)",
            valueToStore
        );
        addressesToCall.push(address(store));
        values.push(0);
        functionCalls.push(encodedFunctionCall);
        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        console.log("Proposal State:", uint256(governor.state(proposalId)));
        // governor.proposalSnapshot(proposalId)
        // governor.proposalDeadline(proposalId)

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "I like a do da cha cha";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(store.retrieve() == valueToStore);
    }
}
