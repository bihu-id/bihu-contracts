// Copyright (C) 2017 DappHub, LLC

pragma solidity ^0.4.11;

import "ds-token/token.sol";
import "ds-exec/exec.sol";
import "ds-auth/auth.sol";
import "ds-note/note.sol";
import "ds-math/math.sol";

contract TGCSale is DSAuth, DSMath, DSNote, DSExec {

    DSToken public tgc;

    // TGC PRICES (ETH/TGC)
    uint public constant PUBLIC_SALE_PRICE = 200000;

    // test
    //uint128 public constant TOTAL_SUPPLY = (10 ** 6) * (10 ** 18);  // 100 billion TGC in total
    uint128 public constant TOTAL_SUPPLY = (10 ** 11) * (10 ** 18);  // 100 billion TGC in total


    uint128 public constant SELL_SOFT_LIMIT = TOTAL_SUPPLY * 10 / 100; // soft limit is 10%
    uint128 public constant SELL_HARD_LIMIT = TOTAL_SUPPLY * 20 / 100; // hard limit is 20%

    uint128 public constant FUTURE_DISTRIBUTE_LIMIT = TOTAL_SUPPLY * 80 / 100; // 80% for future distribution

    uint128 public constant USER_BUY_LIMIT = 500 ether; // 500 ether limit
    uint128 public constant MAX_GAS_PRICE = 50000000000;  // 50GWei


    uint public startTime;
    uint public endTime;

    bool public paused;
    bool public moreThanSoftLimit;


    mapping (address => uint)  public  userBuys; // limit to 500 eth

    address public destFoundation; //multisig account , 4-of-6

    uint sold;


    modifier notPaused() {
        require(!paused);
        _;
    }

    function TGCSale(uint startTime_, address destFoundation_) {

        tgc = new DSToken("TGC");

        destFoundation = destFoundation_;

        startTime = startTime_;
        endTime = startTime + 14 days;

        tgc.mint(TOTAL_SUPPLY);

        tgc.authTransfer(destFoundation, FUTURE_DISTRIBUTE_LIMIT);

        //disable transfer
        tgc.stop();

        paused = false;
        moreThanSoftLimit = false;
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
        size := extcodesize(_addr)
        }
        return size > 0;
    }

    function() payable notPaused note {

        require(!isContract(msg.sender));
        require(msg.value >= 0.01 ether);
        require(tx.gasprice <= MAX_GAS_PRICE);

        assert(time() >= startTime && time() < endTime);

        // owner is for test
        assert(msg.sender == owner || add(userBuys[msg.sender], msg.value) <= USER_BUY_LIMIT);

        assert(sold < SELL_HARD_LIMIT);

        uint rate = PUBLIC_SALE_PRICE;
        uint toFund = msg.value;

        uint requested = mul(toFund, rate);

        if( add(sold, requested) >= SELL_HARD_LIMIT) {
            requested = SELL_HARD_LIMIT - sold;
            toFund = div(requested, rate);

            endTime = time();
        }

        sold = add(sold, requested);

        if( !moreThanSoftLimit && sold >= SELL_SOFT_LIMIT ) {
            moreThanSoftLimit = true;
            endTime = time() + 24 hours; // last 24 hours after soft limit,
        }

        userBuys[msg.sender] = add(userBuys[msg.sender], toFund);

        tgc.authTransfer(msg.sender, requested);
        exec(destFoundation, toFund); // send the ETH to multisig

        uint toReturn = sub(msg.value, toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

    function pauseContribution() auth note{
        paused = true;
    }

    function resumeContribution() auth note{
        paused = false;
    }

    function setStartTime(uint startTime_) auth note{
        require(time() <= startTime && time() <= startTime_);

        startTime = startTime_;
        endTime = startTime + 14 days;
    }

    function finalize() auth note{
        require(time() >= endTime);

        uint256 unsold = sub(SELL_HARD_LIMIT, sold);

        if(unsold > 0){
            tgc.authTransfer(destFoundation, unsold);
        }

        // enable transfer
        tgc.start();

        // owner -> destFoundation
        tgc.setOwner(destFoundation);
    }

    // disable token transfer
    function freezeToken() auth note{
        tgc.stop();
    }


    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth note{

        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}
