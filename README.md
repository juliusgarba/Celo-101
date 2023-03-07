# How to Build a Tipping System on the Celo Blockchain

## Introduction 
Hello there, welcome to my tutorial where we will be learning about creating a tipping system using blockchain technologies step by step. But before we proceed further, let me ask you this simple question:

> _Have you ever gone to a restaurant where the staffs get their salary bonus from tips?_

A tip is considered a monetary incentive that is given by the customer or guest for polite, prompt, and efficient service provided by a restaurant or hotel staff. Tipping staff is usually not mandatory but it is necessary to appreciate the service provided by staff.

A tipping system can be made better by using blockchain technology to implement a solution that is transparent and accessible to everyone.

For this tutorial, we want to build a tipping system on the Celo blockchain using a smart contract programming language called Solidity. But before we start building, let's know what the above terminologies mean.

### What is the Blockchain?
The blockchain is a shared, immutable ledger that facilitates the process of recording transactions and tracking assets in a business network. An asset can be **tangible** (a house, car, cash, land) or **intangible** (intellectual property, patents, copyrights, branding). Virtually anything of value can be tracked and traded on a blockchain network, reducing risk and cutting costs for all involved. 


### What is Solidity?
With the mention that Ethereum can be used to write smart contracts, we tend to corner our minds to the fact that there must be some programming language with which these applications are designed.
Yes, there is a programming language that makes it possible. It goes by the name of ‘**Solidity**’.

Solidity is an object-oriented and statically-typed programming language that was developed by the core contributors of the Ethereum platform. It is used to design and implement smart contracts that implement self-enforcing business logic within the Ethereum Virtual Machine and several other  EVM-compatible blockchain platforms like the Celo blockchain.


### What is the Celo blockchain?
Celo is the carbon-negative, mobile-first, EVM-compatible blockchain ecosystem leading a thriving new digital economy for all. The Celo blockchain is an ecosystem designed to allow mobile users around the world to make simple financial transactions with cryptocurrency. The platform has its own blockchain and a native coin known as CELO.

Now that you already know the basics of the blockchain, Solidity, and Celo, let's proceed to build a Tip System using Solidity smart contract.

## Writing the Smart Contract

### What Problem is Our Code Solving?
We are building a system that allows organizations to properly manage the tips offered to staff members by making it more transparent and open to all.
Our smart contract will be able to do the following:

- Let the staff of a particular organization go to the system and register themselves. We will not be collecting personal information like date of birth or email address from staff members. We will only collect general information like staff names, short descriptions, and profile pictures. 
- Let admin verify the account of registered staff so they can use the account to collect tips from customers.
- Let customers pay a tip to these accounts created by staff members.
- Let staff withdraw their funds from the account into their own wallet after a period of time.
- Let admin remove any staff that behaves maliciously or is no longer part of the organization.

### Smart Contract Code
Below is the Solidity smart contract code for our tipping system.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipContract {
    struct Purse {
        address payable staffId;
        string staffName;
        string aboutStaff;
        string profilePic;
        bool verified;
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

    // Verify an address as a staff member of organisation
    function addStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = true;
        emit AddStaff(_staff_address);
    }

    // Remove an address as a staff memmber
    function removeStaff(address _staff_address) public onlyDeployer {
        require(
            _staff_address != address(0),
            "Staff address can't be an empty address"
        );
        isStaff[_staff_address] = false;
        emit RemoveStaff(_staff_address);
    }

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
        purse.amountDeposited = 0;
        purse.lastCashout = block.timestamp;

        hasCreated[msg.sender] = true;
    }

    // Verify purse created by staffs
    function verifyPurse(uint256 _purse_id)
        public
        onlyDeployer
        idIsValid(_purse_id)
    {
        require(isStaff[purses[_purse_id].staffId], "Not a staff member");
        purses[_purse_id].verified = true;
    }

    // Customer deposits amount into purse
    function depositIntoPurse(uint256 _purse_id, string memory _message)
        public
        payable
        idIsValid(_purse_id)
    {
        Purse storage purse = purses[_purse_id];
        require(purse.staffId != msg.sender, "Can't deposit into own purse");
        require(canAcceptFunds(_purse_id), "Can't deposit into an unverified or invalid purse");

        purse.amountDeposited += msg.value;
        Deposit storage deposit = deposits[depositsCounter++];
        deposit.purseId = _purse_id;
        deposit.depositor = msg.sender;
        deposit.message = _message;
        deposit.depositAmount = msg.value;
    }

    // Cash out all funds stored in purse
    function cashOut(uint256 _purse_id) public {
        require(
            purses[_purse_id].staffId == msg.sender,
            "Can't cashout purse because you are not the owner"
        );
        require(
            purses[_purse_id].lastCashout + cashoutInterval <= block.timestamp,
            "Not yet time for cashout"
        );
        require(purses[_purse_id].amountDeposited > 0, "No balance to cash out.");
        Purse storage purse = purses[_purse_id];
        uint256 amount = purse.amountDeposited;
        purse.amountDeposited = 0; // reset state variables before sending funds
        purse.lastCashout = block.timestamp;
        (bool sent, ) = purse.staffId.call{value: amount}("");
        require(sent, "Failed to cashout amount to staff wallet");
    }

    // Check if purse can accept funds before sending
    function canAcceptFunds(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (bool)
    {
        Purse memory purse = purses[_purse_id];
        return purse.verified && (isStaff[purse.staffId]);
    }

    // Read details about purse. Only deployer and purse owner can access
    function readPurse(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (
            string memory staffName,
            string memory aboutStaff,
            string memory profilePic,
            bool verified,
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
        amountDeposited = purse.amountDeposited;
        lastCashout = purse.lastCashout;
    }

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

In the first two lines of our code, we specified the license that our code is guided by. This license is a very important aspect of our solidity smart contract. Without the license, our solidity code will not compile. Before we go further, let me give you a short story of why Solidity requires that we add this license file to our smart contract code.

> _In the early days of smart contract development where all the projects were required to make their project code open source. Many companies abide by this law and uploaded all their code to open-source platforms like Github for the whole world to see and verify that the code does what they told you. But it didn't take long before some geeks started taking advantage of this move. A typical example is the Uniswap protocol. People discovered that Uniswap is making a lot of money, so they decided to clone Uniswap code and build their own version of Uniswap thereby creating competition for Uniswap. I won't mention names but you probably heard of projects like Pancakeswap, Sushiswap, etc_

Don't take the above story too formally. It's just a fun way of explaining why you need to add a license to your smart contract code. You can do your own research to find out about the real story. Now back to code!

In the second line, we declared the version of the compiler our code should work on. In this case, any compiler between version `0.8.0` and less than version `0.9.0`. You see, Solidity is a pretty new language whose formal version came out around 2018. So the language is still going through rapid changes and upgrades which is why you need to specify a range of versions. You can still instruct your smart contract to use only one version though. Simply remove the caret sign (^) and your code will only compile on version `0.8.0` only.

```solidity
    struct Purse {
        address payable staffId;
        string staffName;
        string aboutStaff;
        string profilePic;
        bool verified;
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

Inside the body of the contract, two structs were created. `Purse` and `Deposit`. A [struct](https://docs.soliditylang.org/en/v0.8.14/structure-of-a-contract.html#struct-types) is a data type that Solidity provides for us to store a group of variables that are related. Using the `struct` data type makes our code cleaner and easy to read. Structs are created with the keyword `struct` followed by the name we wish to give the struct. By convention, we are expected to format the struct name in the **CapWords** style.

The `Purse` struct from our code holds information related to a purse. Our application will allow staff to create purses (more like accounts) which they can use to receive tips paid by customers. The `Deposit` struct also holds information related to a deposit made by a customer. It holds information like the purse `Id` to deposit to, the address of the customer making the deposit, how they felt about the service, and the amount deposited.

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

After creating the structs that will be used to group data together, the next thing we did was create variables that will hold these data for us.
For the code above, we first created a variable - `deployer`, which will hold the address of whoever deployed the contract. This account will have administrative privileges over the contract. We then created two mappings - `isStaff` and `hasCreated`. The `isStaff` mapping maps addresses to boolean values (true or false). If an address is set as a staff, it sets the value to *true*. The default value is *false*. The `hasCreated` mapping is also very similar to the `isStaff` mapping but the difference is that, `hasCreated` sets the value of an address key to *true* if the staff has already created a wallet before. Its purpose is to prevent staff from creating multiple wallets.

We also created two other mappings - `purses` and `deposits`. The `purses` mapping maps an ID to a `purse` data (Remember the `Purse` struct we created earlier). So each purse created has a unique ID it can be queried with. The `deposits` mapping is also similar to the `purses` mapping. The only difference is that it keeps track of all deposits made by the customers and it maps a `uint` to a `deposit` type.

We then created 3 more variables - `id`, `depositsCounter`, and `cashOutInterval`. The `id` variable assigns an ID to all purses created (remember that `purses` mapping maps an ID to a `purse`). `depositsCounter` is the variable that keeps track of the total deposits made. It can use used to query all the deposits made to the contract. Notice the difference between the `id` and `depositCounter` variables? I did that intentionally to show you the concept of default values. The value of `depositCounter` is initialized to zero by default, so we can omit the zero assignment to `id` and everything will still work fine. We also have a variable to keep track of the interval between when staff can make a withdrawal. We are using 30 days here to simulate the salary system. Solidity offers suffixes like minutes, hours, days, etc that you can use in your code directly. All of them evaluates in seconds. Refer to the list below to see the full list.



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

The first function inside the body of our contract is the constructor function. We created the constructor function to set the deployer to the function caller. This function caller will in turn have admin privileges over the contract.

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
Two modifiers are then created - `onlyDeployer` and `idIsValid`. `onlyDeployer` checks that the address calling a function is the deployer of the contract (i.e admin), if the caller is not the admin, it throws an error with a message description. `idIsValid` takes in the ID of a purse and checks if it is a valid ID, and throws an error with a message description if the ID isn't valid.

```solidity
    event AddStaff(address indexed);
    event RemoveStaff(address indexed);
```

Two events are also created - `AddStaff()` and `RemoveStaff`. These events are emitted and stored on the blockchain when staff is added and removed from the contract respectively.

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

- This function above will take in a parameter`_staff_address` 
- It is a `public` function and can only be called by the contract deployer (the admin)
- The first line inside the function first confirms if the staff address we want to add is valid, else throws an error with a message description
- It then proceeds to save the staff in storage
- Lastly, it emits an event to indicate a staff has been added to the blockchain

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
- This function above removes staff from the system
- It takes in an `address` parameter called `_staff_address` 
- It is `public` and can only be called by the contract deployer
- It first checks if the address entered is *valid*, before proceeding, else it reverts the transaction with an error message
- If then removes staff from storage
- It then emits an event indicating staff has been removed

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
        purse.amountDeposited = 0;
        purse.lastCashout = block.timestamp;

        hasCreated[msg.sender] = true;
    }
```
- The function above takes in three parameters - `_staff_name`, `_about_staff`, and `_staff_profile_pic`
- It, first of all, validates that the sender calling the function is a staff and has not created any purse before.
- It then proceeds to create a new purse with the arguments passed into the function and the default values.

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
- The function above verifies a purse
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
        require(canAcceptFunds(_purse_id), "Can't deposit into an unverified or invalid purse");

        purse.amountDeposited += msg.value;
        Deposit storage deposit = deposits[depositsCounter++];
        deposit.purseId = _purse_id;
        deposit.depositor = msg.sender;
        deposit.message = _message;
        deposit.depositAmount = msg.value;
    }
```
- This function above is called by a customer to deposit funds into a purse along with a message.
- The function has a modifier - `payable` which means that the function can receive CELO tokens.
- The function first checks if the argument sent for `_purse_id` is valid.
- It then checks if the sender is not the purse's owner.
- Finally, the function checks if the purse can receive tips by calling the **canAcceptFunds()** function that returns a boolean value inside a *require* statement
- If all the checks have passed, the function then adds the `msg.value` to the `purse`'s `amountDeposited` property, creates a `deposit` object, and stores it in the state.

Next up is the `cashOut()` function:

```solidity
    // Cash out all funds stored in purse
    function cashOut(uint256 _purse_id) public {
        require(
            purses[_purse_id].staffId == msg.sender,
            "Can't cashout purse because you are not the owner"
        );
        require(
            purses[_purse_id].lastCashout + cashoutInterval <= block.timestamp,
            "Not yet time for cashout"
        );
        require(purses[_purse_id].amountDeposited > 0, "No balance to cash out.");
        Purse storage purse = purses[_purse_id];
        uint256 amount = purse.amountDeposited;
        purse.amountDeposited = 0; // reset state variables before sending funds
        purse.lastCashout = block.timestamp;
        (bool sent, ) = purse.staffId.call{value: amount}("");
        require(sent, "Failed to cashout amount to staff wallet");
    }
```
- Staff can call this function to withdraw their tips stored in their respective purse in the smart contract.
- The function first checks if the `sender` is the owner of the purse.
- It then checks if enough time has passed since the last cash out and whether the purse's `amountDeposited` is greater than zero.
- Finally, if all the checks have passed, the `amountDeposited` is fetched from storage and then updated before we use the `.call()` method which is a low-level function to send the CELO to the purse's owner. Since the `.call()` method does not automatically revert the transaction during failure, we perform a check to ensure that the transfer has been successful.


We will now create the `canAcceptFunds()` function:

```solidity
    // Check if purse can accept funds before sending
    function canAcceptFunds(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (bool)
    {
        Purse memory purse = purses[_purse_id];
        return purse.verified && (isStaff[purse.staffId]);
    }

```

- The `canAcceptFunds()` function takes in a `_purse_id` as a parameter that refers to a purse ID.
- The function first checks if the purse ID provided is valid
- If it is, the function returns a `boolean` value that is calculated based on the `verified` property of the purse and the `isStaff` value of the purse's owner. The function returns **true** if both values are **true**, otherwise, if any of the values are **false**, **false** is returned. 


Next, we will define the `readPurse()` function:

```solidity
    // Read details about purse. Only deployer and purse owner can access
    function readPurse(uint256 _purse_id)
        public
        view
        idIsValid(_purse_id)
        returns (
            string memory staffName,
            string memory aboutStaff,
            string memory profilePic,
            bool verified,
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
        amountDeposited = purse.amountDeposited;
        lastCashout = purse.lastCashout;
    }
```
The function above takes a `_purse_id` as a parameter and returns all the details about that purse and can only be successfully used by the admin or owner of the purse.

We will add one last special function called a `fallback` function. This function is executed if none of the other functions match the function identifier or no data was provided with the function call or sent some plain funds without any data to the contract. In the case of our function, it will revert any of the transactions. Below is what the function looks like:

```solidity
    fallback() external {
        revert();
    }
```

## Deploying the contract to the blockchain
After completing the contract code, the next step is to deploy it to the blockchain so that we can interract with it. We will be deploying it to the Celo blockchain from Remix.

### Why are we deploying it to Celo blockchain?
- Celo blockchain is secured
- It is scalable
- It is interoprable i.e you can communicate with other blockchains
- It is easy to use.

### Using Remix
Remix IDE, is a no-setup tool with a GUI for developing smart contracts. Used by experts and beginners alike, Remix will get you going in double time. Remix plays well with other tools, and allows for a simple deployment process to the chain of your choice. Remix is famous for its visual debugger.

#### Write and compile code
Click [here](https://remix.ethereum.org) to open Remix IDE in your browser. Inside the contracts folder, right click and select "New File". Save the file name as TipContract.sol. Inside the contract file, paste our code from above. Click on CTRL +S to save the code

#### Add Celo Extension to Remix
In order to deploy the contract code to the blockchain, we will need to insftall the Celo extension on Remix.
Click on the extensions section and search for celo, click on activate and it will be added to remix. Now click on it from the left menu to open it.

#### Deploying code to Celo blockchain
Once the extension is open, ensure your wallet is connected by clicking on the connect button at the top right. 
Ensure that the contract has been compiled, then clickon the Deploy button to deploy the contract to the celo blockchain.
After it is done deploying, the newly created address will display nect to the button.

Remix will also create an interface where you can interact with the contract you just deployed.

## What is the way forward?
After you have sucessfully followed the steps above correctly and your contract is working as expected. The next step is to build a frontend that users can interact with. You can use Celo Extension Wallet to connect your code with the Celo blockchain. Challenge your self by adding more functionalities to the app, and even posting it on social media so friends can test it out.

## Conclusion
This tutorial teaches you how to write smart contracts with solidity and how to deploy the contract to the Celo blockchain using Remix ide. We covered the basic concepts on solidity smart contracts needed to get you started with advanced concepts. Next time, we will be covering more advanced concept. Stay prepared!

