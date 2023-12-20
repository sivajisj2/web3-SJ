// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test,console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test{
  
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint64 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;

     address public PLAYER = makeAddr("player");
     uint256 public constant STARTING_USER_BALANCE = 10 ether;



    function setup() external {
      DeployRaffle deployer = new DeployRaffle();
       (raffle, helperConfig) = deployer.run();
       (
        entranceFee,
        interval,
        vrfCoordinator,
        subscriptionId,
        gasLane,
        callbackGasLimit,
       ) = helperConfig.activeNetworkConfig();

    }


      function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}