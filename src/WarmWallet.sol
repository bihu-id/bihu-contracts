pragma solidity ^0.4.8;

import "ds-token/token.sol";
import "ds-auth/auth.sol";


contract WarmWalletEvents {
    event LogSetWithdrawer (address indexed withdrawer);
    event LogSetWithdrawLimit (address indexed sender, uint value);
}

contract WarmWallet is DSStop, WarmWalletEvents{

    DSToken public key;
    address public hotWallet;
    address public coldWallet;

    //@note
    address public withdrawer;
    uint public withdrawLimit;
    uint256 public lastWithdrawTime;

    modifier onlyWithdrawer {
        require(msg.sender == withdrawer);
        _;
    }

    // overrideable for easy testing
    function time() public returns (uint) {
        return now;
    }

    function WarmWallet(DSToken _key, address _hot, address _cold, address _withdrawer, uint _limit){
        require(_key != address(0) );
        require(_hot != address(0) );
        require(_cold != address(0) );
        require(_withdrawer != address(0) );
        require(_limit > 0);

        require(_key != _hot);
        require(_key != _cold);
        require(_key != _withdrawer);

        key = _key;
        hotWallet = _hot;
        coldWallet = _cold;

        withdrawer = _withdrawer;
        withdrawLimit = _limit;
    }

    function forwardToHotWallet(uint _amount) stoppable onlyWithdrawer {
        require(_amount > 0);
        uint _time = time();
        require(_time > (lastWithdrawTime + 24 hours));

        uint amount = _amount;
        if (amount > withdrawLimit) {
            amount = withdrawLimit;
        }

        key.transfer(hotWallet, amount);
        lastWithdrawTime = _time;
    }

    function restoreToColdWallet(uint _amount) onlyWithdrawer {
        require(_amount > 0);
        key.transfer(coldWallet, _amount);
    }

    function setWithdrawer(address _withdrawer) auth {
        withdrawer = _withdrawer;
        LogSetWithdrawer(_withdrawer);
    }

    function setWithdrawLimit(uint _limit) auth {
        withdrawLimit = _limit;
        LogSetWithdrawLimit(msg.sender, _limit);
    }


    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) onlyWithdrawer {
        require(_token != address(key));
        if (wad > 0) {
            ERC20 token = ERC20(_token);
            token.transfer(dst, wad);
        }
    }



}
