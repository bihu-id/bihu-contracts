pragma solidity ^0.4.0;


import "ds-token/token.sol";

contract KeyRewardHolder is DSStop{

    DSToken public key;
    uint256 public rewardStartTime;

    uint256 constant public yearlyRewardRate = percent(5); // 5% of remaining
    uint256 public totalRewardThisYear;

    uint256 public collectedTokens;

    function KeyRewardHolder(uint256 _rewardStartTime, address _key){
        rewardStartTime = _rewardStartTime;

        key = DSToken(_key);
    }

    // @notice call this method to extract the tokens

    function collectToken() auth{

        require(getTime() > rewardStartTime);

        uint256 balance = key.balanceOf(address(this));

        uint256 total = collectedTokens.add(balance);

        uint yearCount = yearFor(getTime());

        uint256 remainingTokens = total;
        for(uint i = 0; i < yearCount; i++) {

            remainingTokens = remainingTokens * (1 - yearlyRewardRate);
        }
        // 5% of remaining tokens
        totalRewardThisYear = remainingTokens * yearlyRewardRate;

        // the reward will be increasing linearly in one year.
        uint256 canExtractThisYear = totalRewardThisYear.mul(getTime().sub(timeStampForYear(yearCount))).div(365 days);
        uint256 canExtract = canExtractThisYear + (total - remainingTokens);

        canExtract = canExtract.sub(collectedTokens);

        if(canExtract > balance) {
            canExtract = balance;
        }

        assert(key.transfer(owner, canExtract));
        collectedTokens = collectedTokens.add(canExtract);

        TokensWithdrawn(owner, canExtract);
    }


    function yearFor(uint timestamp) constant returns(uint) {
        return timestamp < rewardStartTime
        ? 0
        : sub(timestamp, rewardStartTime) / 365 days;
    }

    function timeStampForYear(uint n) constant returns(uint256) {
        require(n >= 0);

        return rewardStartTime.add(n.mul(365 days));
    }


    function getTime() constant returns (uint256) {
        return now;
    }


    function percent(uint256 p) internal returns (uint256) {
        return p.mul(10**16);
    }



    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) public auth note {
        ERC20 token = ERC20(_token);
        token.transfer(dst, wad);
    }

    event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
