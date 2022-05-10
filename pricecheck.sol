// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import 'https://github.com/smartcontractkit/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract priceCheck {
    uint256 public startDate;
    uint256 endDate;
    uint256 public betPrice = 12;
    uint256 public totalPriceFund;
    mapping(address => uint) public amountStakedLower;
    mapping(address => uint) public amountStakedHigherOrEqual;
    AggregatorV3Interface private immutable priceFeed =  AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    bool public winnerSet = false;
    //IERC20 private immutable token;

    enum Winner { LowerThan, HigherOrEqualThan }
    Winner public whoWon;

    event WinnerDrawn(Winner winner, uint256 priceAtSetTime);

    constructor(){ //uint256 _endDate, address _tokenAddress, address _priceFeed,  uint256 _betPrice
        //require(_priceFeed != address(0), 'Price feed address cannot be 0');
        //priceFeed = AggregatorV3Interface(_priceFeed);
        //endDate = _endDate;
        //betPrice = _betPrice;
        //token = IERC20(_tokenAddress);
        startDate = block.timestamp;
    }

    modifier poolEnded(){
        require(block.timestamp >= startDate + 30 minutes, "Pool is still active");
        _;
    }

    modifier poolActive(){
        require(block.timestamp < startDate + 30 minutes, "Pool has ended");
        _;
    }

    function stakeLowerThan() external payable poolActive{
        //require(msg.value > 0, "Value must be bigger than 0");
        //require(block.timestamp < endDate)
        amountStakedLower[msg.sender] += msg.value;
        totalPriceFund += msg.value;
    }

    function stakeHigherOrEqual() external payable poolActive{
        //require(msg.value > 0, "Value must be bigger than 0");
        //require(block.timestamp < endDate)
        amountStakedHigherOrEqual[msg.sender] += msg.value;
        totalPriceFund += msg.value;
    }

    function checkWinner() external payable poolEnded {
        require(!winnerSet, "Winner is already set");
        uint256 priceAtSetTime = uint256(getLatestPrice()); //check specific timestamp
        if(priceAtSetTime < betPrice){
            whoWon = Winner.LowerThan;
        }else{
            whoWon = Winner.HigherOrEqualThan;
        }
        winnerSet = true;
        emit WinnerDrawn(whoWon, priceAtSetTime);
    }

    function claim() external payable poolEnded{
        require(winnerSet, "Winner is not set yet");
        if(whoWon == Winner.LowerThan){
            require(amountStakedLower[msg.sender] > 0, "No funds to claim");
            uint wonPercentage = amountStakedLower[msg.sender] / totalPriceFund;
            uint amountWon = wonPercentage * totalPriceFund;
            amountStakedLower[msg.sender] = 0;
            payable(msg.sender).transfer(amountWon);
        }else{
            require(amountStakedHigherOrEqual[msg.sender] > 0, "No funds to claim");
            uint wonPercentage = amountStakedHigherOrEqual[msg.sender] / totalPriceFund;
            uint amountWon = wonPercentage * totalPriceFund;
            amountStakedHigherOrEqual[msg.sender] = 0;
            payable(msg.sender).transfer(amountWon);
        }
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}