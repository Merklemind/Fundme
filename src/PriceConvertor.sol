
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

library priceConvertor {


    function getPrice(AggregatorV3Interface priceFeed) public view returns(uint256){


        (,int256 price,,,) = priceFeed.latestRoundData();

        return uint256(price * 10000000000);


    }


function getConversion(uint256 ethAmount, AggregatorV3Interface priceFeed) public  view returns(uint256){

    uint256 price = getPrice(priceFeed);

    uint256 ethAmountInUsd = (price * ethAmount) / 1e18;

    return ethAmountInUsd;
}

}