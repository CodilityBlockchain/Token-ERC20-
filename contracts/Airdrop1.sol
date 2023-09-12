// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Airdrop1 {
    using SafeMath for uint256;
    address platformOwner;
    uint256 platformFees = 100;
    uint256 airdropCounter = 1;
    struct info {
        IERC20 token;
        address user;
        uint256 amount;
        uint256 remainingAmount;
        address[] users;
        uint256 amountPeruser;
        bool isActive;
    }
    mapping(uint256 => info) airdropInfo;
    mapping(uint256 => address) claimed;
    event Claim(address indexed user);

    constructor() {
        platformOwner = msg.sender;
    }

    function inititalize(
        address _token,
        uint256 _amount,
        uint256 _amountPeruser
    ) public {
        IERC20 token_ = IERC20(_token);
        require(
            airdropInfo[airdropCounter].token != token_,
            "already airdropped"
        );
        airdropInfo[airdropCounter].token.approve(address(this), _amount);
        airdropInfo[airdropCounter].token = token_;
        airdropInfo[airdropCounter].user = msg.sender;
        airdropInfo[airdropCounter].amount = _amount;
        airdropInfo[airdropCounter].remainingAmount = _amount;
        airdropInfo[airdropCounter].amountPeruser = _amountPeruser;
        airdropInfo[airdropCounter].isActive = true;
        airdropInfo[airdropCounter].token.transfer(
            platformOwner,
            platformFees * 10 ** airdropInfo[airdropCounter].token.decimals()
        );
        airdropCounter++;
    }

    function claim(uint256 airdropId) public {
        require(airdropInfo[airdropId].isActive, "not active");
        require(claimed[airdropId] != msg.sender, "already claimed");
        require(
            airdropInfo[airdropId].remainingAmount >=
                airdropInfo[airdropId].amountPeruser,
            "insufficient remaining amount"
        );
        airdropInfo[airdropId].token.transferFrom(
            airdropInfo[airdropId].user,
            msg.sender,
            airdropInfo[airdropId].amountPeruser
        );
        airdropInfo[airdropId].remainingAmount =
            airdropInfo[airdropId].remainingAmount -
            airdropInfo[airdropId].amountPeruser;
        airdropInfo[airdropId].users.push(msg.sender);
        claimed[airdropId] = msg.sender;
        emit Claim(msg.sender);
    }

    function closeAirdrop(uint256 airdropId) public {
        require(airdropInfo[airdropId].isActive, "not active");
        require(airdropInfo[airdropId].user == msg.sender, "invalid user");
        airdropInfo[airdropId].isActive = false;
        airdropInfo[airdropId].remainingAmount = 0;
    }

    function getAirdropDetails(
        uint256 airdropId
    )
        public
        view
        returns (
            IERC20,
            address,
            uint256,
            uint256,
            address[] memory,
            uint256,
            bool
        )
    {
        info memory i = airdropInfo[airdropId];
        return (
            i.token,
            i.user,
            i.amount,
            i.remainingAmount,
            i.users,
            i.amountPeruser,
            i.isActive
        );
    }

    function addMoreTokens(uint256 airdropId, uint256 _amount) public {
        require(airdropInfo[airdropId].user == msg.sender, "invalid user");
        airdropInfo[airdropId].amount = airdropInfo[airdropId].amount.add(
            _amount
        );
        airdropInfo[airdropId].amount = airdropInfo[airdropId]
            .remainingAmount
            .add(_amount);
        airdropInfo[airdropId].token.approve(address(this), _amount);
    }
}
