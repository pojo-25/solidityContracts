pragma solidity ^0.4.17;


contract ProjectContract {
    
    struct TaxiDriver {
        address taxiDriverAddress;
        uint taxiDriverSalary;
        uint approvalState;
        mapping(address => bool) approverUsers;
        bool isApproved;
        uint taxiDriverBalance;
        bool isNotFired;
    }

    struct ParticipationUser {
        uint participationUserBalance;
        bool participationUserIsPurchasCarApproved;
        bool participationUserIsRepurchasedApproved;
        uint participationContribution;
    }
    
    struct ProposedCar {
       uint carID;
       uint price;
       uint validTime;
       uint approvalState;
    }
    
    struct ProposedRepurchase {
       uint carID;
       uint price;
       uint validTime;
       uint approvalState;
    }
    
    
    mapping(address => ParticipationUser) public participationUserDetailMap;
    address public manager;
    uint256 public constant weitoEthrConst = 1000000000000000000;
    uint256 public  ParticipationFee = 100 * weitoEthrConst;
    uint public participationCount = 0;
    uint public participationUserNumbers = 9;
    
    address public carDealerAddress;
    ProposedCar[] public proposedCars;
    ProposedRepurchase[] public proposedRepurchases; 
    
    TaxiDriver public taxiDriver;
    ParticipationUser[9] public participationUserList;
    
    uint public totalProfit = 0;
    address[] public participationUserAddressList;
    
    modifier onlyManagerAccesible() {
        require(msg.sender == manager);
        _;
    }
    
    modifier onlyCarDealerAccesible() {
        require(msg.sender == carDealerAddress);
        _;
    }
    
    modifier onlyParticipitionsAccesible() {
        require(participationUserDetailMap[msg.sender].participationContribution > 0);
        _;
    }
    
    modifier onlyDriversAccesible() {
        require(taxiDriver.taxiDriverAddress == msg.sender);
        _;
    }
    
    
    function ProjectContract() public {
        manager = msg.sender;
    }
    
    
    function() payable { 
       
    }
     
    function joinInverstment() public payable {
        require(msg.value > ParticipationFee);
        require(participationCount < participationUserNumbers);
        participationUserDetailMap[msg.sender].participationContribution = msg.value;
        participationUserDetailMap[msg.sender].participationUserIsPurchasCarApproved = false;
        participationCount++;
        participationUserAddressList.push(msg.sender);
    }
    
    function SetCarDealer(address carDlrAddr) public onlyManagerAccesible {
        carDealerAddress = carDlrAddr;
    }
    
    function convertToTimeStamp(uint dayOfValidTime) public  view returns (uint)  {
        // taken dayOfValidTime as month 
        return dayOfValidTime * 30*24*60*60;
    }   
    
    function convertEtherToWei(uint etherVal) public  view returns (uint)  {
        return etherVal * weitoEthrConst;
    }   
    
    function GetContractBalance() public onlyManagerAccesible view returns (uint)  {
        return address(this).balance;
    } 

    function GetRepurchaseApprovelNumberFromParticipiants() public onlyCarDealerAccesible view returns (uint)    {
        uint  approvelNumber = 0;
        for(uint i = 0; i < participationCount; i++){
            if(participationUserDetailMap[participationUserAddressList[i]].participationUserIsRepurchasedApproved) {
                approvelNumber++;
            }
        }
        return approvelNumber;
    } 

    function GetTaxiDriverApprovelNumberFromParticipiants() public onlyManagerAccesible view returns (uint)  {
        uint  approvelNumber = 0;
        for(uint i = 0; i < participationCount; i++){
            if(taxiDriver.approverUsers[participationUserAddressList[i]]) {
                approvelNumber++;
            }
        }
        return approvelNumber;
    } 
    
    // for controlling validtime of purchase car  
    uint public startValidTime;

    // price as wei, validTime as month 
    // example usage(123, 3, 4, 0)
    function CarProposeToBusiness(uint carID, uint price, uint validTime, uint approvalState) public onlyCarDealerAccesible {
        ProposedCar memory newProposedCar = ProposedCar({
          carID: carID,
          price: convertEtherToWei(price),
          validTime: convertToTimeStamp(validTime),
          approvalState: approvalState
        });
        startValidTime = now;
        proposedCars.push(newProposedCar);
    }
    
    function ApprovePurchaseCar(uint index) public onlyParticipitionsAccesible {
        ProposedCar storage proposedCar = proposedCars[index];
        require(!participationUserDetailMap[msg.sender].participationUserIsPurchasCarApproved);
        participationUserDetailMap[msg.sender].participationUserIsPurchasCarApproved = true;
        proposedCar.approvalState++;
    }
    
    
    function PurchaseCar(uint index) public onlyManagerAccesible {
        ProposedCar storage proposedCar = proposedCars[index];
        require(now - startValidTime < proposedCar.validTime);
        require(proposedCar.approvalState > (participationCount / 2));
        carDealerAddress.transfer(proposedCar.price);
    }
    
    // for controlling validtime of Repurchase a car 
    uint public startRepurchaseValidTime = 0;
    
    function RepurchaseCarPropose(uint index) public onlyCarDealerAccesible {
        ProposedCar storage tempProposedCar = proposedCars[index];
        ProposedRepurchase memory newProposedRepurchase = ProposedRepurchase({
          carID: tempProposedCar.carID,
          price: tempProposedCar.price,
          validTime: tempProposedCar.validTime,
          approvalState: 0
        });
        startRepurchaseValidTime = now;
        proposedRepurchases.push(newProposedRepurchase);
    }
    
    
    function ApproveSellProposal(uint index) public onlyParticipitionsAccesible {
        ProposedRepurchase storage proposedRepurchase = proposedRepurchases[index];
        require(!participationUserDetailMap[msg.sender].participationUserIsRepurchasedApproved);
        participationUserDetailMap[msg.sender].participationUserIsRepurchasedApproved = true;
        proposedRepurchase.approvalState++;
    }
    
    
    function Repurchasecar(uint index) public onlyCarDealerAccesible payable {
         ProposedRepurchase storage proposedRepurchase = proposedRepurchases[index];
         require(now - startRepurchaseValidTime < proposedRepurchase.validTime);
         require(GetRepurchaseApprovelNumberFromParticipiants() > (participationCount / 2));
    }
    
    // taxiDriverSalary as wei
    function ProposeDriver(address taxDriverAddr, uint taxiDriverSalary) public onlyManagerAccesible {
        TaxiDriver memory newTaxiDriver = TaxiDriver({
          taxiDriverAddress: taxDriverAddr,
          taxiDriverSalary : convertEtherToWei(taxiDriverSalary),
          approvalState: 0,
          isApproved: false,
          taxiDriverBalance:0,
          isNotFired:false
        });

        taxiDriver = newTaxiDriver;
    }
    
    function ApproveDriver(uint index) public onlyParticipitionsAccesible {
        require(!taxiDriver.approverUsers[msg.sender]);
        taxiDriver.approverUsers[msg.sender] = true;
        taxiDriver.approvalState++;
    }
    
    // car is started to work as taxi
    uint public taxiWorkingStartingTime = 0;
    // six month period as fixed
    uint public sixMonthAsTimeStamp = 6*30*24*60*60;
     // one month period as constant
    uint public oneMonthAsTimeStamp = 30*24*60*60;
    // for preventing calling manager to ReleaseSalary more than once in a month
    uint public regularCallReleaseSalary = 0;
    // for preventing calling manager to CarExpenses more than once in six months
    uint public regularCallForCarExpenses = 0;
    // for preventing calling manager to PayDividend more than once in six months
    uint public regularCallPayDividentCalled = 0;
    
    
    function SetDriver(uint index) public onlyManagerAccesible {
        require(GetTaxiDriverApprovelNumberFromParticipiants() > (participationCount / 2));
        taxiDriver.isApproved = true;
        taxiWorkingStartingTime = now;
        regularCallReleaseSalary = taxiWorkingStartingTime;
        regularCallPayDividentCalled = taxiWorkingStartingTime;
    }
    
    
    function FireDriver(address taxDriverAddr) public onlyManagerAccesible {
       require(taxiDriver.isApproved);
       require(!taxiDriver.isNotFired);
       taxDriverAddr.transfer(taxiDriver.taxiDriverSalary);
       taxiDriver.isNotFired = true;
    }
    
    function GetCharge() public payable {
    }
    
    function ReleaseSalary() public onlyManagerAccesible {
        uint timeNow = now;
        require(timeNow - regularCallReleaseSalary == oneMonthAsTimeStamp);
        require(taxiDriver.isApproved);
        require(!taxiDriver.isNotFired);
        regularCallReleaseSalary = regularCallReleaseSalary + oneMonthAsTimeStamp;
        taxiDriver.taxiDriverBalance = taxiDriver.taxiDriverBalance + taxiDriver.taxiDriverSalary;
    }
    
    function GetSalary() public onlyDriversAccesible {
        require(!taxiDriver.isNotFired);
        require(taxiDriver.taxiDriverBalance > 0);
        taxiDriver.taxiDriverAddress.transfer(taxiDriver.taxiDriverBalance);
        taxiDriver.taxiDriverBalance = 0; 
    }
    
    uint public totalCarExpenses = 10;
    
    function CarExpenses() public onlyManagerAccesible {
        uint timeNow = now; 
        require(timeNow - regularCallForCarExpenses == sixMonthAsTimeStamp);
        regularCallForCarExpenses = regularCallForCarExpenses + sixMonthAsTimeStamp;
        carDealerAddress.transfer(convertEtherToWei(totalCarExpenses));
    }
    
    function PayDividend() public onlyManagerAccesible {
        uint timeNow = now; 
        require(timeNow - regularCallPayDividentCalled == sixMonthAsTimeStamp);
        regularCallPayDividentCalled = regularCallPayDividentCalled + sixMonthAsTimeStamp;
        uint profitPerParticipiant = GetContractBalance() / participationCount;
        
        for(uint i = 0; i < participationCount; i++){
            participationUserDetailMap[participationUserAddressList[i]].participationUserBalance 
                = participationUserDetailMap[participationUserAddressList[i]].
                    participationUserBalance + profitPerParticipiant;
        }

        
    }
    
    function GetDividend() public onlyParticipitionsAccesible {
            if(participationUserDetailMap[msg.sender].participationUserBalance > 0) {
                msg.sender.transfer(participationUserDetailMap[msg.sender].
                    participationUserBalance);
            }
    }
    
  
    
    
    
    
    
    
    
    
  
    
    
    
    
    
    



    
    
    
    


    
    
    
    
    
    
    
    
}

