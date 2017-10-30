pragma solidity ^0.4.0;


import "ds-test/test.sol";

import "ds-token/token.sol";

import "./WarmWallet.sol";
import "./KeyTokenReborn.sol";


contract Wallet {}

contract Withdrawer {
    WarmWallet warmWallet;
    DSToken key;

    function Withdrawer(address _warmWallet, address _key) {
        warmWallet = WarmWallet(_warmWallet);
        key = DSToken(_key);
    }

    function forwardToHotWallet(uint _amount) {
        warmWallet.forwardToHotWallet(_amount);
    }

    function restoreToColdWallet(uint _amount) {
        warmWallet.restoreToColdWallet(_amount);
    }

}

contract WarmWalletTest is DSTest {

    DSToken key;
    WarmWallet warmWallet;
    KeyTokenReborn keyReborn;

    address hotWallet = new Wallet();
    address coldWallet = new Wallet();
    Withdrawer withdrawer;

    function setUp() {

        keyReborn = new KeyTokenReborn(this);

        key = keyReborn.key();

        warmWallet = new WarmWallet(key, hotWallet, coldWallet, 0x0, 200 ether);

        key.transfer(warmWallet, 1000 ether);

        withdrawer = new Withdrawer(warmWallet, key);
        warmWallet.setWithdrawer(withdrawer);

    }

    function testTokenBalance() {
        assertEq(key.balanceOf(warmWallet), 1000 ether);
    }

    function testForwardToHotWallet() {
        withdrawer.forwardToHotWallet(100 ether);

        assertEq(key.balanceOf(hotWallet), 100 ether);
        assertEq(key.balanceOf(warmWallet), 900 ether);
    }

    function testRestoreToColdWallet() {
        withdrawer.restoreToColdWallet(800 ether);

        assertEq(key.balanceOf(coldWallet), 800 ether);
        assertEq(key.balanceOf(warmWallet), 200 ether);
    }


    function testForwardToHotWalletExceedLimit() {
        withdrawer.forwardToHotWallet(500 ether);

        assertEq(key.balanceOf(hotWallet), 200 ether);
        assertEq(key.balanceOf(warmWallet), 800 ether);
    }

    function testFailForwardToHotIn24Hours(){
        withdrawer.forwardToHotWallet(100 ether);
        withdrawer.forwardToHotWallet(100 ether);
    }
}

