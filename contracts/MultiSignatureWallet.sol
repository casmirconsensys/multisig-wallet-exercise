pragma solidity ^0.5.0;

contract MultiSignatureWallet {



  uint constant public MAX_OWNER_COUNT = 2;

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed owner);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint required);

   mapping (uint => Transaction) public transactions;
   mapping (uint => mapping(address => bool)) public confirmations;
   mapping (address => bool) public isOwner;
   address[] public owners;
   uint public required;
   uint public transactionCount;

      struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
      }



  modifier onlyWallet() {
            require(msg.sender == address(this));
            _;
        }

  modifier ownerExists(address owner) {
          require(isOwner[owner]);
          _;
      }

modifier ownerDoesNotExist(address owner) {
           require(!isOwner[owner]);
           _;
       }

  modifier confirmed(uint transactionId, address owner) {
             require(confirmations[transactionId][owner]);
             _;
         }

  modifier notConfirmed(uint transactionId, address owner) {
               require(!confirmations[transactionId][owner]);
               _;
           }

  modifier notExecuted(uint transactionId) {
                 require(!transactions[transactionId].executed);
                 _;
             }

  modifier notNull(address _address) {
                   require(_address != address(0));
                   _;
               }

  modifier  validRequirement( uint ownerCount, uint _required) {
      if (  _required > ownerCount
          ||  _required == 0
          ||  ownerCount   == 0)
          revert();
          _;
        }



    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)
          public



          validRequirement(_owners.length, _required)
      {
          for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == address (0))
              revert();
            isOwner[_owners[i]] = true;
          }
          owners = _owners;
          required = _required;
      }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes
    memory data)
    public
    returns (uint transactionId)
  {
    require(isOwner[msg.sender]);
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
    public
  {
     require(isOwner[msg.sender]);
     require(transactions[transactionId].destination != address (0));
     require(confirmations[transactionId][msg.sender] == false);
     confirmations[transactionId][msg.sender] = true;
     executeTransaction(transactionId);
  }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
    public
 {
    require(transactions[transactionId].executed == false);
 }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    public
{
    require(transactions[transactionId].executed == false);
    if (isConfirmed(transactionId)) {
      Transaction storage t  = transactions[transactionId];
      t.executed = true;
      (bool success, bytes memory data) =
      t.destination.call.value(t.value)(t.data);
      if (success)
          emit Execution(transactionId);
      else {
          emit ExecutionFailure(transactionId);
          t.executed = false;
      }
}
}
		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
    public
    view
    returns (bool)
  {
    uint count = 0;
     for(uint i=0; i<owners.length; i++) {
        if (confirmations[transactionId][owners[i]])
            count += 1;
        if (count == required)
            return true;
  }
}
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
    internal
    returns (uint transactionId)
  {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination: destination,
      value: value,
      data: data,
      executed: false
    });
    transactionCount +=1;
    emit Submission(transactionId);
  }
}
