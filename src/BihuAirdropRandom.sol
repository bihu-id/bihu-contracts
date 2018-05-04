pragma solidity ^0.4.17;

// https://kovan.etherscan.io/address/0xb2F943B7bC60A44C9ebA9771cB21a2E15F0c937A

contract BihuAirdropRandom {

    // random range
    uint256  public randomBase = 10 ** 11; // 100 billion

    // airdrop info
    uint public futureBlockNum;
    string public secretString;
    bytes32 public secretStringHash;
    bool public isSecretRevealed;

    // owner
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function BihuAirdropRandom() public{
        secretString = "";
        isSecretRevealed = false;

        owner = msg.sender;
    }

    // to init an airdrop activity, we need to specify two things
    // 1. a future block number, this block's hash will be one part of the seed.
    // 2. a secret string's hash, this secret will be revealed soon after block(_blockNum) is mined.
    function initAirdropRandom (uint _blockNum, bytes32 _secretHash) onlyOwner public{ // only owner
        require(_blockNum > block.number + 10 );
        require(_secretHash != 0);
        require(_blockNum != 0);

        futureBlockNum = _blockNum;
        secretStringHash = _secretHash;
        secretString = "";
        isSecretRevealed = false;
    }


    function revealSecret(string _secret) public returns (bool) {

        require(block.number > futureBlockNum);

        if (secretStringHash == keccak256(_secret)) {
            secretString = _secret;
            isSecretRevealed = true;
            return true;
        }

        return false;
    }


    // Generates a random number from 0 to 10^11 based on (1）a future block hash ,(2) user's id , (3) secret string
    function randomGen(uint id) constant public returns (uint randomNumber) {
        // require(isSecretRevealed);
        // require(block.number > futureBlockNum);

        if(!isSecretRevealed || (block.number <futureBlockNum))
            return 0;

        return(uint(keccak256(block.blockhash(futureBlockNum), id, secretString )) % randomBase);
    }


    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }


    // help function
    function calculateSecretHash(string _secret) pure public returns (bytes32 secretHash) {
        secretHash = keccak256(_secret);
    }

    // help function
    function getBlockNumber() public constant returns (uint256) {
        return block.number;
    }


}
