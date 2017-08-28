// Copyright (C) 2017 DappHub, LLC

pragma solidity ^0.4.11;

import "ds-test/test.sol";
import "ds-exec/exec.sol";
import "ds-token/token.sol";

import "./TGCSale.sol";

contract TGCSaleUser is DSExec {

    TGCSale sale;
    DSToken tgc;

    function TGCSaleUser(TGCSale sale_) {
        sale = sale_;
        tgc = sale.tgc();
    }

    function() payable {}

    function doBuy(uint wad) {
        exec(sale, wad);
    }

    function doTransfer(address to, uint256 amount) returns (bool){
        return tgc.transfer(to, amount);
    }
}

contract TGCOwner {

    DSToken tgc;

    function TGCOwner() {}

    function setTGC(DSToken tgc_) {
        tgc = tgc_;
    }

    function doStop() {
        tgc.stop();
    }



    function() payable {}
}

contract TestableTGCSale is TGCSale {

    function TestableTGCSale(uint startTime, address destFoundation)
    TGCSale(startTime, destFoundation) {
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

contract TGCSaleTest is DSTest, DSExec {
    TestableTGCSale sale;
    DSToken tgc;
    TGCOwner tgcFoundation;

    TGCSaleUser user1;
    TGCSaleUser user2;


    function setUp() {
        tgcFoundation = new TGCOwner();
        sale = new TestableTGCSale(now, tgcFoundation);
        tgc = sale.tgc();

        tgcFoundation.setTGC(tgc);

        user1 = new TGCSaleUser(sale);
        exec(user1, 600 ether);

        user2 = new TGCSaleUser(sale);
        exec(user2, 600 ether);

    }



    function testTGCSaleToken() {
        assertEq(tgc.balanceOf(sale), (10 ** 11)*(10 ** 18) * 20 / 100 );
    }

    function testFoundationToken() {
        assertEq(tgc.balanceOf(tgcFoundation), (10 ** 11)*(10 ** 18) * 80 / 100 );
    }


    function testPublicBuy() {
        sale.addTime(1 days);

        user1.doBuy(19 ether);
        assertEq(tgc.balanceOf(user1), 200000 * 19 ether);
        assertEq(tgcFoundation.balance, 19 ether);

        exec(sale, 11 ether);
        assertEq(tgc.balanceOf(this), 200000 * 11 ether);
        assertEq(tgcFoundation.balance, 30 ether);
    }

    function testClaimTokens() {
        //sale.claimTokens(address(0x0));
    }


    function testBuyManyTimes() {
        exec(sale, 100 ether);
        assertEq(tgc.balanceOf(this), 200000 * 100 ether);

        exec(sale, 200 ether);
        assertEq(tgc.balanceOf(this), 200000 * 300 ether);

        exec(sale, 200 ether);
        assertEq(tgc.balanceOf(this), 200000 * 500 ether);
    }


    function testPostponeStartTime(){

        assertEq(sale.startTime(), now );
        assertEq(sale.endTime(), now + 14 days);

        sale.setStartTime(now + 2 days);

        assertEq(sale.startTime(), now + 2 days);
        assertEq(sale.endTime(), now + 16 days);
    }

    function testFinalize() {

        // sell 70000 ether, remains 30000 ether
        exec(sale, 70000 ether);

        sale.addTime(14 days);


        assertEq(tgc.balanceOf(sale), 30000 * 200000 * (10**18) );
        assertEq(tgc.balanceOf(tgcFoundation), ( (10 ** 11) * 80 / 100 ) * (10**18) );

        sale.finalize();

        assertEq(tgc.balanceOf(sale), 0 );
        assertEq(tgc.balanceOf(tgcFoundation), ( (10 ** 11) * 80 / 100 + 30000 * 200000) * (10**18) );

        assertEq(tgcFoundation.balance, 70000 ether);

    }

    function testTokenOwnershipBeforeFinalize() {

        sale.freezeToken();
    }

    function testTokenOwnershipAfterFinalize() {

        sale.addTime(14 days);

        sale.finalize();
        tgcFoundation.doStop();
    }

    function testTransferAfterFinalize() {
        user1.doBuy(1 ether);
        assertEq(tgc.balanceOf(user1), 200000 * 1 ether);

        sale.addTime(14 days);
        sale.finalize();

        assert(user1.doTransfer(user2, 200000 * 1 ether));

        assertEq(tgc.balanceOf(user1), 0);
        assertEq(tgc.balanceOf(user2), 200000 * 1 ether);

    }

    function testFailTransferBeforeFinalize() {
        user1.doBuy(1 ether);
        assert(user1.doTransfer(user2, 200000 * 1 ether));
    }

    function testFailAfterPause() {
        sale.pauseContribution();
        exec(sale, 100 ether);
    }

    function testEndTimeAfterSoftLimit(){

        // normal sell is 14 days
        assertEq(sale.endTime(), now + 14 days);

        // hit soft limit
        exec(sale, 50000 ether);
        assertEq(tgc.balanceOf(this), 200000 * 50000 ether);

        // 24 hours left for sell
        assertEq(sale.endTime(), now + 24 hours);
    }

    function testFailSoftLimit() {

        exec(sale, 50000 ether);

        sale.addTime(24 hours);

        // sell is finished
        exec(sale, 1 ether);
    }

    function testFailHardLimit() {

        // hit hard limit
        exec(sale, 100000 ether);

        // sell is finished
        exec(sale, 1 ether);
    }

    // tries to buy more than 500 eth
    function testFailUserBuyTooMuch() {
        user1.doBuy(501 ether);
    }


    function testFailStartTooEarly() {
        sale = new TestableTGCSale(now + 1 days, tgcFoundation);
        exec(sale, 10 ether);
    }

    function testFailBuyAfterClose() {
        sale.addTime(14 days);
        exec(sale, 10 ether);
    }

}
