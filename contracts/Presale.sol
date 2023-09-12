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

contract Presale {
    using SafeMath for uint256;
    address platformOwner;
    uint256 platformFees = 0.0001 ether;
    uint256 presaleCounter = 1;
    struct info {
        IERC20 token;
        address user;
        uint256 amount;
        uint256 price;
        uint256 remainingAmount;
        address[] users;
        bool isActive;
    }
    mapping(uint256 => info) presaleInfo;
    mapping(uint256 => address) claimed;
    event BUY(address indexed user, uint256 indexed amountOfToken);

    constructor() {
        platformOwner = msg.sender;
    }

    function inititalize(
        address _token,
        uint256 _amount,
        uint256 _price
    ) public payable {
        IERC20 token_ = IERC20(_token);
        require(
            presaleInfo[presaleCounter].token != token_,
            "already Presale On"
        );
        require(msg.value == platformFees, "0.0001 is the platforfees");
        presaleInfo[presaleCounter].token.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        presaleInfo[presaleCounter].token = token_;
        presaleInfo[presaleCounter].user = msg.sender;
        presaleInfo[presaleCounter].amount = _amount;
        presaleInfo[presaleCounter].remainingAmount = _amount;
        presaleInfo[presaleCounter].price = _price;
        presaleInfo[presaleCounter].isActive = true;
        payable(platformOwner).transfer(msg.value);
        presaleCounter++;
    }

    function buy(uint256 presaleId) public payable {
        require(presaleInfo[presaleId].isActive, "not active");
        require(
            msg.value >= presaleInfo[presaleId].price,
            "value less than price "
        );
        uint256 tokenAmount = msg.value.div(presaleInfo[presaleId].price);
        tokenAmount = tokenAmount * msg.value;
        require(
            presaleInfo[presaleId].remainingAmount >= tokenAmount,
            "insufficient remaining amount"
        );
        presaleInfo[presaleId].token.transferFrom(
            presaleInfo[presaleId].user,
            msg.sender,
            tokenAmount
        );
        presaleInfo[presaleId].remainingAmount =
            presaleInfo[presaleId].remainingAmount -
            tokenAmount;
        presaleInfo[presaleId].users.push(msg.sender);
        emit BUY(msg.sender, tokenAmount);
    }

    function closePresale(uint256 presaleId) public {
        require(presaleInfo[presaleId].isActive, "not active");
        require(presaleInfo[presaleId].user == msg.sender, "invalid user");
        presaleInfo[presaleId].isActive = false;
        presaleInfo[presaleId].token.transfer(
            msg.sender,
            presaleInfo[presaleId].remainingAmount
        );
        presaleInfo[presaleId].remainingAmount = 0;
    }

    function getPresaleDetails(
        uint256 presaleId
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
        info memory i = presaleInfo[presaleId];
        return (
            i.token,
            i.user,
            i.amount,
            i.remainingAmount,
            i.users,
            i.price,
            i.isActive
        );
    }

    function addMoreTokens(uint256 presaleId, uint256 _amount) public {
        require(presaleInfo[presaleId].user == msg.sender, "invalid user");
        presaleInfo[presaleId].amount = presaleInfo[presaleId].amount.add(
            _amount
        );
        presaleInfo[presaleId].amount = presaleInfo[presaleId]
            .remainingAmount
            .add(_amount);
        presaleInfo[presaleId].token.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }
}
