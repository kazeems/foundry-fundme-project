// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  // This is only for testing purpose. to create a PRANK user for our contract calls
  address USER = makeAddr("user"); // fondry cheatcode
  uint256 constant SEND_VALUE = 0.1 ether; // 1000000000000000000 wei
  uint256 constant STARTING_BALANCE = 10 ether;

  function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE); // foundry cheatcode
  }

  function testOnlyOwner() public view {
    assertEq(fundMe.i_owner(), msg.sender);
  }

  function testMinimumUsdIsFive() public view {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testPriceFeedVersionIsAccurate() public view{
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  }

  // Foundry cheatcodes: book.getfoundry.sh/cheatcodes
  function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert(); // this means the next line must fail
    // for this test to pass
    fundMe.fund(); // send 0 value: this will fail so test passes
  }

  function testFundUpdatesFundedDataStructure() public {
    // testing if mapping (address => uint256) addressToAmountFunded is being updated
    vm.prank(USER); // The next transaction will be sent by the USER
    fundMe.fund{value: SEND_VALUE}(); // Sent by USER

    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

    assertEq(amountFunded, SEND_VALUE);

  }

  function testAddsFunderToArrayOfFunders() public {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();

    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }

  modifier funded() {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function testOnlyOwnerCanWithdraw() public funded {
    // vm.prank(USER);
    // fundMe.fund{value: SEND_VALUE}();
    // above two lines not needed since we are using the funded modifier

    vm.prank(USER);
    vm.expectRevert();
    fundMe.withdraw();
  }

  function testWithdrawWithASingleFunder() public funded {
    //: Tests methodology
    // Arrange
    uint256 startingownerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();

    // Assert
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingownerBalance, endingOwnerBalance);
  }

  function testWithdrawFromMultipleFunders() public funded {
    // Arrange

    uint160 numberOfFunders = 10; // uint160 is used when using numbers to generate adresses
    // uint160 has same bytes as an address
    uint160 startingFunderIndex = 1;
    for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      // vm.prank new address
      // vm.deal new address
      hoax(address(i), SEND_VALUE);
      // fund the fundMe
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    assertEq(address(fundMe).balance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

  }

  function testWithdrawFromMultipleFundersCheaper() public funded {
    // Arrange

    uint160 numberOfFunders = 10; // uint160 is used when using numbers to generate adresses
    // uint160 has same bytes as an address
    uint160 startingFunderIndex = 1;
    for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
      // vm.prank new address
      // vm.deal new address
      hoax(address(i), SEND_VALUE);
      // fund the fundMe
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.startPrank(fundMe.getOwner());
    fundMe.cheaperWithdraw();
    vm.stopPrank();

    assertEq(address(fundMe).balance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

  }


}