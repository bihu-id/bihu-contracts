pragma solidity ^0.4.0;

import "ds-math/math.sol";
import "ds-token/token.sol";

contract KeyRewardPool is DSStop , DSMath{

    DSToken public key;
    uint256 public rewardStartTime;

    uint256 constant public yearlyRewardRate = 10; // 10% of remaining tokens
    uint256 public totalRewardThisYear;

    uint256 public collectedTokens;

    function KeyRewardPool(uint256 _rewardStartTime, address _key){
        rewardStartTime = _rewardStartTime;

        key = DSToken(_key);
    }

    // @notice call this method to extract the tokens
    function collectToken() auth{

        require(time() > rewardStartTime);

        uint256 balance = key.balanceOf(address(this));

        uint256 total = add(collectedTokens, balance);

        uint yearCount = yearFor(time());

        uint256 remainingTokens = total;
        for(uint i = 0; i < yearCount; i++) {
            remainingTokens =  div( mul(remainingTokens, 100 - yearlyRewardRate), 100);
        }
        //
        totalRewardThisYear =  div( mul(remainingTokens, yearlyRewardRate), 100);

        // the reward will be increasing linearly in one year.
        uint256 canExtractThisYear = div( mul(totalRewardThisYear, (time() - rewardStartTime)  % 365 days), 365 days);

        uint256 canExtract = canExtractThisYear + (total - remainingTokens);

        canExtract = sub(canExtract, collectedTokens);

        if(canExtract > balance) {
            canExtract = balance;
        }

        assert(key.transfer(owner, canExtract));
        collectedTokens = add(collectedTokens, canExtract);

        TokensWithdrawn(owner, canExtract);
    }


    function yearFor(uint timestamp) constant returns(uint) {
        return timestamp < rewardStartTime
        ? 0
        : sub(timestamp, rewardStartTime) / (365 days);
    }

    function time() constant returns (uint256) {
        return now;
    }

    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) public auth note {

        require( _token != address(key));

        ERC20 token = ERC20(_token);
        token.transfer(dst, wad);
    }

    event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
