// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {priceConvertor} from "./PriceConvertor.sol";

error FundMe_NotOwner();

contract FundMe {

    using priceConvertor for uint256;

    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    address public immutable I_OWNER;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {

        I_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    
    //function to send funds
    function fund() public payable {
        //allow users to send money

        require(msg.value.getConversion(s_priceFeed) >= MINIMUM_USD, "not enough eth");

        s_addressToAmountFunded[msg.sender] += msg.value;

       s_funders.push(msg.sender);
        //minumum 5 dollars
    }

    modifier onlyOwner {

         _checkOwner();
         _;
    }

    function _checkOwner() internal view {
        if (msg.sender != I_OWNER) revert FundMe_NotOwner();
    }

   

    //withdraw function to withdraw

    function withdraw() public onlyOwner payable {

        for(uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){

            address funder = s_funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;


        }
           s_funders = new address[](0);

            (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
            require(callSuccess, "Call Failed");


    }

    fallback() external payable {

        fund();
     }

     receive() external payable {

        fund();
      }


      
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return I_OWNER;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}