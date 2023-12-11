// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

/**
 * @title RewardToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A mintable ERC20 with 2 decimals to issue rewards
 */
contract RewardToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error Forbidden();

    constructor() ERC20("Reward Token", "RWT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert Forbidden();
        _mint(to, amount);
    }
}

//    /**
//      * @dev Returns `true` if `account` has been granted `role`.
//      */
//     function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
//         return _roles[role].members[account];
//     }

// /**
//      * @dev Grants `role` to `account`.
//      *
//      * If `account` had not been already granted `role`, emits a {RoleGranted}
//      * event. Note that unlike {grantRole}, this function doesn't perform any
//      * checks on the calling account.
//      *
//      * May emit a {RoleGranted} event.
//      *
//      * [WARNING]
//      * ====
//      * This function should only be called from the constructor when setting
//      * up the initial roles for the system.
//      *
//      * Using this function in any other way is effectively circumventing the admin
//      * system imposed by {AccessControl}.
//      * ====
//      *
//      * NOTE: This function is deprecated in favor of {_grantRole}.
//      */
//     function _setupRole(bytes32 role, address account) internal virtual {
//         _grantRole(role, account);
//     }

// /**
//      * @dev Grants `role` to `account`.
//      *
//      * Internal function without access restriction.
//      *
//      * May emit a {RoleGranted} event.
//      */
//     function _grantRole(bytes32 role, address account) internal virtual {
//         if (!hasRole(role, account)) {
//             _roles[role].members[account] = true;
//             emit RoleGranted(role, account, _msgSender());
//         }
//     }

//  struct RoleData {
//         mapping(address => bool) members;
//         bytes32 adminRole;
//     }

//     mapping(bytes32 => RoleData) private _roles;

//     bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
