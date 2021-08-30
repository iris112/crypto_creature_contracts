//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./interfaces/IGameSwapBEP20.sol";
import "./interfaces/IGameSwapPair.sol";
import "./interfaces/IGameSwapFactory.sol";
import "./interfaces/IBEP20.sol";
import "./library/SafeMath.sol";
import "./library/UQ112x112.sol";

contract GameSwapBEP20 is IGameSwapBEP20 {
    using SafeMath for uint256;

    string private constant _name = 'DWARF LPs';
    string private constant _symbol = 'DLP';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    bytes32 private _DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) private _nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function name() external override pure returns (string memory) {
        return _name;
    }

    function symbol() external override pure returns (string memory) {
        return _symbol;
    }

    function decimals() external override pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balanceOf[owner];
    }

    function nonces(address owner) external override view returns (uint256) {
        return _nonces[owner];
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowance[owner][spender];
    }

    function DOMAIN_SEPARATOR() external override view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function PERMIT_TYPEHASH() external override pure returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }

    function _mint(address to, uint256 value) internal {
        _totalSupply = _totalSupply.add(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(from != address(0), "GameSwapBEP20: transfer from the zero address");
        require(to != address(0), "GameSwapBEP20: transfer to the zero address");

        uint256 senderBalance = _balanceOf[from];
        require(senderBalance >= value, "GameSwapBEP20: transfer amount exceeds balance");

        _balanceOf[from] = senderBalance.sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        _transfer(from, to, value);

        uint256 currentAllowance = _allowance[from][msg.sender];
        require(currentAllowance >= value, "GameSwapBEP20: transfer amount exceeds allowance");
        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
                
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, 'GameSwapBEP20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'GameSwapBEP20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

contract GameSwapPair is IGameSwapPair, GameSwapBEP20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 private constant _MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address private _factory;
    address private _token0;
    address private _token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 private _price0CumulativeLast;
    uint256 private _price1CumulativeLast;
    uint256 private _kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'GameSwapPair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        _factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address token0_, address token1_) external override {
        require(msg.sender == _factory, 'GameSwapPair: FORBIDDEN'); // sufficient check
        _token0 = token0_;
        _token1 = token1_;
    }

    function MINIMUM_LIQUIDITY() external override pure returns (uint256) {
        return _MINIMUM_LIQUIDITY;
    }

    function factory() external override view returns (address) {
        return _factory;
    }

    function token0() external override view returns (address) {
        return _token0;
    }

    function token1() external override view returns (address) {
        return _token1;
    }

    function price0CumulativeLast() external override view returns (uint256) {
        return _price0CumulativeLast;
    }

    function price1CumulativeLast() external override view returns (uint256) {
        return _price1CumulativeLast;
    }

    function kLast() external override view returns (uint256) {
        return _kLast;
    }

    function getReserves()
    public
    override
    view
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'GameSwapPair: TRANSFER_FAILED');
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'GameSwapPair: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            _price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            _price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IGameSwapFactory(_factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 __kLast = _kLast; // gas savings
        if (feeOn) {
            if (__kLast != 0) {
                uint256 rootK = SafeMath.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = SafeMath.sqrt(__kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply().mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (__kLast != 0) {
            _kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IBEP20(_token0).balanceOf(address(this));
        uint256 balance1 = IBEP20(_token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = SafeMath.sqrt(amount0.mul(amount1)).sub(_MINIMUM_LIQUIDITY);
            _mint(address(0), _MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = SafeMath.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'GameSwapPair: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) _kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address __token0 = _token0; // gas savings
        address __token1 = _token1; // gas savings
        uint256 balance0 = IBEP20(__token0).balanceOf(address(this));
        uint256 balance1 = IBEP20(__token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'GameSwapPair: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(__token0, to, amount0);
        _safeTransfer(__token1, to, amount1);
        balance0 = IBEP20(__token0).balanceOf(address(this));
        balance1 = IBEP20(__token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) _kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'GameSwapPair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'GameSwapPair: INSUFFICIENT_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address __token0 = _token0;
            address __token1 = _token1;
            require(to != __token0 && to != __token1, 'GameSwapPair: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(__token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(__token1, to, amount1Out); // optimistically transfer tokens
            balance0 = IBEP20(__token0).balanceOf(address(this));
            balance1 = IBEP20(__token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'GameSwapPair: INSUFFICIENT_INPUT_AMOUNT');
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000**2),
                'GameSwapPair: K'
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address __token0 = _token0; // gas savings
        address __token1 = _token1; // gas savings
        _safeTransfer(__token0, to, IBEP20(__token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(__token1, to, IBEP20(__token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IBEP20(_token0).balanceOf(address(this)), IBEP20(_token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

contract GameSwapFactory is IGameSwapFactory {
    address private _feeTo;
    address private _feeToSetter;

    mapping(address => mapping(address => address)) private _getPair;
    address[] private _allPairs;
    bytes32 private constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(GameSwapPair).creationCode));

    constructor() {
        _feeToSetter = msg.sender;
        // default feeTo is feeToSetter
        _feeTo = _feeToSetter;
    }

    function feeTo() external override view returns (address) {
        return _feeTo;
    }

    function feeToSetter() external override view returns (address) {
        return _feeToSetter;
    }

    function getPair(address tokenA, address tokenB) external override view returns (address pair) {
        return _getPair[tokenA][tokenB];
    }

    function allPairs(uint256 index) external override view returns (address pair) {
        return _allPairs[index];
    }

    function allPairsLength() external override view returns (uint256) {
        return _allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'GameSwapFactory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'GameSwapFactory: ZERO_ADDRESS');
        require(_getPair[token0][token1] == address(0), 'GameSwapFactory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(GameSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IGameSwapPair(pair).initialize(token0, token1);
        _getPair[token0][token1] = pair;
        _getPair[token1][token0] = pair; // populate mapping in the reverse direction
        _allPairs.push(pair);
        emit PairCreated(token0, token1, pair, _allPairs.length);
    }

    function setFeeTo(address feeTo_) external override {
        require(msg.sender == _feeToSetter, 'GameSwapFactory: FORBIDDEN');
        _feeTo = feeTo_;
    }

    function setFeeToSetter(address feeToSetter_) external override {
        require(msg.sender == _feeToSetter, 'GameSwapFactory: FORBIDDEN');
        _feeToSetter = feeToSetter_;
    }
}
