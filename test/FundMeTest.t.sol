//SPDX-Licesne-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {FundMe, FundMe_NotOwner} from "../src/FundMe.sol";

import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
      
    FundMe public fundMe;
    
    address public immutable USER = makeAddr("user");

    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {

     //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
     DeployFundMe deployeFundMe = new DeployFundMe();
        fundMe = deployeFundMe.run();
       vm.deal(USER, STARTING_BALANCE);

    }

    function testMinimumDollarIsFIve() public view{

        assertEq(fundMe.MINIMUM_USD(), 5e18);


    }

  

    function testOwnerIsMsgSender() public view {

        console.log(msg.sender);

        assertEq(fundMe.I_OWNER(),msg.sender);
    }
    
    function testWihtdrawalFailsForNonOwner() public {

        address attacker = address(1);
        vm.deal(attacker    , 10 ether);

        vm.prank(attacker);

        fundMe.fund{value: 10 ether}();

        vm.prank(attacker);  

        vm.expectRevert(FundMe_NotOwner.selector);
        fundMe.withdraw();

    }
        function testPriceFeedVersionIsAccurate() public view {


            uint256 version = fundMe.getVersion();

            assertEq(version, 4);

        }

        function testFundFailsIfNotEnoughEth() public {

            vm.expectRevert();
            fundMe.fund();

        }

        function testFundUpdatesFundedDataStructure() public {
            vm.prank(USER);
            fundMe.fund{value: 1e18}();
            uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
            assertEq(amountFunded, 1e18);
            
        }

        function testAddFunderToArrayOfFunders() public {
            vm.prank(USER);
            fundMe.fund{value: 1e18}();
            address funder = fundMe.getFunder(0);
            assertEq(funder, USER);
        }

        modifier funded() {
            vm.prank(USER);
            fundMe.fund{value: 1e18}();
            _;
        }

        function testOnlyOwnerCanWithdraw() public funded {

         vm.expectRevert();
            vm.prank(USER);
            fundMe.withdraw();
        }       

         function testWithdrawFromASingleFunder() public funded  {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }


        function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2 + USER_NUMBER;

        uint256 originalFundMeBalance = address(fundMe).balance; // This is for people running forked tests!

        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundedeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundedeBalance + startingOwnerBalance == fundMe.getOwner().balance);

        uint256 expectedTotalValueWithdrawn = ((numberOfFunders) * SEND_VALUE) + originalFundMeBalance;
        uint256 totalValueWithdrawn = fundMe.getOwner().balance - startingOwnerBalance;

        assert(expectedTotalValueWithdrawn == totalValueWithdrawn);
    }
}

