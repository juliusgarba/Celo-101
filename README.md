
# How to build a Tipping System using Solidity on the Celo Blockchain

_Estimated reading time: **20 Minutes**_

## Table of Content
- [Introduction](#introduction)
  * [What is a blockchain?](#what-is-a-blockchain-)
  * [What is Solidity?](#what-is-solidity-)
  * [What is the Celo blockchain?](#what-is-the-celo-blockchain-)
- [Writing the smart contract](#writing-the-smart-contract)
  * [What problem is our code solving?](#what-problem-is-our-code-solving-)
  * [Smart contract code](#smart-contract-code)
- [Deploying the contract to the blockchain](#deploying-the-contract-to-the-blockchain)
  * [Why are we deploying it to Celo blockchain?](#why-are-we-deploying-it-to-celo-blockchain-)
  * [Using Remix](#using-remix)
    + [Write and compile code](#write-and-compile-code)
    + [Add Celo Extension to Remix](#add-celo-extension-to-remix)
    + [Deploying code to Celo blockchain](#deploying-code-to-celo-blockchain)
- [What is the way forward?](#what-is-the-way-forward-)
- [Conclusion](#conclusion)

## Introduction 
Hello there, welcome to my tutorial where we will be learning about blockchain technology step by step. But before we proceed further, let me ask you this simple question:

> _Have you ever gone to a restaurant where the staffs get's their salary bonus from tips?_

A tip is considered a monetary incentive which is given by the customer or guest for polite, prompt, and efficient service provided by by a restaurant or a hotel staff. Tipping a staff is usually not mandatory but it is necessary to appreciate the service provided by a staff.

A tipping system can be made better by using a blockchain technology to implement a solution that is transparent and accessible to everyone in the  world.

For this tutorial, we want to build a tipping system on the Celo blockchain using a smart contract programming language called Solidity. But before we start building, let's know what the above terminologies mean.

### What is a blockchain?
A blockchain is a shared, immutable ledger that facilitates the process of recording transactions and tracking assets in a business network. An asset can be tangible (a house, car, cash, land) or intangible (intellectual property, patents, copyrights, branding). Virtually anything of value can be tracked and traded on a blockchain network, reducing risk and cutting costs for all involved. 


### What is Solidity?
With the mention that Ethereum can be used to write smart contracts, we tend to corner our minds to the fact that there must be some programming language with which these applications are designed.
Yes, there is a programming language that makes it possible. It goes by the name ‘Solidity’.

Solidity is an object-oriented programming language which was developed by the core contributors of the Ethereum platform. It is used to design and implement smart contracts within the Ethereum Virtual Platform and several other Blockchain platforms like the Celo blockchain.

Solidity is a statically-typed programming language designed for developing smart contracts that run on the Ethereum Virtual Machine. With this language, developers can write applications that implement self-enforcing business logic embodied in smart contracts, leaving an authoritative record of transactions.

### What is the Celo blockchain?
Celo is the carbon-negative, mobile-first, EVM-compatible blockchain ecosystem leading a thriving new digital economy for all. Celo blockchain is a platform designed to allow mobile users around the world to make simple financial transactions with cryptocurrency. The platform has its own blockchain and a native currency known as CELO.

Now that you already know the basics of the blockchain, Solidity, and Celo, let's proceed to build a Tip System using Solidity smart contract.

## Writing the smart contract
### What problem is our code solving?
We are building a system that allows organizations to properly manage the tips offered to staff members by making it more transparent and open to all.
Our smart contract will be able to do the following:

- Let staffs of a particular organization go to the system and register themselves. We will not be collecting personal information like date of birth or email address from staff members. We will only collect general information like staff name, short description of staff, and profile picture. 
- Let admin verify the account of registered staffs so they can use the account to collect tips from customers.
- Let customers pay tip to this accounts created by staff members.
- Let staff withdraw their funds from the account into their own wallet after a period of time.
- Let admin remove any staff that behaves malicously or is no longer part of the organization.

### Smart contract code
Below is the Solidity smart contract code for our tipping system.

```solidity
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
```

We will now break down the smart contract code into small snippets and explain them one after the other.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```

In the first two lines of our code we specified the license that our code is guided by. This license is a very important aspect of our Solidity smart contract. Without the license, our Solidity code will not compile. Before we go further, let me give you short story of why Solidity requires that we add this license file to our smart contract code.

> _In the early days of smart contract development where all the projects were required to make their project's code opensource. Many companies abide by this law and uploaded all their code to opensource platforms like Github for the whole world to see and verify that the code does what they told you. But it didn't take long before some geeks started taking advantage of this move. A typical example is the Uniswap protocol. People discovered that Uniswap is making a lot of money, so they decided to clone Uniswap code and build their own version of Uniswap thereby creating a competition for Uniswap. I won't mention names but you have probably heard of projects like Pancakeswap, Sushiswap, etc_

Don't take the above story too formal. It's just a fun way of explaining why you need to add license to your smart contract code. You can do your own research to find out about the real story. Now back to code!

In the second line, we declared the version of compiler our code should work with. In this case, any compiler betweeen 0.8.0 to 0.9.0. You see, Solidity is a pretty new language whose formal version came out around 2018. So the language is still going through rapid changes and upgrade that is why you need to specify a range of version. You can still instruct your smart contract to use only one version though. Simply remove the caret sign (^) and your code will only compile on version 0.8.0 only.

```solidity
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
```

Inside the body of the contract, two structs were created. `Purse` and `Deposit`. Struct is a data type that Solidity provides for us to store a group of variables which are related. Using structs data type makes our code cleaner and easy to read. Structs are created with the keyword `struct` followed by the name we wish to give the struct. By convention, we are expected to format the struct name in title case.

`Purse` struct from our code holds information related to a purse. Our application will allow staffs to create purses (more like account) which they can use to receive tip paid by customers. `Deposit` struct also holds information related to a deposit made by a customer. It holds information like the purse Id it made deposit to, the address of customer making the deposit, how they felt about the service, and the amount deposited.

```solidity
    address payable deployer;
    mapping(address => bool) internal isStaff;
    mapping(address => bool) internal hasCreated;

    mapping(uint256 => Purse) internal purses;
    mapping(uint256 => Deposit) internal deposits;

    uint256 internal id = 0;
    uint256 internal depositsCounter;    
    uint256 cashoutInterval = 30 days;
```

After creating the structs that will be used to group data together, the next thing we did was to create variables that will hold these data for us.
For the code above, we first created a variable - `deployer`, which will hold the address of whoever deployed the contract. This account will have adminstrative privilledges over the contract. When then created two mappings - `isStaff` and `hasCreated`. `isStaff` mapping maps address to a boolean value (true or false). If an address is a set as a staff, it sets the value to `true`. The default value is `false`. `hasCreated` mapping is also very similar to `isStaff` mapping but the difference is that, `hasCreated` sets the value of an address key to `true `if the staff has already created a wallet before. It's purpose is to prevent staffs from creating multiple wallets.

We also created two other mappings - `purses` and `deposites`. `purses` mapping maps an ID to a `Purse` data (Remember the `Purse` struct we created earlier). So each purse created has a unique ID it can be queried with. The `deposits` mapping is also similar to the `purse` mapping. The only difference is that is keeps track of all deposits made by the customers and it maps a `uint` to a `Deposit` type.

We then created 3 more variables - `id`, `depositsCounter`, and `cashOutInterval`. `id` is the variable that assigns ID to all `Purse`s created (remember that `purses` mapping maps and ID to a `Purse`). `depositsCounter` is the variable that keeps track of the total deposits made. It can use used to query for all the deposits made to the contract. Notice the difference between the `id` and `depositCounter` variable? I did that intentionally to show you the concept of default values. The value of `depositCounter` is initialized to zero by default, so we can omit the zero assignment to `id` and everything will still work fine. 

We also have a variable to keep track of the interval between when a staff can made a withdrawal. We are using 30 days here to simulate the salary system. Solidity offers suffixes like `minutes`, `hours`, `days`, etc that you can use in your code directly. All of them evaluates to seconds. Refer to the list below to see all the suffixes.


- `1 == 1 seconds`
- `1 minutes == 60 seconds`
- `1 hours == 60 minutes`
- `1 days == 24 hours`
- `1 weeks == 7 days`

```solidity
 constructor() {
        deployer = payable(msg.sender);
    }
```

The first function inside the body of our contract is the `contructor `function. We created the constructor functon to set the deployer to the function caller. This function caller will in turn have administrative privileges over the contract.

```solidity
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
```
Two modifiers are then created - `onlyDeployer` and `idIsValid`. `onlyDeployer` checks that the address calling a function is the deployer of the contract (i.e admin), if the caller is not the admin, it throws an error with message description. `idIsValid` takes in the `id` of a purse and check if it is a valid ID, and throws an error with a message description otherwise.

```solidity
    event AddStaff(address indexed);
    event RemoveStaff(address indexed);
```

Two events are also created - `AddStaff()` and `RemoveStaff()`. These event are emitted and stored on the blockchain when a staff is added and removed from the contract respectively.

Now we will be going through the functions in the contract one after the other.

```solidity
    // Verify an address as a staff member of organisation
    function addStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = true;
        emit AddStaff(_staff_address);
    }
```

- The function above will take in a variable `_staff_address` 
- It is a public function and can only be called by the contract deployer (the admin)
- The first line inside the function first confirms if the staff address we want to add is valid, else throws an error with a message description
- It then proceeds to save the staff address in storage
- Lastly, it emits an event to indicate a staff has been added to the contract

```solidity
   // Remove an address as a staff memmber
    function removeStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = false;
        emit RemoveStaff(_staff_address);
    }
```
- The function above removes a staff from the contract
- It takes in a `address` parameter called `_staff_address` 
- It is public and can only be called by the contract deployer
- It first checks if the address entered is valid, before proceeding, else it reverts the transaction
- It then removes staff from storage
- It tnen emit event indicating staff has been removed

```solidity
    // Staff members can create new purse
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
```
- The function above takes in three arguments - `_staff_name`, `_about_staff`, and `_about_staff`
- It firsts of all validates that address creating new purse is a staff and has not created any purse before.
- It then proceeds to create a new purse with the arguments entered into the function and the default values.

```solidity
    // Verify purse created by staffs
    function verifyPurse(uint256 _purse_id)
        public
        onlyDeployer
        idIsValid(_purse_id)
    {
        require(isStaff[purses[_purse_id].staffId], "Not a staff member");
        purses[_purse_id].verified = true;
    }
```
- This function above verifies a purse
- It can only be called by the admin
- It first validates that the purse is owned by a staff member, before going ahead to set its verified property to `true`

```solidity
    // Customer deposits amount into purse
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
```
- This function above is called by a customer to deposit funds into a purse along with a message.
- The function has a modifier - `payable`, which means it can accept coins
- The function first validates the inputs before updating the user purse with amount sent along with the transaction
- The funds sent is stored in the contract

```solidity
    // Cash out all funds stored in purse
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
```
- Staffs call this function to withdraw their funds from this contract
- The function has a lot of similarities with the previous functions but one thing to note is the use of a low level function called `call()`. We used this function to transfer CELO to which ever address we called the function on (either contract address or wallet address). Be careful while using this function as things may go wrong.

```solidity
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
```
This function above is also similar to the functions defined earlier. it simply takes in a purse id and returns all the details about that purse.

We added one last special function called a fallback function. This function is executed when we call a function that does not exist in our contract, or sent some funds to the contract. In the case of our function, it will revert any of the trasaction. Below is how the function look like:

```solidity
  // Do nothing if any function is wrongly called
    fallback() external {
        revert();
    }
```

## Deploying the contract to the blockchain
After completing the contract code, the next step is to deploy it to the blockchain so that we can interact with it. We will be deploying it to the Celo blockchain from Remix IDE.

### Why are we deploying it to Celo blockchain?
- Celo blockchain is secured
- It is scalable
- It is interoprable i.e you can communicate with other blockchains
- It is easy to use.

### Using Remix
Remix IDE, is a no-setup tool with a GUI for developing smart contracts. Used by experts and beginners alike, Remix will get you going in double time. Remix plays well with other tools, and allows for a simple deployment process to the chain of your choice. Remix is famous for its visual debugger.

#### Write and compile code
Click [here](https://remix.ethereum.org) to open Remix IDE in your browser. Inside the contracts folder, right click and select **New File**. Save the file name as `TipContract.sol`. Inside the contract file, paste our code from above. Click on **CTRL + S** to save the code.

#### Add Celo Extension to Remix
In order to deploy the contract code to the blockchain, we will need to install the Celo extension on Remix.
Click on the extensions section and search for Celo, click on activate and it will be added to Remix. Now click on it from the left menu to open it.

#### Deploying code to Celo blockchain
- Once the extension is open, ensure your wallet is connected by clicking on the connect button at the top right. 
- Ensure that the contract has been compiled, then click on the **Deploy** button to deploy the contract to the Celo blockchain.
- After it is done deploying, the newly created address will display next to the button.

Remix will also create an interface where you can interact with the contract you just deployed.

## What is the way forward?
After you have sucessfully followed the steps above correctly and your contract is working as expected. The next step is to build a frontend that users can interact with. You can use Celo Extension Wallet to connect your code with the Celo blockchain. Challenge your self by adding more functionalities to the app, and even posting it on social media so friends can test it out.

## Conclusion
This tutorial teaches you how to write smart contracts with solidity and how to deploy the contract to the Celo blockchain using Remix ide. We covered the basic concepts on solidity smart contracts needed to get you started with advanced concepts. Next time, we will be covering more advanced concept. Stay prepared!


## Reference
- [Celo docs](https://docs.celo.org)
- [Celo Extension Wallet](https://chrome.google.com/webstore/detail/celoextensionwallet/kkilomkmpmkbdnfelcpgckmpcaemjcdh?hl=en)
- [Remix IDE](https://remix.ethereum.org)
- [Solidity Documentation](https://docs.soliditylang.org)
- [Introduction to blockchain](https://dacade.org/communities/blockchain/courses/intro-to-blockchain)
