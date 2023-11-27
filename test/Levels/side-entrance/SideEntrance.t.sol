// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 internal constant _ETHER_IN_POOL = 1_000e18;

    Utilities internal _utils;
    SideEntranceLenderPool internal _sideEntranceLenderPool;
    address payable internal _attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        _utils = new Utilities();
        address payable[] memory users = _utils.createUsers(1);
        _attacker = users[0];
        vm.label(_attacker, "Attacker");

        _sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(_sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(_sideEntranceLenderPool), _ETHER_IN_POOL);

        assertEq(address(_sideEntranceLenderPool).balance, _ETHER_IN_POOL);

        attackerInitialEthBalance = address(_attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        //What do we know
        // LenderPool has 1_000e18 ether
        // our attacker is users[0]
        //we need to drain lenderpool

        /**
         * EXPLOIT END *
         */
        _validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function _validation() internal {
        assertEq(address(_sideEntranceLenderPool).balance, 0);
        assertGt(_attacker.balance, attackerInitialEthBalance);
    }
}
