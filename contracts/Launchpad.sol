// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                customRevert
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                customRevert
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                customRevert
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(
        bytes memory returndata,
        function() internal view customRevert
    ) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using Address for address;
    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 requestedDecrease
    );

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 requestedDecrease
    ) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(
                    spender,
                    currentAllowance,
                    requestedDecrease
                );
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.transfer.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transfer.selector, spender, 0)
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            address(token).code.length > 0;
    }
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

contract Launchpad {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address launcpadOwner;
    uint256 platformFees = 0.001 ether;
    event CreatePresale(
        address indexed tokenAddress,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event AddMore(uint256 indexed count, uint256 indexed amount);
    event InvesWithBNB(uint256 indexed count, uint256 indexed amount);
    event InvestWithUSDT(uint256 indexed count, uint256 indexed amount);
    event UpdateCaps(
        uint256 indexed count,
        uint256 indexed softCap,
        uint256 indexed hardCap
    );
    event UpdatePrice(uint256 indexed count, uint256 indexed price);
    event UpdateMinInvestment(
        uint256 indexed count,
        uint256 indexed minimumInvestment
    );

    event UpdateTime(
        uint256 indexed count,
        uint256 indexed startingtime,
        uint256 indexed endingTime
    );
    event ClosePresale(uint256 indexed count);
    struct details {
        address tokenAddress;
        string metadata;
        IERC20 paymentToken;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 softCap;
        uint256 hardCap;
        uint256 minimumInvestment;
        uint256 maximumInvestment;
        uint256 remainingAmount;
        bool status;
    }
    mapping(uint256 => details) presaleDetails;
    mapping(address => bool) public isPurchasedListed;
    uint256 presaleCounter = 1;

    constructor() {
        launcpadOwner = msg.sender;
    }

    modifier onlyLaunchpadOwner() {
        require(msg.sender == launcpadOwner, "Launchpad owner can call");
        _;
    }

    function createPresaleBNB(
        address _tokenAddress,
        string memory _metadata,
        uint256 _amount,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minimumInvestment,
        uint256 _maximumInvestment
    ) public returns (bool) {
        details storage pre = presaleDetails[presaleCounter];
        IERC20 tokenAddress = IERC20(_tokenAddress);
        require(pre.status == false, "token on presale already");
        require(
            tokenAddress.balanceOf(msg.sender) >= _amount,
            "insufficient amount"
        );
        require(
            pre.hardCap >= pre.softCap,
            "hardcap should be greater than softcap"
        );
        require(
            pre.maximumInvestment >= pre.minimumInvestment,
            "maximum investment should be greater than minimum invesment"
        );
        tokenAddress.transferFrom(msg.sender, address(this), _amount);
        pre.tokenAddress = _tokenAddress;
        pre.seller = msg.sender;
        pre.metadata = _metadata;
        pre.price = _price;
        pre.amount = _amount;
        pre.endTime = _endTime;
        pre.startTime = _startTime;
        pre.softCap = _softCap;
        pre.hardCap = _hardCap;
        pre.minimumInvestment = _minimumInvestment;
        pre.maximumInvestment = _maximumInvestment;
        pre.remainingAmount = _amount;
        pre.status = true;
        emit CreatePresale(_tokenAddress, msg.sender, address(this), _amount);
        return true;
    }

    function createPresaleToken(
        address _tokenAddress,
        string memory _metadata,
        IERC20 paymentToken,
        uint256 _amount,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minimumInvestment,
        uint256 _maximumInvestment
    ) public returns (bool) {
        details storage pre = presaleDetails[presaleCounter];
        IERC20 tokenAddress = IERC20(_tokenAddress);
        require(pre.status == false, "token on presale already");
        require(
            tokenAddress.balanceOf(msg.sender) >= _amount,
            "insufficient amount"
        );
        require(
            pre.hardCap >= pre.softCap,
            "hardcap should be greater than softcap"
        );
        require(
            pre.maximumInvestment >= pre.minimumInvestment,
            "maximum investment should be greater than minimum invesment"
        );
        tokenAddress.transferFrom(msg.sender, address(this), _amount);
        pre.tokenAddress = _tokenAddress;
        pre.seller = msg.sender;
        pre.metadata = _metadata;
        pre.price = _price;
        pre.paymentToken = paymentToken;
        pre.amount = _amount;
        pre.endTime = _endTime;
        pre.startTime = _startTime;
        pre.softCap = _softCap;
        pre.hardCap = _hardCap;
        pre.minimumInvestment = _minimumInvestment;
        pre.maximumInvestment = _maximumInvestment;
        pre.remainingAmount = _amount;
        pre.status = true;
        emit CreatePresale(_tokenAddress, msg.sender, address(this), _amount);
        return true;
    }

    function getPresaleDetail(
        uint256 _counter
    )
        public
        view
        returns (
            address _tokenAddress,
            address _seller,
            IERC20 paymentToken,
            string memory _metadata,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _softCap,
            uint256 _hardCap,
            uint256 _minimumInvestment,
            uint256 _maximumInvestment,
            uint256 _remainingAmount,
            uint256 price
        )
    {
        details storage pre = presaleDetails[(_counter)];
        return (
            pre.tokenAddress,
            pre.seller,
            pre.paymentToken,
            pre.metadata,
            pre.startTime,
            pre.endTime,
            pre.softCap,
            pre.hardCap,
            pre.minimumInvestment,
            pre.maximumInvestment,
            pre.remainingAmount,
            pre.price
        );
    }

    function totalPresale() public view returns (uint256) {
        return presaleCounter;
    }

    function investWithBNB(
        uint256 _count,
        uint256 _amount
    ) public payable returns (bool) {
        require(
            !isPurchasedListed[msg.sender],
            "Address has purchased already"
        );
        details memory pre = presaleDetails[_count];
        IERC20 _tokenAddress = IERC20(pre.tokenAddress);
        uint256 _price = _amount.mul(pre.price);
        require(
            _tokenAddress.balanceOf(address(this)) >= _amount,
            "tokens are not enough"
        );
        require(
            msg.value <= pre.maximumInvestment,
            "increase maximum investment "
        );
        require(
            msg.value <= pre.maximumInvestment,
            "increase maximum investment "
        );
        require(pre.endTime >= block.timestamp, "presale ended");
        payable(pre.seller).transfer(_price);
        _tokenAddress.approve(msg.sender, _amount);
        _tokenAddress.transferFrom(address(this), msg.sender, _amount);
        pre.remainingAmount = pre.amount - _amount;
        emit InvesWithBNB(_count, _amount);
        isPurchasedListed[msg.sender] = true;
        presaleCounter++;
        return true;
    }

    function investWithUSDT(
        uint256 _count,
        uint256 _USDTamount
    ) public returns (uint256) {
        require(
            !isPurchasedListed[msg.sender],
            "Address has purchased already"
        );
        details memory pre = presaleDetails[_count];
        IERC20 _tokenAddress = IERC20(pre.tokenAddress);
        uint256 _amount = _USDTamount.mul(pre.price).div(1e18);
        require(
            _USDTamount <= pre.maximumInvestment,
            "increase maximum investment "
        );
        require(
            _USDTamount >= pre.minimumInvestment,
            "less than minimum investment "
        );
        require(pre.status == true, "presale status ended");
        require(pre.endTime >= block.timestamp, "presale time ended");
        require(pre.startTime <= block.timestamp, "presale is not active");
        require(
            _tokenAddress.balanceOf(address(this)) >= _amount,
            "balance low"
        );
        presaleDetails[_count].paymentToken.transferFrom(
            msg.sender,
            pre.seller,
            _USDTamount
        );
        _tokenAddress.transfer(msg.sender, _amount);
        pre.remainingAmount = pre.amount - _amount;
        emit InvestWithUSDT(_count, _USDTamount);
        isPurchasedListed[msg.sender] = true;
        return _amount;
    }

    function closePresale(uint256 _count) public returns (bool) {
        IERC20 _tokenAddress = IERC20(presaleDetails[_count].tokenAddress);
        require(
            msg.sender == presaleDetails[_count].seller,
            "only seller can call"
        );
        _tokenAddress.transfer(
            msg.sender,
            _tokenAddress.balanceOf(address(this))
        );
        presaleDetails[_count].status = false;
        emit ClosePresale(_count);
        return true;
    }

    function withdrawTokens(
        uint256 _count,
        address _tokenAddress
    ) public returns (bool) {
        require(
            msg.sender == presaleDetails[_count].seller,
            "only seller can call"
        );
        IERC20 tokenAddress = IERC20(_tokenAddress);
        tokenAddress.transfer(
            msg.sender,
            tokenAddress.balanceOf(address(this))
        );
        return true;
    }

    function updateTime(
        uint256 _count,
        uint256 _startingtime,
        uint256 _endingTime
    ) public {
        require(msg.sender == presaleDetails[_count].seller, "seller can call");
        presaleDetails[_count].startTime = _startingtime;
        presaleDetails[_count].endTime = _endingTime;
        emit UpdateTime(_count, _startingtime, _endingTime);
    }

    function updatePrice(uint256 _count, uint256 _price) public {
        require(msg.sender == presaleDetails[_count].seller, "seller can call");
        presaleDetails[_count].price = _price;
        emit UpdatePrice(_count, _price);
    }

    function updateMinInvestment(uint256 _count, uint256 _minInvest) public {
        require(msg.sender == presaleDetails[_count].seller, "seller can call");
        presaleDetails[_count].minimumInvestment = _minInvest;
        emit UpdateMinInvestment(_count, _minInvest);
    }

    function updateCaps(
        uint256 _count,
        uint256 _softCap,
        uint256 _hardCap
    ) public {
        require(msg.sender == presaleDetails[_count].seller, "seller can call");
        presaleDetails[_count].softCap = _softCap;
        presaleDetails[_count].hardCap = _hardCap;
        emit UpdateCaps(_count, _softCap, _hardCap);
    }

    function addMoreTokens(
        uint256 _count,
        uint256 amount
    ) public returns (uint256) {
        details memory pre = presaleDetails[_count];
        IERC20 tokenAddress = IERC20(pre.tokenAddress);
        require(msg.sender == presaleDetails[_count].seller, "seller can call");
        presaleDetails[_count].amount = presaleDetails[_count].amount + amount;
        uint256 balance = tokenAddress.balanceOf(address(this));
        balance = balance + amount;
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit AddMore(_count, amount);
        return balance;
    }

    function getPresaleStatus(uint256 _count) public view returns (bool) {
        details memory pre = presaleDetails[_count];
        return pre.status;
    }

    function calculateTokens(
        uint256 _usdt,
        uint256 _count
    ) public view returns (uint256) {
        details memory pre = presaleDetails[_count];
        return _usdt.mul(pre.price).div(1e18);
    }
}
