// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol"; // for our anvil chain priceFeed

contract HelperConfig is Script {

  NetworkConfig public activeNetworkConfig;

  uint8 public constant DECIMALS = 8;
  int256 public constant INITIAL_PRICE = 2000e8;

  struct NetworkConfig {
    address priceFeed;
  }

  constructor () {
    if (block.chainid == 11155111) {
      activeNetworkConfig = getSepoliaEthConfig();
    } else if (block.chainid == 1) {
      activeNetworkConfig = getMainnetEthConfig();
    } else {
      activeNetworkConfig = getOrCreateAnvilEthConfig();
    }
  }

  function getSepoliaEthConfig() public pure returns(NetworkConfig memory) { // any contract we deploy using this does not exist because its on local chain
    NetworkConfig memory sepoliaConfig = NetworkConfig({
      priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
    });

    return sepoliaConfig;
  }

  function getMainnetEthConfig() public pure returns(NetworkConfig memory) {
    NetworkConfig memory mainnetEthConfig = NetworkConfig({
      priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    });

    return mainnetEthConfig;
  }

  function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {

    // Check if we already deployed an anvil priceFeed
    if (activeNetworkConfig.priceFeed != address(0)) {
      return activeNetworkConfig;
    }
    // Deploy the mock chainlink contract on Anvil
    // Return the mock adress

    // this way, we will deploy th contracts to our local chain, ANVIL and be able to access and control it without having to make api calls to our alchemy node

    // Now we can run forge test without --fork-url
    vm.startBroadcast(); 
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    NetworkConfig memory anvilConfig = NetworkConfig({
      priceFeed: address(mockPriceFeed)
    });

    return anvilConfig;
  }
}