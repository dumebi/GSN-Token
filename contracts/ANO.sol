pragma solidity >=0.4.22 <0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import "@0x/contracts-utils/contracts/src/LibBytes.sol";

import './Ownable.sol';
import './Blacklistable.sol';
import './Pausable.sol';

contract ANO is GSNRecipient, Ownable, ERC20, Pausable, Blacklistable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;
    uint256 internal totalSupply_;
    uint256 public gsnFee;

    enum GSNErrorCodes {
        INSUFFICIENT_BALANCE, NOT_ALLOWED
    }

    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
   
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event GSNFeeUpdated(uint256 oldFee, uint256 newFee);
    event GSNFeeCharged(uint256 fee, address user);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _currency,
        uint8 _decimals,
        address _masterMinter,
        address _pauser,
        address _blacklister,
        address _owner,
        uint256 _gsnFee,
        uint256 _totalSupply
    ) public {
        require(!initialized, 'Contract is already initialized');
        require(_masterMinter != address(0), 'Master Minter does not exist');
        require(_owner != address(0), 'Contract owner does not exist');
        require(_pauser != address(0));
        require(_blacklister != address(0));

        GSNRecipient.initialize();
        name = _name;
        symbol = _symbol;
        currency = _currency;
        decimals = _decimals;
        masterMinter = _masterMinter;
        pauser = _pauser;
        blacklister = _blacklister;
        gsnFee = _gsnFee;
        setOwner(_owner);
        initialized = true;
        totalSupply_ = _totalSupply;
        balances[_owner] = balances[_owner].add(_totalSupply);
    }

    /**
      * @dev Throws if called by any account other than a minter
    */
    modifier onlyMinters() {
        require(minters[_msgSender()] == true, 'Only a minter can call this function');
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) whenNotPaused onlyMinters notBlacklisted(_msgSender()) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0), 'Mint destination adddress is invalid');
        require(_amount > 0, 'Mint amount has to be greater than one');

        uint256 mintingAllowedAmount = minterAllowed[_msgSender()];
        require(_amount <= mintingAllowedAmount, 'Not allowed to mint this amount');

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        minterAllowed[_msgSender()] = mintingAllowedAmount.sub(_amount);
        emit Mint(_msgSender(), _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Throws if called by any account other than the masterMinter
    */
    modifier onlyMasterMinter() {
        require(_msgSender() == masterMinter, 'Only a master minter can call this function');
        _;
    }

    /**
     * @dev Get minter allowance for an account
     * @param minter The address of the minter
     */
    function minterAllowance(address minter) public view returns (uint256) {
        return minterAllowed[minter];
    }

    /**
     * @dev Checks if account is a minter
     * @param account The address to check
    */
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    /**
     * @dev Get allowed amount for an account
     * @param owner address The account owner
     * @param spender address The account spender
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * @dev Get totalSupply of token
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Adds blacklisted check to approve
     * @return True if the operation was successful.
    */
    function approve(address _spender, uint256 _value) whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(_spender) public returns (bool) {
        allowed[_msgSender()][_spender] = _value;
        emit Approval(_msgSender(), _spender, _value);
        return true;
    }

    /**
     * @dev Adds blacklisted & not paused check to increaseAllowance
     * @return True if the operation was successful.
    */
    function increaseAllowance(address _spender, uint256 _addedValue) whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(_spender) public returns (bool) {
        _approve(_msgSender(), _spender, allowed[_msgSender()][_spender].add(_addedValue));
        return true;
    }

    /**
     * @dev Adds blacklisted & not paused check to decreaseAllowance
     * @return True if the operation was successful.
    */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(_spender) public returns (bool) {
        _approve(_msgSender(), _spender, allowed[_msgSender()][_spender].sub(_subtractedValue));
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     */
    function _approve(address owner, address spender, uint256 value)  internal {
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return bool success
    */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused notBlacklisted(_to) notBlacklisted(_msgSender()) notBlacklisted(_from) public returns (bool) {
        require(_to != address(0), 'No `to` address');
        require(_value <= balances[_from], 'Not enough funds to make this request');
        require(_value <= allowed[_from][_msgSender()], 'you do not have access to transfer this much funds');

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][_msgSender()] = allowed[_from][_msgSender()].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return bool success
    */
    function transfer(address _to, uint256 _value) whenNotPaused notBlacklisted(_msgSender()) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0), 'No `to` address');
        require(_value <= balances[_msgSender()], 'Not enough funds to make this request');

        balances[_msgSender()] = balances[_msgSender()].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_msgSender(), _to, _value);
        return true;
    }

    /**
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
    */
    function configureMinter(address minter, uint256 minterAllowedAmount) whenNotPaused onlyMasterMinter public returns (bool) {
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
    */
    function removeMinter(address minter) onlyMasterMinter public returns (bool) {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param _amount uint256 the amount of tokens to be burned
    */
    function burn(uint256 _amount) onlyMinters notBlacklisted(_msgSender()) public {
        uint256 balance = balances[_msgSender()];
        require(_amount > 0, 'No `amount` to burn');
        require(balance >= _amount, 'Not enough funds to burn');

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_msgSender()] = balance.sub(_amount);
        emit Burn(_msgSender(), _amount);
        emit Transfer(_msgSender(), address(0), _amount);
    }

    /**
     * @dev allows the owner to update the master minter address
     * Validates that caller is an owner
     * @param _newMasterMinter the new master minter address
    */
    function updateMasterMinter(address _newMasterMinter) onlyOwner public {
        require(_newMasterMinter != address(0), 'No `master` address');
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

    /**
     * @dev allows the owner to update the gsnFee
     * Validates that caller is an owner
     * Validates _newGsnFee is not 0 and that its not more than two times old fee
     * @param _newGsnFee the new gnsFee
    */
    function updateGsnFee(uint256 _newGsnFee) onlyOwner public {
        require(_newGsnFee != 0, 'No `gsn` fee');
        require(_newGsnFee <= gsnFee.mul(2), 'New `gsn` fee is outrageous');
        uint256 oldFee = gsnFee;
        gsnFee = _newGsnFee;
        emit GSNFeeUpdated(oldFee, gsnFee);
    }

    /**
     * @dev "callback" to determine if a GSN call should be accepted
     * Validates that call is transfer, approve or transferFrom
     * Validates that user ANO balances is enough for the transaction + gsnFee
    */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory) {
        uint256 userBalance = balanceOf(from);

        bytes4 calldataSelector = LibBytes.readBytes4(encodedFunction, 0);

        if (calldataSelector == this.transfer.selector) {
            uint256 valuePlusGsnFee = gsnFee.add(uint(LibBytes.readBytes32(encodedFunction, 36)));

            if (userBalance >= valuePlusGsnFee) {
                return _approveRelayedCall(abi.encode(from));
            } else {
                return _rejectRelayedCall(uint256(GSNErrorCodes.INSUFFICIENT_BALANCE));
            }
        } else if (calldataSelector == this.transferFrom.selector || calldataSelector == this.approve.selector || calldataSelector == this.mint.selector 
                || calldataSelector == this.burn.selector || calldataSelector == this.configureMinter.selector || calldataSelector == this.removeMinter.selector 
                || calldataSelector == this.updateMasterMinter.selector || calldataSelector == this.updateGsnFee.selector) {
            if (userBalance >= gsnFee) {
                return _approveRelayedCall(abi.encode(from));
            } else {
                return _rejectRelayedCall(uint256(GSNErrorCodes.INSUFFICIENT_BALANCE));
            }
        } else {
            return _rejectRelayedCall(uint256(GSNErrorCodes.NOT_ALLOWED));
        }

    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {

    }

    /**
     * @dev "callback" to charge user gsnFee units of ANO after successful relayed call
    */
    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {
        address from = abi.decode(context, (address));

        balances[from] = balances[from].sub(gsnFee);
        balances[address(this)] = balances[address(this)].add(gsnFee);
        emit GSNFeeCharged(gsnFee, from);
    }

}

