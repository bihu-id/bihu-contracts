pragma solidity ^0.4.0;

import "ds-token/token.sol";
import "ds-auth/auth.sol";


contract WarmWallet is DSAuth{

    DSToken public key;
    address public hotWallet;
    address public coldWallet;

    function WarmWallet(DSToken _key, address _hot, address _cold){
        require(address(_key) != 0x0 );

        key = _key;
        hotWallet = _hot;
        coldWallet = _cold;
    }

    function forwardToHotWallet(uint _amount) auth {
        require(_amount > 0);
        key.transfer(hotWallet, _amount);
    }

    function restoreToColdWallet(uint _amount) auth {
        require(_amount > 0);
        key.transfer(coldWallet, _amount);
    }

}
