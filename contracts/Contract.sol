// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
// versus timeLock rake
contract HigariowBlackJackV1 {
    address public owner;
    uint seedLocker;
    uint minimumBetCost;
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    mapping(address => uint256) public balances;
    uint256 public locked;

    struct BlackJack { 
        uint256 id;
        bool ended; 
        address[] winners;
        address dealer; 
        address[] players; 
        uint256[] bets; 
        uint256[] rest; 
        uint256[] total;
        uint256 totalCompensation; 
        bool dealerBusted; 
        bool[] funded; 
        bool[] terminated; 
        bool versus; 
        uint256[][] cards; 
    }

    mapping (address=>bool) public signUpAlready;
    mapping (uint256=>BlackJack) public blackJackGames;
    uint256 public blackJackQuantity;

    constructor() {
        owner = msg.sender;
        seedLocker = 0; 
        minimumBetCost = 10000000000000000;
    }

    function blackJackSetup( // 2
        address[] memory _addressPlayers,
        // uint256 _maxbetper, // ui
        uint256[] memory _bets) public returns (uint256) {
        require(_addressPlayers.length<=7&&_addressPlayers.length>0,"");
        require(signUpAlready[msg.sender]==true,"");
        for (uint j=0;j<_addressPlayers.length;j++) {
            require(signUpAlready[_addressPlayers[j]]==true&&msg.sender!=_addressPlayers[j],
            "");
        }
        uint256 requiredFund = 0;
        BlackJack storage blackJack = blackJackGames[blackJackQuantity];
        blackJack.id=blackJackQuantity;
        blackJack.dealer=msg.sender;
        blackJack.versus=false;
        blackJack.dealerBusted=false;
        blackJack.ended=false;
        bool[] memory termination= new bool[](_addressPlayers.length);
        while (termination.length==_addressPlayers.length) {
            termination[termination.length]=false;
        }
        blackJack.terminated=termination;
        for (uint p=0;p<_addressPlayers.length;p++){
            blackJack.players.push(_addressPlayers[p]);
            require(_bets[p]>=minimumBetCost,"");
            blackJack.bets.push(_bets[p]);
            blackJack.total.push(0);
            requiredFund+=_bets[p]*150/100;
            blackJack.funded.push(false);
        }
        blackJack.total.push(0);
        blackJack.funded.push(false);
        blackJack.totalCompensation=requiredFund;
        require(requiredFund<msg.sender.balance,"");
        blackJackQuantity++;
        return blackJackQuantity-1;
    }

    function fundBet(uint256 _id) public payable { // 3
        BlackJack storage blackJack = blackJackGames[_id];
        require(blackJack.ended==false,"");
        bool d = checkAddress(blackJack.players);
        require(d==true||msg.sender==blackJack.dealer,"");
        uint index;
        if (msg.sender==blackJack.dealer) {
            index = blackJack.players.length;
            require(msg.value==blackJack.totalCompensation,
            "");
        }
        else {
            index = checkAddressIndex(blackJack.players);
            require(msg.value==blackJack.bets[index],
            "");
        }
        require(blackJack.funded[index]==false,"");
        uint256 val = msg.value;
        balances[msg.sender]+=val;
        locked+=msg.value;
        blackJack.funded[index]=true;
        emit Staked(msg.sender, val);
    }

    function blackJackInitialDealt( // 4
        uint256 _blackJackId
    ) public {
        BlackJack storage blackJack = blackJackGames[_blackJackId];
        require(blackJack.ended==false&&blackJack.cards.length==0&&msg.sender==blackJack.dealer,"");
        for (uint w=0;w<blackJack.players.length+1;w++){
            require(blackJack.funded[w]==true,"");
        }
        address[] memory addresses = blackJack.players;
        uint256[] memory deck = new uint256[](52);
        for (uint k=0;k<52;k++) {
            deck[k]=k+1;
        }
        uint256[][] memory hands;
        uint256[] memory past;
        while (past.length!=(addresses.length+1)*2) {
            uint256 g = ranger(52)+1;
            bool h = checkUint(past,g);
            if (h==false) {
                past[past.length]=g;
            }
        }
        uint256[] memory restArr;
        for (uint e=0;e<52;e++) {
            bool t = false;
            for (uint h=0;h<past.length;h++) {
                if (e+1==past[h]) {
                    t=true;
                    break;
                }
            }
            if (t==false) {
                restArr[restArr.length]=e+1;
            }
        }
        blackJack.rest=restArr;
        for (uint t = 0;t<addresses.length+1;t++) {
            uint f = 0;
            uint e = 1;
            while (hands[t].length!=2) {
                uint256[] memory arr = new uint256[](7); // max 7 card
                arr[0]=past[f];
                arr[1]=past[e];
                hands[t]=arr;
            }
            f+=2;
            e+=2;
        }
        blackJack.cards=hands;
    }

    function terminateBlackJackBeforeBusted(uint256 _id) public { // 5a
        BlackJack storage blackJack = blackJackGames[_id];
        require(blackJack.ended==false&&blackJack.versus==false&&blackJack.cards.length==blackJack.players.length+1,"");
        bool d = checkAddress(blackJack.players);
        uint index = checkAddressIndex(blackJack.players);
        (bool vusted,uint256 tt) = checkBlackJackIfTerminated(_id);
        require(vusted==false&&d==true&&blackJack.terminated[index]==false,"");
        blackJack.total[index]=tt;
        blackJack.terminated[index]=true;
        bool oh=true;
        for (uint u=0;u<blackJack.terminated.length;u++) {
            if (blackJack.terminated[u]!=true) { 
                oh=false;
                break;
            }
        }
        if (oh==true) {
            blackJack.versus=true;
        }
    }

    function moreBlackJackCard(uint256 _id) public { // 5b
        BlackJack storage blackJack = blackJackGames[_id];
        require(blackJack.ended==false&&blackJack.cards.length!=0&&blackJack.versus==false,"");
        bool d = checkAddress(blackJack.players);
        uint index = checkAddressIndex(blackJack.players);
        uint rindex = ranger(blackJack.rest.length);
        require(blackJack.cards[index].length<7&&blackJack.cards[index].length>1 &&blackJack.terminated[index]==false&&d==true,"");
        blackJack.cards[index][blackJack.cards[index].length]=blackJack.rest[rindex];
        (bool busted,uint256 tt) = checkBlackJackIfTerminated(_id);
        blackJack.total[index]=tt;
        if (busted==true){
            blackJack.terminated[index]=true;
            bool oh=true;
            for (uint u=0;u<blackJack.terminated.length;u++) {
                if (blackJack.terminated[u]!=true) {
                    oh=false;
                    break;
                }
            }
            if (oh==true) {
                blackJack.versus=true;
            }
        }
        uint256[] memory restArr;
        for (uint c=0;c<blackJack.rest.length;c++) {
            if (blackJack.rest[c]!=blackJack.rest[rindex]) {
                restArr[restArr.length]=blackJack.rest[c];
            }
        }
        blackJack.rest=restArr;
    }

    function dealerBlackJackRest(uint256 _id) public { // 6
        BlackJack storage blackJack = blackJackGames[_id];
        require(msg.sender==blackJack.dealer&&blackJack.ended==false&&blackJack.cards.length!=0&&blackJack.versus==true,"");
        uint256 forNow;
        for (uint d=0;d<2;d++) { 
            forNow+=blackJack.cards[blackJack.cards.length-1][d];
        }
        while (forNow < 17) {
            uint rindex = ranger(blackJack.rest.length);
            blackJack.cards[blackJack.cards.length-1][
                blackJack.cards[blackJack.cards.length-1].length
                ]=blackJack.rest[rindex];
            uint256[] memory restArr;
            for (uint c=0;c<blackJack.rest.length;c++) {
                if (blackJack.rest[c]!=blackJack.rest[rindex]) {
                    restArr[restArr.length]=blackJack.rest[c];
                }
            }
            blackJack.rest=restArr;
            forNow+=blackJack.rest[rindex];
        }
        (bool f,uint256 tt)=checkBlackJackIfTerminated(_id);
        blackJack.total[blackJack.total.length-1]=tt;
        if (f==true){
            blackJack.dealerBusted=true;
        }
    }

    function findBlackJackWinners(uint256 _id) public { // 7
        BlackJack storage blackJack=blackJackGames[_id];
        require(msg.sender==blackJack.dealer,"");
        require(blackJack.ended==false&&blackJack.cards.length!=0&&blackJack.versus==true,"");
        bool dealwin=false;
        uint256 dealerVal=blackJack.total[blackJack.total.length-1];
        uint256 td = blackJack.totalCompensation;
        if (blackJack.dealerBusted==true) { // owner
            for (uint r=0;r<blackJack.total.length-1;r++) {
                if (blackJack.total[r]<=21) {
                    blackJack.winners.push(blackJack.players[r]); 
                    balances[blackJack.players[r]]-=blackJack.bets[r];
                    td-=blackJack.bets[r]*50/100;
                    locked-=blackJack.bets[r]*150/100; 
                    payable(blackJack.players[r]).transfer(blackJack.bets[r]*150/100*92/100);
                    emit Withdrawn(blackJack.players[r], blackJack.bets[r]*150/100*92/100);
                    payable(owner).transfer(blackJack.bets[r]*150/100*8/100);
                    emit Withdrawn(owner, blackJack.bets[r]*150/100*8/100);
                } else {
                    balances[blackJack.players[r]]-=blackJack.bets[r];
                    locked-=blackJack.bets[r];
                    payable(owner).transfer(blackJack.bets[r]);
                    emit Withdrawn(owner, blackJack.bets[r]);
                }
            }
            balances[blackJack.dealer]-=blackJack.bets[blackJack.players.length];
            locked-=td;
            payable(owner).transfer(td);
            emit Withdrawn(owner, td);
        } else { // dealer
            for (uint r=0;r<blackJack.total.length-1;r++) {
                if (blackJack.total[r]>dealerVal||blackJack.total[r]==21) {
                    blackJack.winners.push(blackJack.players[r]);
                    balances[blackJack.players[r]]-=blackJack.bets[r];
                    td-=blackJack.bets[r]*50/100;
                    locked-=blackJack.bets[r]*150/100;
                    payable(blackJack.players[r]).transfer(blackJack.bets[r]*150/100*92/100);
                    emit Withdrawn(blackJack.players[r], blackJack.bets[r]*150/100*92/100);
                    payable(owner).transfer(blackJack.bets[r]*150/100*8/100);
                    emit Withdrawn(owner, blackJack.bets[r]*150/100*8/100);
                } else {
                    if (dealwin!=true) { 
                        dealwin=true;
                    }
                    balances[blackJack.players[r]]-=blackJack.bets[r];
                    locked-=blackJack.bets[r];
                    payable(blackJack.dealer).transfer(blackJack.bets[r]*92/100);
                    emit Withdrawn(blackJack.dealer, blackJack.bets[r]*92/100);
                    payable(owner).transfer(blackJack.bets[r]*8/100);
                    emit Withdrawn(owner, blackJack.bets[r]*8/100);
                }
            }
            balances[blackJack.dealer]-=blackJack.bets[blackJack.players.length];
            locked-=td;
            payable(blackJack.dealer).transfer(td);
            emit Withdrawn(blackJack.dealer, td);
        }
        if (dealwin==true){
            blackJack.winners.push(blackJack.dealer);
        }
        blackJack.ended=true;
    }

    function checkBlackJackAllShownHands(uint256 _blackJackId) 
    public view returns (uint256[][]memory) {
        BlackJack memory blackJack = blackJackGames[_blackJackId];// anyone even outside the game can check
        uint256[][] memory result;
        for (uint g=0;g<blackJack.players.length+1;g++) {
            if (g==blackJack.players.length) {
                uint256[] memory last;
                if (blackJack.versus==false) {
                    last[0]=blackJack.cards[g][0];
                } else {
                    last=blackJack.cards[g];
                }
                result[g]=last;
            } else {
                result[g]=blackJack.cards[g];
            }
        }
        return result;
    }

    function checkUint(uint[] memory _uints,uint _val) 
    public pure returns (bool) {
        bool tf = false;
        if (_uints.length>0) {
            for (uint g =0;g<_uints.length;g++){
                if (_val==_uints[g]) {
                    tf=true;
                    break;
                }
            }
        }
        return tf;
    }

    function ranger(uint _v) public returns (uint) {
        seedLocker++;
        return uint(keccak256(abi.encodePacked(
            block.timestamp,msg.sender,seedLocker))) % _v;
    }

    function registerFirst() public { // 1
        require(msg.sender!=owner,"");
        signUpAlready[msg.sender]=true;
    }

    function checkAddress(address[] memory _adds) public view returns (bool) {
        bool f=false;
        for (uint g = 0;g< _adds.length;g++) {
            if (msg.sender==_adds[g]) {
                f = true;
                break;
            }
        }
        return f;
    }

    function checkAddressIndex(address[] memory _adds) 
    public view returns (uint) {
       uint f=0;
        for (uint g = 0;g< _adds.length;g++) {
            if (msg.sender==_adds[g]) {
                f = g;
                break;
            }
        }
        return f;
    }

    function checkBlackJackIfTerminated(uint256 _id) public view returns (bool,uint256) {
        BlackJack memory blackJack = blackJackGames[_id];
        bool d = checkAddress(blackJack.players);
        require(blackJack.ended==false&&blackJack.cards.length!=0,"");
        bool before = false;
        uint index;
        if (d==true) {
            index = checkAddressIndex(blackJack.players);
            require(blackJack.terminated[index]==false,"");
        } else if (msg.sender==blackJack.dealer) {
            index = blackJack.players.length;
        }
        uint256[] memory setset = blackJack.cards[index];
        uint256 total;
        for (uint j=0;j<setset.length;j++) {
            if (setset[j]==1||setset[j]==14||setset[j]==27||setset[j]==40) {

            } else {
                if (
                    setset[j]==10||
                    setset[j]==11||
                    setset[j]==12||
                    setset[j]==13||
                    setset[j]==23||
                    setset[j]==24||
                    setset[j]==25||
                    setset[j]==26||
                    setset[j]==36||
                    setset[j]==37||
                    setset[j]==38||
                    setset[j]==39||
                    setset[j]==49||
                    setset[j]==50||
                    setset[j]==51||
                    setset[j]==52
                ) {
                    total=total+10;
                } else if (
                    setset[j]==2||
                    setset[j]==15||
                    setset[j]==28||
                    setset[j]==41
                ) {
                    total=total+2;
                } else if (
                    setset[j]==3||
                    setset[j]==16||
                    setset[j]==29||
                    setset[j]==42
                ) {
                    total=total+3;
                } else if (
                    setset[j]==4||
                    setset[j]==17||
                    setset[j]==30||
                    setset[j]==43
                ) {
                    total=total+4;
                } else if (
                    setset[j]==5||
                    setset[j]==18||
                    setset[j]==31||
                    setset[j]==44
                ) {
                    total=total+5;
                } else if (
                    setset[j]==6||
                    setset[j]==19||
                    setset[j]==32||
                    setset[j]==45
                ) {
                    total=total+6;
                } else if (
                    setset[j]==7||
                    setset[j]==20||
                    setset[j]==33||
                    setset[j]==46
                ) {
                    total=total+7;
                } else if (
                    setset[j]==8||
                    setset[j]==21||
                    setset[j]==34||
                    setset[j]==47
                ) {
                    total=total+8;
                } else if (
                    setset[j]==9||
                    setset[j]==22||
                    setset[j]==35||
                    setset[j]==48
                ) {
                    total=total+9;
                }
            }
        }
        if (total > 21) {
            before = true;
        } else {
            for (uint k=0;k<setset.length;k++) {
                if (setset[k]==1||setset[k]==14||
                setset[k]==27||setset[k]==40) {
                    if (total+11>21) {
                        total+=1;
                    } else {
                        total+=11;
                    }
                }
            }
        }
        if (total>21&&before==false){
            before=true;
        }
        return (before,total);
    }
}
