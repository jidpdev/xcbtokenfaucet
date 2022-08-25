// SPDX-License-Identifier: MIT

// Crypto Birds XCB Token Faucet
// This smart contract is created by the Community and is not affiliated with Crypto Birds Platform.
// Please visit cryptobirds.com if you are looking for official information.

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity 0.8.16;

contract FaucetTokenXCB {

    address public owner;
    IERC20Metadata public tokenContract;
    uint256 public setRewardMin;
    uint256 public setRewardMax;
    uint256 public setTimeWait;    
    uint256 public setAllowedClaims;
    uint256 internal claimCount;

    mapping(address => uint256) public rewardGains;
    mapping(address => uint256) public rewardLastTime;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (IERC20Metadata _tokenContract, 
                uint256 _setRewardMin, 
                uint256 _setRewardMax, 
                uint256 _setTimeWait,
                uint256 _setAllowedClaims
        ) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        setRewardMin = _setRewardMin;
        setRewardMax = _setRewardMax;
        setTimeWait = _setTimeWait;
        setAllowedClaims = _setAllowedClaims;
        claimCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Error. Caller is not the owner.");
        _;
    }    

    // ----------------------
    // Contract info

    function contractBalance() external view returns (uint256) {
        return tokenContract.balanceOf(address(this)); 
    }


    // ----------------------
    // Token info

    function tokenName() external view returns (string memory) {
        return tokenContract.name(); 
    }

    function tokenSymbol() external view returns (string memory) {
        return tokenContract.symbol(); 
    }

    // ----------------------
    // Faucet  

    function faucetClaim() public {
        require(claimCount < setAllowedClaims, "Error. Completed.");
        require(tokenContract.balanceOf(address(this)) > setRewardMax, "Error. Insufficient balance.");
        require(faucetWalletEnabled(),"Error. You must wait to receive rewards again.");
		require(setRewardMax >= setRewardMin,"Error. Setting wrong.");
        uint _amountReward = faucetAmountReward();
        tokenContract.transfer(address(msg.sender), _amountReward);
        rewardGains[msg.sender] = _amountReward;
        rewardLastTime[msg.sender] = block.timestamp;
        claimCount++;
        emit Transfer(address(this), msg.sender, _amountReward);
    } 

     function faucetWalletEnabled() internal view returns (bool) {
        if(rewardLastTime[msg.sender] == 0) {
            return true;
        } else if(block.timestamp >= rewardLastTime[msg.sender] + setTimeWait) {
            return true;
        }
        return false;
    }

    function faucetWalletTimer() public view returns (uint256) {
		uint timer = 0;
		if (faucetWalletEnabled() == false ) {
			timer = rewardLastTime[msg.sender] + setTimeWait - block.timestamp;
		}
        return timer; 
    }

    function faucetAmountReward() internal view returns(uint){
        uint amount;
        if(setRewardMax > setRewardMin) {
            uint number = setRewardMax - setRewardMin;
            amount = setRewardMin + uint(blockhash(block.number-1)) % number;
        } else {
            amount = setRewardMax;
        }
        return amount;
    }   

    function faucetSuccessClaims() public view returns (uint256) {
        return claimCount; 
    }

    function faucetWithdraw(uint256 _tokenAmount) public onlyOwner {
         tokenContract.transfer(address(msg.sender), _tokenAmount);
    }
    
    function faucetUpdate(
            uint256 _setRewardMin, 
            uint256 _setRewardMax, 
            uint256 _setTimeWait,
            uint256 _setAllowedClaims
        ) public onlyOwner {
        setRewardMin = _setRewardMin;
        setRewardMax = _setRewardMax;
        setTimeWait = _setTimeWait;
        setAllowedClaims = _setAllowedClaims;
        claimCount = 0;
    } 

}
