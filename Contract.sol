// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice A contract for tipping staffs of any organization 
contract TipContract {
    struct Purse {
        address payable staffId;
        string staffName;
        string aboutStaff;
        string profilePic;
        bool verified;
        bool disabled;
        uint256 amountDeposited;
        uint256 lastCashout;
    }

    struct Deposit {
        uint256 purseId;
        address depositor;
        string message;
        uint256 depositAmount;
    }

    address payable deployer;
    mapping(address => bool) internal isStaff;
    mapping(address => bool) internal hasCreated;

    mapping(uint256 => Purse) internal purses;
    mapping(uint256 => Deposit) internal deposits;

    uint256 internal id = 0;
    uint256 internal depositsCounter;    
    uint256 cashoutInterval = 30 days;

    constructor() {
        deployer = payable(msg.sender);
    }

    modifier onlyDeployer() {
        require(
            msg.sender == deployer,
            "Only contract deployer can call this function."
        );
        _;
    }

    modifier idIsValid(uint256 _purse_id) {
        require(_purse_id < id, "Invalid purse ID entered");
        _;
    }

    event AddStaff(address indexed);
    event RemoveStaff(address indexed);

    /// @notice Verify an address as a staff member of organisation
    /// @param _staff_address Address of staff to be added
    function addStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = true;
        emit AddStaff(_staff_address);
    }

    /// @notice Remove an address as a staff memmber
    /// param _staff_address Address of staff to be removed
    function removeStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = false;
        emit RemoveStaff(_staff_address);
    }

    /// @notice Staff members can create new purse
    /// @param _staff_name Name of staff to add
    /// @param _about_staff Short information about staff to add
    /// @param _staff_profile_pic Link to staff profile picture
    function newPurse(
        string memory _staff_name,
        string memory _about_staff,
        string memory _staff_profile_pic
    ) public {
        require(isStaff[msg.sender], "Only staff members can create new purse");
        require(
            !hasCreated[msg.sender],
            "You can't create more than one purse"
        );
        Purse storage purse = purses[id++];
        purse.staffId = payable(msg.sender);
        purse.staffName = _staff_name;
        purse.aboutStaff = _about_staff;
        purse.profilePic = _staff_profile_pic;
        purse.verified = false;
        purse.disabled = false;
        purse.amountDeposited = 0;
        purse.lastCashout = block.timestamp;

        hasCreated[msg.sender] = true;
    }

    /// @notice Verify purse created by staffs
    /// @param _purse_id ID of purse to verify
    function verifyPurse(uint256 _purse_id)
        public
        onlyDeployer
        idIsValid(_purse_id)
    {
        require(isStaff[purses[_purse_id].staffId], "Not a staff member");
        purses[_purse_id].verified = true;
    }

    /// @notice Customer deposits amount into purse
    /// @param _purse_id Id of purse to make deposit into
    /// @param _message Message to send along with deposit
    function depositIntoPurse(uint256 _purse_id, string memory _message)
        public
        payable
        idIsValid(_purse_id)
    {
        Purse storage purse = purses[_purse_id];
        require(purse.staffId != msg.sender, "Can't deposit into own purse");
        require(purse.verified, "Can't deposit into an unverified purse");
        require(!purse.disabled, "Can't deposit into a disabled purse");

        purse.amountDeposited += msg.value;
        Deposit storage deposit = deposits[depositsCounter++];
        deposit.purseId = _purse_id;
        deposit.depositor = msg.sender;
        deposit.message = _message;
        deposit.depositAmount = msg.value;
    }

    /// @notice Cash out all funds stored in purse
    /// @param _purse_id Id of purse to cashout from
    function cashOut(uint256 _purse_id) public {
        require(isStaff[msg.sender], "Only verified staffs can cashout");
        require(
            purses[_purse_id].staffId == msg.sender,
            "Can't cashout purse because you are not the owner"
        );
        require(
            purses[_purse_id].lastCashout + cashoutInterval <= block.timestamp,
            "Not yet time for cashout"
        );
        Purse storage purse = purses[_purse_id];
        uint256 amount = purse.amountDeposited;
        purse.amountDeposited = 0; // reset state variables before sending funds
        purse.lastCashout = block.timestamp;
        (bool sent, ) = purse.staffId.call{value: amount}("");
        require(sent, "Failed to cashout amount to staff wallet");
    }

    /// @notice Check if purse can accept funds before sending
    /// @param _purse_id ID of purse to check
    function canAcceptFunds(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (bool)
    {
        Purse memory purse = purses[_purse_id];
        return purse.verified && (purse.disabled == false);
    }

    /// @notice Read details about purse. Only deployer and purse owner can access
    /// @param _purse_id ID of purse to read data from
    function readPurse(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (
            string memory staffName,
            string memory aboutStaff,
            string memory profilePic,
            bool verified,
            bool disabled,
            uint256 amountDeposited,
            uint256 lastCashout
        )
    {
        Purse memory purse = purses[_purse_id];
        require(
            (msg.sender == purse.staffId) || (msg.sender == deployer),
            "Not authorized to call this function"
        );
        staffName = purse.staffName;
        aboutStaff = purse.aboutStaff;
        profilePic = purse.profilePic;
        verified = purse.verified;
        disabled = purse.disabled;
        amountDeposited = purse.amountDeposited;
        lastCashout = purse.lastCashout;
    }

    // Do nothing if any function is wrongly called
    fallback() external {
        revert();
    }
}
