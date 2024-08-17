// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GameBase {
    address public contractOwner;
    mapping(uint256 => Player) public players;
    mapping(address => bool) public registered;
    mapping(uint256 => Duel) public duels;
    uint256 public playerAmount;
    uint256 public duelAmount;
    mapping(address => uint256) public individualBalances;

    struct Duel {
        uint256 gameIndex;
        address payable playerA;
        address payable playerB;
        address winner;
        address loser; 
        uint256 bet;
        string[] moves;
        uint256 timeLog;
    }

    struct Player {
        uint256 playerIndex;
        uint256 ranking;
        address tag;
        uint256 won;
        uint256 even;
        uint256 loss;
        uint256 prize;
        Duel[] pastDuel;
        string nickname;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    modifier miniBet(uint _mB) {
        string memory _msg = string.concat(
            "The minimum bet amount is ",
            Strings.toString(_mB)
        );
        require(msg.value >= _mB, _msg);
        _;
    }

    modifier exceptOwner() {
        require(msg.sender != contractOwner, "Anyone but owner");
        require(registered[msg.sender] == true, "need to be a player");
        _;
    }

    modifier exceptPlayers() {
        require(msg.sender == contractOwner, "Anyone but players");
        _;
    }

    function homePageMatch() private view exceptOwner returns (uint) {
        uint userIndex = 0;
        for (uint t = 0; t < playerAmount; t++) {
            if (players[t].tag == msg.sender) {
                userIndex = t;
                break;
            }
        }
        uint target = userIndex;
        while (target == userIndex) {
            uint current = uint(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        playerAmount
                    )
                )
            );
            if (current != userIndex) {
                target = current;
                break;
            }
        }
        return target;
    }

    function createNewProfile(
        string memory _nickname
    ) public exceptOwner returns (uint256) {
        require(registered[msg.sender] == false, "have not registered yet");
        Player storage newPlayer = players[playerAmount];
        newPlayer.tag = msg.sender;
        newPlayer.playerIndex=playerAmount;
        newPlayer.won = 0;
        newPlayer.loss = 0;
        newPlayer.even = 0;
        newPlayer.prize = 0;
        newPlayer.nickname = _nickname;
        newPlayer.ranking = 0;
        playerAmount += 1;
        registered[msg.sender] = true;
        return playerAmount - 1;
    }

    function createDuelRecord(
        string[] memory _moves,
        address _opponent
    ) public payable exceptOwner returns (uint256) {}

    function depositForDuel(uint256 _amount) public payable exceptOwner miniBet(0.02 ether){
        require(msg.value >= _amount, "sufficient input is required");
        individualBalances[msg.sender] += msg.value;
    }

    function withdrawFromDuel(
        address _account,
        uint256 _amount
    ) public exceptOwner {
        require(
            individualBalances[_account] >= _amount,
            "sufficient account balance is required"
        );
        individualBalances[_account] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    event DuelMatching(address player, uint256 individualBet);

    event DuelInvite(address playerA, address playerB, uint256 bet);

    event DuelMatchedNStarted(
        uint256 gameIndex,
        uint256 betTotal,
        address playerA,
        address playerB
    ); // if accepted by opponent

    event DuelMoving(
        uint256 gameIndex,
        address movingSide,
        address againstSide,
        string moveTag
    );

    event DuelEnding(
        uint256 gameIndex,
        address winner,
        address loser,
        string[] allMoves
    );
}
