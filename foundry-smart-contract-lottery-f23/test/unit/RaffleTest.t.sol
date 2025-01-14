// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test{

  /* Events */

  event RaffleEnter(address indexed player);


  
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee = 0.02 ether;
    uint256 interval;
    address vrfCoordinator;
    uint64 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    address link;

     address public PLAYER = makeAddr("player");
     uint256 public constant STARTING_USER_BALANCE = 15 ether;



    function setUp() external {
      DeployRaffle deployer = new DeployRaffle();
       (raffle, helperConfig) = deployer.run();
        console.log("Raffle contract deployed at:", address(raffle));
   console.log("HelperConfig contract deployed at:", address(helperConfig));
           vm.deal(PLAYER, STARTING_USER_BALANCE);
       (
        ,
        interval,
        vrfCoordinator,
        subscriptionId,
        gasLane,
        callbackGasLimit,
        
          ) = helperConfig.activeNetworkConfig();

          console.log("Entrance Fee:", entranceFee);
          console.log("Interval:", interval);
          console.log("VRF Coordinator:", vrfCoordinator);
          console.log("Subscription ID:", subscriptionId);
        
          console.log("Callback Gas Limit:", callbackGasLimit);

    }


      function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenYouDontPayEnoughEth() public {
      //Arrange
      vm.prank(PLAYER);

      //Act  //assert
      vm.expectRevert(Raffle.Raffle_NotEnoughETHSent.selector);
      raffle.enterRaffle();
      


    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value : entranceFee}();
      address playerRecorded = raffle.getPlayer(0);
      assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public{
      // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

    }

     function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value : entranceFee}();

       // vm.roll(newHeight); //used for setting new block.number avlue
       // vm.warp(newTimestamp); //used for setting new block.timestamp avlue
       vm.warp(block.timestamp + interval  + 1);

       vm.roll(block.number + 1);

       raffle.performUpkeep("");
       

      vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
      vm.prank(PLAYER);
      raffle.enterRaffle{value : entranceFee} ();

    }

       function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpKeep("");

        // Assert
        assert(!upkeepNeeded);
    }

       function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpKeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

     function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();

    // Act
    (bool upkeepNeeded, ) = raffle.checkUpKeep("");

    // Assert
    assert(upkeepNeeded==false);

    // Warp time to a point just before the next interval
   vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act again
    (bool newUpkeepNeeded, ) = raffle.checkUpKeep("");

    // Assert
    assert(upkeepNeeded == false);
}
   
     function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpKeep("");

        // Assert
        assert(upkeepNeeded);
    }

        function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        // It doesnt revert
        raffle.performUpkeep("");
    }

       function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

       modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }


        function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered{
        // Arrange
       vm.recordLogs();
       raffle.performUpkeep("");
       Vm.Log[] memory entries = vm.getRecordedLogs();
       bytes32 requestId = entries[0].topics[1];


       Raffle.RaffleState rState = raffle.getRaffleState();

       assert(uint256(requestId) > 0);
       assert(uint256(rState) == 1);




    }


      function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
        public
        raffleEntered
        
    {
        // Arrange
        // Act / Assert
        vm.expectRevert("nonexistent request");
        // vm.mockCall could be used here...
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            0,
            address(raffle)
        );

        vm.expectRevert("nonexistent request");

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            1,
            address(raffle)
        );
    }



    //  function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
    //     public
    //     raffleEntered
        
    // {
    //     address expectedWinner = address(0);

    //     // Arrange
    //     uint256 additionalEntrances = 5;
    //     uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

    //     for (
    //         uint256 i = startingIndex;
    //         i < startingIndex + additionalEntrances;
    //         i++
    //     ) {
    //         address player = address(uint160(i));
    //         hoax(player, STARTING_USER_BALANCE); // deal 1 eth to the player
    //         raffle.enterRaffle{value: entranceFee}();
    //     }

    //     uint256 startingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 startingBalance = expectedWinner.balance;


    //     uint256 prize = entranceFee * (additionalEntrances + 1);
    //     //  console.log(requestId);
      
   


    //     // Act
    //     vm.recordLogs();
    //     raffle.performUpkeep(""); // emits requestId
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //      bytes32 requestId = entries[0].topics[1]; // get the requestId from the logs

    //     uint256 previousTimeStamp = raffle.getLastTimeStamp();
       

    //     VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
    //         uint256(requestId),
    //         address(raffle)
    //     );
       

    //     // Assert
    //     address recentWinner = raffle.getRecentWinner();
    //     Raffle.RaffleState raffleState = raffle.getRaffleState();
    //     uint256 winnerBalance = recentWinner.balance;
    //     uint256 endingTimeStamp = raffle.getLastTimeStamp();
   
      
    //     // assert(uint256(raffle.getRaffleState()) == 0);

    //     // assert(recentWinner != expectedWinner);
    //     // assert(uint256(raffleState) == 0);

    //     // assert(raffle.getLengthOfPlayer() == 0);
    //     // assert(previousTimeStamp < raffle.getLastTimeStamp());
    //     assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee );
    //     console.log(raffle.getRecentWinner().balance);
    //     console.log(prize);  
    //     console.log(prize);
       
    // }
}