// SPDX-License-Identifier: MIT

// Crypto Birds XCB Token Faucet 1.1
// This smart contract is created by the Community and is not affiliated with Crypto Birds Platform.
// Please visit cryptobirds.com if you are looking for official information.

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity 0.8.17;

contract XCBRewards {

    address public owner;
    bool public paused;
    IERC20Metadata public tokenContract;
    uint256 public rewardMin;
    uint256 public rewardMax;
    uint256 public rewardWaitingTime;    
    uint256 public rewardAllowed;
    uint256 internal rewardCount;
    uint256 public rewardTimelock;
    uint256 internal rewardLastClaimed;

    mapping(address => uint256) public rewardGains;
    mapping(address => uint256) public rewardLastTime;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (IERC20Metadata _tokenContract, 
                uint256 _rewardMin, 
                uint256 _rewardMax, 
                uint256 _rewardWaitingTime,
                uint256 _rewardAllowed,
                uint256 _rewardTimelock
        ) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        rewardMin = _rewardMin;
        rewardMax = _rewardMax;
        rewardWaitingTime = _rewardWaitingTime;
        rewardAllowed = _rewardAllowed;
        rewardTimelock = _rewardTimelock;
        rewardCount = 0;
        rewardLastClaimed = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Error. Caller is not the owner.");
        _;
    }    

    // ----------------------
    // Contract info

    function getContractBalance() external view returns (uint256) {
        return tokenContract.balanceOf(address(this)); 
    }

    function setContractPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    // ----------------------
    // Token info

    function getTokenName() external view returns (string memory) {
        return tokenContract.name(); 
    }

    function getTokenSymbol() external view returns (string memory) {
        return tokenContract.symbol(); 
    }

    // ----------------------
    // Rewards Center  

    function claimReward() public {
        require(paused == false, "Error. Contract paused");
        require(rewardCount < rewardAllowed, "Error. Completed.");
        require(tokenContract.balanceOf(address(this)) > rewardMax, "Error. Insufficient balance.");
        require(isWalletEnabled(msg.sender),"Error. You must wait to receive rewards again.");
        require(rewardMax >= rewardMin,"Error. Setting wrong.");
        require(block.timestamp >= rewardLastClaimed + rewardTimelock, "Error. You must wait at Locker Time.");
        uint _amountReward = setAmountReward();
        tokenContract.transfer(address(msg.sender), _amountReward);
        rewardGains[msg.sender] = _amountReward;
        rewardLastTime[msg.sender] = block.timestamp;
        rewardCount++;
        rewardLastClaimed = block.timestamp;
        emit Transfer(address(this), msg.sender, _amountReward);
    } 

     function isWalletEnabled(address _user) internal view returns (bool) {
        if(rewardLastTime[_user] == 0) {
            return true;
        } else if(block.timestamp >= rewardLastTime[_user] + rewardWaitingTime) {
            return true;
        }
        return false;
    }

    function getWalletWaitingTime(address _user) public view returns (uint256) {
        uint timer = 0;
        if (isWalletEnabled(_user) == false ) {
            timer = rewardLastTime[_user] + rewardWaitingTime - block.timestamp;
        }
        return timer; 
    }

    function setAmountReward() internal view returns(uint){
        uint amount;
        if(rewardMax > rewardMin) {
            uint number = rewardMax - rewardMin;
            amount = rewardMin + uint(blockhash(block.number-1)) % number;
        } else {
            amount = rewardMax;
        }
        return amount;
    }   

    function getSuccessClaims() public view returns (uint256) {
        return rewardCount; 
    }
    
    function getTimelockCountdown() public view returns (uint256) {
        if ( block.timestamp >= rewardLastClaimed + rewardTimelock ) {
            return 0;
        } else {
            return rewardLastClaimed + rewardTimelock - block.timestamp;
        }
    }    

    function withdrawRewards(uint256 _tokenAmount) public onlyOwner {
        tokenContract.transfer(address(msg.sender), _tokenAmount);
    }
    
    function updateRewards(
            uint256 _rewardMin, 
            uint256 _rewardMax, 
            uint256 _rewardWaitingTime,
            uint256 _rewardAllowed,
			uint256 _rewardTimelock
        ) public onlyOwner {
        rewardMin = _rewardMin;
        rewardMax = _rewardMax;
        rewardWaitingTime = _rewardWaitingTime;
        rewardAllowed = _rewardAllowed;
		rewardTimelock = _rewardTimelock;
        rewardCount = 0;
		rewardLastClaimed = 0;
    } 

}
