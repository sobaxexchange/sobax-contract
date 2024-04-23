// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/ISBlpManager.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardTracker.sol";

// provide a way to transfer staked SBLP tokens by unstaking from the sender
// and staking for the receiver
// tests in RewardRouterV2.js
contract StakedSBlp {
    using SafeMath for uint256;

    string public constant name = "StakedSBlp";
    string public constant symbol = "sSBLP";
    uint8 public constant decimals = 18;

    address public sblp;
    ISBlpManager public sblpManager;
    address public stakedSBlpTracker;
    address public feeSBlpTracker;

    mapping (address => mapping (address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _sblp,
        ISBlpManager _sblpManager,
        address _stakedSBlpTracker,
        address _feeSBlpTracker
    ) public {
        sblp = _sblp;
        sblpManager = _sblpManager;
        stakedSBlpTracker = _stakedSBlpTracker;
        feeSBlpTracker = _feeSBlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "StakedSBlp: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function balanceOf(address _account) external view returns (uint256) {
        return IRewardTracker(feeSBlpTracker).depositBalances(_account, sblp);
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(stakedSBlpTracker).totalSupply();
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "StakedSBlp: approve from the zero address");
        require(_spender != address(0), "StakedSBlp: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "StakedSBlp: transfer from the zero address");
        require(_recipient != address(0), "StakedSBlp: transfer to the zero address");

        require(
            sblpManager.lastAddedAt(_sender).add(sblpManager.cooldownDuration()) <= block.timestamp,
            "StakedSBlp: cooldown duration not yet passed"
        );

        IRewardTracker(stakedSBlpTracker).unstakeForAccount(_sender, feeSBlpTracker, _amount, _sender);
        IRewardTracker(feeSBlpTracker).unstakeForAccount(_sender, sblp, _amount, _sender);

        IRewardTracker(feeSBlpTracker).stakeForAccount(_sender, _recipient, sblp, _amount);
        IRewardTracker(stakedSBlpTracker).stakeForAccount(_recipient, _recipient, feeSBlpTracker, _amount);
    }
}
