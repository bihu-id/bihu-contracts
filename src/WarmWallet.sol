pragma solidity ^0.4.0;

import "ds-token/token.sol";
import "ds-auth/auth.sol";


contract WarmWalletEvents {
    event LogSetWithdrawer (address indexed withdrawer);
    event LogSetWithdrawLimit (address indexed sender, uint value);
//    event LogSetOwner     (address indexed owner);
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
        assert(msg.sender == withdrawer);
        _;
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    function WarmWallet(DSToken _key, address _hot, address _cold, address _withdrawer, uint _limit){
        require(address(_key) != 0x0 );

        key = _key;
        hotWallet = _hot;
        coldWallet = _cold;

        withdrawer = _withdrawer;
        withdrawLimit = _limit;
    }

    function forwardToHotWallet(uint _amount) stoppable onlyWithdrawer {
        require(_amount > 0);
        require(time() > (lastWithdrawTime + 24 hours));

        uint amount = _amount;
        if ( amount > withdrawLimit) {
            amount = withdrawLimit;
        }

        key.transfer(hotWallet, amount);
        lastWithdrawTime = time();
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



}
