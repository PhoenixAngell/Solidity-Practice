pragma solidity 0.8.0;

import "./OpenZeppelinDependencies/ERC20.sol";
import "./OpenZeppelinDependencies/AccessControlEnumerable.sol";
import "./OpenZeppelinDependencies/Context.sol";
import "./OpenZeppelinDependencies/Pausable.sol";
import "./OpenZeppelinDependencies/SafeMath.sol";

contract PhoenixCoin is ERC20, AccessControlEnumerable, Pausable {
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant CAP_ROLE = keccak256("CAP_ROLE");

  uint256 private _cap;

  constructor(uint256 cap_, uint256 amount_) ERC20( "PhoenixCoin", "PNX") {

    //_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    _setupRole(CAP_ROLE, _msgSender());

    require(cap_ > 0, "ERC20Capped: cap is 0");
      _cap = cap_;
    require(amount_ <= cap_, "Amount exceeds cap");
    _mint(msg.sender, amount_);
  }


  function increaseCap(uint256 _amount) public whenNotPaused {
      require(hasRole(CAP_ROLE, _msgSender()), "Token: Must have cap role to increase cap");
      _increaseCap(_amount);
  }

  function decreaseCap(uint256 _amount) public whenNotPaused {
      require(hasRole(CAP_ROLE, _msgSender()), "Token: Must have cap role to decrease cap");
      _decreaseCap(_amount);
  }

  function _increaseCap(uint256 _amount) internal {
      _cap += _amount;
      assert(cap() >= totalSupply());
  }

  function _decreaseCap(uint256 _amount) internal {
      _cap -= _amount;
      require(cap() >= totalSupply(), "Cap cannot be smaller than total supply");
  }


//Checks the current cap;
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

//Checks the current circulating supply;
    function totalSupply() public view virtual override returns (uint256) {
        return ERC20.totalSupply();
    }

    function mint(address account, uint256 amount) public whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(account, amount);
    }



    function transfer(address recipient, uint256 amount) public virtual override(ERC20) whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

}
