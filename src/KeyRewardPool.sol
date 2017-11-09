pragma solidity ^0.4.8;

import "ds-math/math.sol";
import "ds-token/token.sol";

contract KeyRewardPool is DSStop , DSMath{

    DSToken public key;
    uint public rewardStartTime;

    uint constant public yearlyRewardPercentage = 10; // 10% of remaining tokens
    uint public totalRewardThisYear;

    uint public collectedTokens;

    event TokensWithdrawn(address indexed _holder, uint _amount);

    function KeyRewardPool(uint _rewardStartTime, address _key){
        rewardStartTime = _rewardStartTime;

        key = DSToken(_key);
    }

    // @notice call this method to extract the tokens
    function collectToken() auth{
        uint _time = time();
        var _key = key;  // create a in memory variable for storage variable will save gas usage.

        require(_time > rewardStartTime);

        uint balance = _key.balanceOf(address(this));
        uint total = add(collectedTokens, balance);

        uint remainingTokens = total;

        uint yearCount = yearFor(_time);

        for(uint i = 0; i < yearCount; i++) {
            remainingTokens =  div( mul(remainingTokens, 100 - yearlyRewardPercentage), 100);
        }
        //
        totalRewardThisYear =  div( mul(remainingTokens, yearlyRewardPercentage), 100);

        // the reward will be increasing linearly in one year.
        uint canExtractThisYear = div( mul(totalRewardThisYear, (_time - rewardStartTime)  % 365 days), 365 days);

        uint canExtract = canExtractThisYear + total - remainingTokens;

        canExtract = sub(canExtract, collectedTokens);

        if(canExtract > balance) {
            canExtract = balance;
        }

        
        collectedTokens = add(collectedTokens, canExtract);

        assert(_key.transfer(owner, canExtract)); // Fix potential re-entry bug.
        TokensWithdrawn(owner, canExtract);
    }


    function yearFor(uint timestamp) constant returns(uint) {
        return timestamp < rewardStartTime
            ? 0
            : sub(timestamp, rewardStartTime) / (365 days);
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) public auth note {
        require( _token != address(key));
        if (wad > 0) {
            ERC20 token = ERC20(_token);
            token.transfer(dst, wad);
        }
    }

    
}
