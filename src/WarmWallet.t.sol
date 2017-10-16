pragma solidity ^0.4.0;


import "ds-test/test.sol";

import "ds-token/token.sol";

import "./WarmWallet.sol";
import "./KeyTokenReborn.sol";


contract Wallet {

}

contract WarmWalletTest is DSTest {

    DSToken key;
    WarmWallet warmWallet;
    KeyTokenReborn keyReborn;

    address hotWallet = new Wallet();
    address coldWallet = new Wallet();


    function setUp() {

        keyReborn = new KeyTokenReborn(this);

        key = keyReborn.key();

        warmWallet = new WarmWallet(key, hotWallet, coldWallet);

        key.transfer(warmWallet, 1000 ether);

    }

    function testTokenBalance() {
        assertEq(key.balanceOf(warmWallet), 1000 ether);
    }

    function testFowardToHotWallet() {
        warmWallet.forwardToHotWallet(100 ether);

        assertEq(key.balanceOf(hotWallet), 100 ether);
        assertEq(key.balanceOf(warmWallet), 900 ether);
    }

    function testRestoreToColdWallet() {
        warmWallet.restoreToColdWallet(800 ether);

        assertEq(key.balanceOf(coldWallet), 800 ether);
        assertEq(key.balanceOf(warmWallet), 200 ether);
    }
}

