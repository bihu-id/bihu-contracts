pragma solidity ^0.4.0;

import "ds-token/token.sol";

contract KeyTokenOwner is DSAuth{

    DSToken public key;

    function KeyTokenOwner(address _key)
    {
        key = DSToken(_key);
    }

    function stopKeyToken() auth
    {
        key.stop();
    }

    function startKeyToken() auth
    {
        key.start();
    }

}
