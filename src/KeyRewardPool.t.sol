pragma solidity ^0.4.0;

import "ds-test/test.sol";
import "ds-math/math.sol";

import "./KeyRewardPool.sol";
import "./KeyTokenReborn.sol";



contract KeyRewardPoolOwner {

    TestableKeyRewardPool pool;

    function KeyRewardPoolOwner(TestableKeyRewardPool _pool) {
        pool = _pool;
    }

    function collectToken() {
        pool.collectToken();
    }

    function transferTokens(address dst, uint wad, address _token) {
        pool.transferTokens(dst, wad, _token );
    }
}



contract TestableKeyRewardPool is KeyRewardPool {

    function TestableKeyRewardPool(uint256 _rewardStartTime, address _key)
    KeyRewardPool(_rewardStartTime, _key) {
        localTime = now;
    }

    uint public localTime;

    function time() constant returns (uint) {
        return localTime;
    }

    function addTime(uint extra) {
        localTime += extra;
    }

}


contract KeyRewardPoolTest is DSTest, DSMath{

    TestableKeyRewardPool rewardPool;
    KeyTokenReborn keyReborn;
    DSToken key;

    KeyRewardPoolOwner poolOwner;

    function setUp() {

        keyReborn = new KeyTokenReborn(this);
        key = keyReborn.key();

        rewardPool = new TestableKeyRewardPool(now, key);

        key.transfer(rewardPool, 100 ether);

        poolOwner = new KeyRewardPoolOwner(rewardPool);

        rewardPool.setOwner(poolOwner);

    }

    function testKeyOwner() {

        assertEq(address(key.owner()), address(this));
    }
//
    function testPoolTotalBalance() {
        assertEq(key.balanceOf(rewardPool), 100 ether);
        assertEq(key.balanceOf(poolOwner), 0 ether);
    }

    function testPoolOwner() {

        assertEq(address(rewardPool.owner()), poolOwner);
    }



    function testCollectTokenOneDay() {

        rewardPool.addTime(1 days);
        poolOwner.collectToken();
        assertEq(key.balanceOf(poolOwner), div(10 ether, 365));
    }

    function testCollectToken300Day() {

        rewardPool.addTime(300 days);
        poolOwner.collectToken();
        assertEq(key.balanceOf(poolOwner), div(300 * 10 ether , 365));
    }

    function testCollectToken400Day() {

        rewardPool.addTime(1 years);
        poolOwner.collectToken();

        rewardPool.addTime(35 days);
        poolOwner.collectToken();

        uint256 reward = 10 ether;
        reward = reward + div( 35 * 90 * 10 ether, 365 * 100) ;

        assertEq(key.balanceOf(poolOwner), reward);
    }

    function testCollectTokenOneYear() {

        rewardPool.addTime(365 days);
        poolOwner.collectToken();
        assertEq(key.balanceOf(poolOwner), 10 ether);
    }

    function testCollectToken2Year() {

        rewardPool.addTime(1 years);
        poolOwner.collectToken();

        rewardPool.addTime(1 years);
        poolOwner.collectToken();

        assertEq(key.balanceOf(poolOwner), 10 ether + (10 * 90 ether)/100);
    }

    function testFailTransferTokens() {

        poolOwner.transferTokens(this, 1 ether, key);


    }



}
