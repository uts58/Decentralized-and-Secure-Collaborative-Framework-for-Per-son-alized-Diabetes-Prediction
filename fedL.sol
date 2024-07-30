// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FederatedLearning {
    struct ModelUpdate {
        address contributor;
        uint256 accuracy;
        uint256 modelUpdate;
    }

    address public owner;
    ModelUpdate[] public updates;
    mapping(address => bool) public participants;
    uint256 public aggregatedModel; // Holds the aggregated model update
    uint256 public startOfRound;
    uint256 public participationWindow = 1 hours; // After this time new model updates enter into the next round
    bool public roundActive = false;
    uint256 public lastUpdatedAccuracy; // Store the last updated accuracy

    event ModelUpdated(address contributor, uint256 accuracy, uint256 modelUpdate);
    event ParticipantRegistered(address participant);
    event ModelAggregated(uint256 aggregatedModel, uint256 updatedAccuracy);
    event RoundStarted(uint256 startOfRound);
    event RoundEnded(uint256 endOfRound);

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner can perform this action.");
        _;
    }

    modifier FLClients() {
        require(participants[msg.sender], "Only registered participants can perform this action.");
        require(roundActive, "No active round.");
        require(block.timestamp <= startOfRound + participationWindow, "Participation window closed.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerParticipant(address _participant) public onlyOwner {
        require(!participants[_participant], "Participant already registered.");
        participants[_participant] = true;
        emit ParticipantRegistered(_participant);
    }

    function startRound() public onlyOwner {
        require(!roundActive, "A round is already active.");
        startOfRound = block.timestamp;
        roundActive = true;
        emit RoundStarted(startOfRound);
    }

 

    function closeParticipationWindow() public onlyOwner {
        require(roundActive, "No active round to close.");
        roundActive = false;
        emit RoundEnded(block.timestamp);
    }


       function submitUpdate(uint256 _accuracy, uint256 _modelUpdate) public FLClients {
        updates.push(ModelUpdate({
            contributor: msg.sender,
            accuracy: _accuracy,
            modelUpdate: _modelUpdate
        }));
        emit ModelUpdated(msg.sender, _accuracy, _modelUpdate);
    }
    // Model Aggregation
    function aggregateModel() public FLClients {
        require(!roundActive, "Only FL Clients can submit model updates");
        uint256 sum = 0;
        for (uint i = 0; i < updates.length; i++) {
            sum += updates[i].modelUpdate;
        }
        aggregatedModel = sum / updates.length;
        lastUpdatedAccuracy = aggregatedModel % 100;
        emit ModelAggregated(aggregatedModel, lastUpdatedAccuracy);
        // Reset for next round
        delete updates;
    }


    function getNumberOfUpdates() public view returns (uint256) {
        return updates.length;
    }
}
