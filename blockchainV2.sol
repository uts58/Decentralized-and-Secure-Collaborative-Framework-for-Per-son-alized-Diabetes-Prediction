// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract HealthDataAccessControl {
    struct User {
        string name;
        address userAddress;
        string role; // "owner", "producer", "consumer"
    }

    struct PatientInfo {
        string name;
        uint age;
        string previousMedication;
    }

    mapping(address => User) public users;
    mapping(address => PatientInfo) public patientInfos;
    mapping(address => mapping(address => bool)) private patientToDataUserMapping; // patientAddress => (dataUserAddress => isAuthorized)

    event UserRegistered(address indexed userAddress, string role);
    event AccessGranted(address indexed patient, address indexed dataUser, string role);
    event AccessRevoked(address indexed patient, address indexed dataUser, string role);
    event MedicationUpdated(address indexed patient, string newMedication);

    // Register a data owner (patient)
    function registerDataOwner(address _userAddress, string memory _name, uint _age, string memory _previousMedication) public {
        users[_userAddress] = User(_name, _userAddress, "owner");
        patientInfos[_userAddress] = PatientInfo(_name, _age, _previousMedication);
        emit UserRegistered(_userAddress, "owner");
    }

    // Register a data producer
    function registerDataProducer(address _userAddress, string memory _name) public {
        users[_userAddress] = User(_name, _userAddress, "producer");
        emit UserRegistered(_userAddress, "Doctor (data producer is granted)");
    }

    // Register a data consumer
    function registerDataConsumer(address _userAddress, string memory _name) public {
        users[_userAddress] = User(_name, _userAddress, "consumer");
        emit UserRegistered(_userAddress, "consumer");
    }

    // Grant access to Healthcare Provider (Data Producer or Consumer)
    function grantAccess(address _patientAddress, address _dataUserAddress) 
    public {
        require(users[_patientAddress].userAddress == _patientAddress, 
        "Patient is not registered");
        require(users[_dataUserAddress].userAddress == _dataUserAddress, 
        "Healthcare Provider is not registered");
        
        patientToDataUserMapping[_patientAddress][_dataUserAddress] = true;
        emit AccessGranted(_patientAddress, _dataUserAddress, users[_dataUserAddress].role);
    }
    // Update a patient's medication by Health Provider (Data Producer only)
    function updateMedication(address _patientAddress, string memory _newMedication) 
    public {
    require(patientToDataUserMapping[_patientAddress][msg.sender], 
    "Unauthorized access !");
    require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("producer")), 
    "Only an authorized Healthcare Provider (producer) can see patient info and update medication if necessary");
     patientInfos[_patientAddress].previousMedication = _newMedication;
     emit MedicationUpdated(_patientAddress, _newMedication);
    }


   // Revoke access from a data consumer or producer
    function revokeAccess(address _patientAddress, address _dataUserAddress) 
    public {
     require(patientToDataUserMapping[_patientAddress][_dataUserAddress], "Access is not granted");
        
     patientToDataUserMapping[_patientAddress][_dataUserAddress] = false;
        emit AccessRevoked(_patientAddress, _dataUserAddress, users[_dataUserAddress].role);
    }

    // Verify access for a data consumer or producer
    function verifyAccess(address _patientAddress, address _dataUserAddress) public view returns (bool) {
        return patientToDataUserMapping[_patientAddress][_dataUserAddress];
    }
}