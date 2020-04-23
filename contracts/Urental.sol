pragma solidity ^0.5.16;
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract Urental is Ownable{
    
    uint8 constant ACTION_BUYER_RENT = 0x01;
    uint8 constant ACTION_BUYER_START_RENT = 0x02;
    uint8 constant ACTION_BUYER_RELEASE_RENT = 0x03;
    uint8 constant ACTION_BUYER_CANCEL_RENT = 0x04;
    uint8 constant ACTION_SELLER_ACCEPT_RENT = 0x05;
    uint8 constant ACTION_SELLER_REQUEST_CAUTION = 0x06;
    uint8 constant ACTION_SELLER_ACCEPT_RELEASE = 0x07;
    uint8 constant ACTION_RENT_BLOCKED = 0x08;
    uint8 constant ACTION_RENT_IN_USE = 0x09;
    uint8 constant ACTION_RENT_FINISHED = 0x10;
    
    struct Rent {
        address payable buyer;
        address payable seller;
        uint256 amount;
        uint256 caution;
        uint256 duration;
        uint8 stateBuyer;
        uint8 stateSeller;
        uint8 stateRent;
        uint start;
    }
    
    mapping(bytes32 => Rent) private rents;
    
    modifier onlyAfter(bytes32 _id) {
        require(now > rents[_id].start + rents[_id].duration , "Rent is not ended yet");
        _;
    }
    
    modifier onlyBuyer (bytes32 _id) {
        require (msg.sender == rents[_id].buyer);
        _;
    }
    modifier onlySeller (bytes32 _id) {
        require (msg.sender == rents[_id].seller);
        _;
    }
    
    modifier onlyRentInUse(bytes32 _id) {
        require ( rents[_id].stateRent == ACTION_RENT_IN_USE );
        _;
    }
    modifier rentExist(bytes32 _id) {
        require( idExist(_id), "this rent allready exist" );
        _;
    }
    
    function getContractBalance() external onlyOwner view returns (uint) { 
        return address(this).balance;   
    }
    
    function rent(bytes32 _id, address payable _buyer, address payable _seller, uint256 _amount, uint256 _caution, uint256 _duration ) external payable {
        if( idExist(_id) ) {
            require( false, "this rent allready exist" );
        }
        require( msg.value == _amount + _caution, "Value incorect" );
        Rent storage rentList = rents[_id];

        rentList.buyer = _buyer;
        rentList.seller = _seller;
        rentList.amount = _amount;
        rentList.caution = _caution;
        rentList.duration = _duration;
        rentList.stateBuyer = ACTION_BUYER_RENT;
        rentList.stateSeller = ACTION_SELLER_ACCEPT_RENT;
        rentList.stateRent = ACTION_RENT_BLOCKED;
        rentList.start = 0;

    }
    
    /*
    function getRentHash(bytes32 _id, address payable _seller, uint256 _amount, uint256 _caution, uint256 _duration) external view returns(bytes32) {
        uint256 amount = _amount - _caution;
        //return keccak256(abi.encode(_id, msg.sender, _seller, amount, _caution, _duration));
    }
    */
    
    function getRent(bytes32 _id) external view returns (address, address, uint256, uint256, uint256, uint8) {
        return (rents[_id].seller, rents[_id].buyer, rents[_id].amount, rents[_id].caution, rents[_id].duration, rents[_id].stateRent);
    }
    
    function getSellerState (bytes32 _id) external onlySeller(_id) view returns (uint8) {
        return (rents[_id].stateSeller);
    }
    
    function getBuyerState (bytes32 _id) external onlyBuyer(_id) view returns (uint8) {
        return (rents[_id].stateBuyer);
    }
    
    function launchRent(bytes32 _id) external rentExist(_id) {
        if (msg.sender == rents[_id].buyer) {
            rents[_id].stateBuyer = ACTION_BUYER_START_RENT;
        }
        if(rents[_id].stateBuyer == ACTION_BUYER_START_RENT && rents[_id].start == 0 ) {
            rents[_id].start = now;
            rents[_id].stateRent = ACTION_RENT_IN_USE;
        }
    }
    
    function releaseRent(bytes32 _id) external onlyAfter(_id) onlyRentInUse(_id) returns (bool success) {
        if (msg.sender == rents[_id].buyer ) {
            rents[_id].stateBuyer = ACTION_BUYER_RELEASE_RENT;
        } else if (msg.sender == rents[_id].seller && rents[_id].stateSeller == ACTION_SELLER_REQUEST_CAUTION && rents[_id].stateBuyer == ACTION_BUYER_RELEASE_RENT ) {
            sendFullToSeller(_id);
            return true;
        } else if(msg.sender == rents[_id].seller){
            rents[_id].stateSeller = ACTION_SELLER_ACCEPT_RELEASE;
        } else {
            return false;
        }
    
        if(rents[_id].stateBuyer == ACTION_BUYER_RELEASE_RENT && rents[_id].stateSeller == ACTION_SELLER_ACCEPT_RELEASE && rents[_id].stateRent == ACTION_RENT_IN_USE) {
            rents[_id].stateRent = ACTION_RENT_FINISHED;
        }
        if (rents[_id].stateRent == ACTION_RENT_FINISHED) {
            
            sendRentPayment(_id);
            sendCautionBack(_id);
            return true;
            
        }
    }

    function askCaution (bytes32 _id) external onlyAfter(_id) onlyRentInUse(_id) onlySeller(_id) returns (bool success){
        rents[_id].stateSeller = ACTION_SELLER_REQUEST_CAUTION;
        return true;
    }
    
    function sendRentPayment(bytes32 _id) private returns (bool success) {
        rents[_id].seller.transfer(rents[_id].amount);
        return true;
    }
    
    function sendCautionBack(bytes32 _id) private returns (bool success) {
        rents[_id].buyer.transfer(rents[_id].caution);
        return true; 
    }
    
    function sendFullToSeller(bytes32 _id) private returns (bool success){
        rents[_id].seller.transfer(rents[_id].amount + rents[_id].caution);
        return true; 
    }
    
    function idExist(bytes32 id) view private returns (bool){
        return rents[id].seller != address(0);
    }
    
}