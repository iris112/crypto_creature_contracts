//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IBEP165.sol";
import "../interfaces/IBEP1155TokenReceiver.sol";
import "./Ownable.sol";
import "../library/SafeMath.sol";
import "../library/Address.sol";
import "../library/Strings.sol";
import "./ProxyRegistry.sol";

contract BEP1155Tradable is IBEP165, Ownable {
  using SafeMath for uint256;
  using Address for address;
  using Strings for string;
  
  struct NFTAttribute {
    uint256 pd; // Power Damage
    uint256 pk; // Power Kinetics
    uint256 ps; // Power Speed 
    uint256 pc; // Power Conversion
    uint256 ph; // Power Healing
    uint256 pave; // Power Average
  }
  
  bytes4 constant internal BEP1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal BEP1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
  bytes4 constant private INTERFACE_SIGNATURE_BEP165 = 0x01ffc9a7;
  bytes4 constant private INTERFACE_SIGNATURE_BEP1155 = 0xd9b67a26;

  mapping (address => mapping(uint256 => uint256)) internal balances;
  mapping (address => uint256) internal powers;
  
  mapping (uint256 => NFTAttribute) public settings;

  mapping (address => mapping(address => bool)) internal operators;
  
  string internal baseMetadataURI;

  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping(uint256 => address) public creators;
  mapping(uint256 => uint256) public tokenSupply;
  mapping(uint256 => uint256) public tokenMaxSupply;
  mapping(uint256 => uint256) public tokenPrice;
  mapping(address => bool) public isPool;

  string public name;
  string public symbol;
  
  modifier onlyLendingPool {
      require(
          isPool[msg.sender],
          "!lending pool"
      );
      _;
  }

  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _uri, uint256 indexed _id);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _newBaseMetadataURI
  )  {
    name = _name;
    symbol = _symbol;
    baseMetadataURI = _newBaseMetadataURI;
  }
  
  function setProxyRegistryAddress(address _proxyRegistryAddress)
    external onlyOwner
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    external
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "BEP1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"BEP1155#safeTransferFrom: INVALID_RECIPIENT");

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonBEP1155Received(_from, _to, _id, _amount, _data);
  }

  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    external
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "BEP1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "BEP1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonBEP1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }

  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    powers[_from] = powers[_from].mul(_amount.add(1)).sub(settings[_id].pave.mul(_amount));
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount
    powers[_to] = (powers[_to].add(settings[_id].pave.mul(_amount))).div(_amount.add(1));

    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  function _callonBEP1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    if (_to.isContract()) {
      bytes4 retval = IBEP1155TokenReceiver(_to).onBEP1155Received(msg.sender, _from, _id, _amount, _data);
      require(retval == BEP1155_RECEIVED_VALUE, "BEP1155#_callonBEP1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "BEP1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    uint256 nTransfer = _ids.length;

    for (uint256 i = 0; i < nTransfer; i++) {
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      powers[_from] = powers[_from].mul(_amounts[i].add(1)).sub(settings[_ids[i]].pave.mul(_amounts[i]));
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
      powers[_to] = (powers[_to].add(settings[_ids[i]].pave.mul(_amounts[i]))).div(_amounts[i].add(1));
    }

    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  function _callonBEP1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    if (_to.isContract()) {
      bytes4 retval = IBEP1155TokenReceiver(_to).onBEP1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
      require(retval == BEP1155_BATCH_RECEIVED_VALUE, "BEP1155#_callonBEP1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  function setApprovalForAll(address _operator, bool _approved)
    external
  {
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(address _owner, uint256 _id)
    external view returns (uint256)
  {
    return balances[_owner][_id];
  }

  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    external view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "BEP1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    uint256[] memory batchBalances = new uint256[](_owners.length);

    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }

  function supportsInterface(bytes4 _interfaceID) override external pure returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_BEP165 ||
        _interfaceID == INTERFACE_SIGNATURE_BEP1155) {
      return true;
    }
    return false;
  }

  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURL;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURL = string(abi.encodePacked(baseURL, Strings.uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURL, _tokenIDs[i]);
    }
  }

  function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
    require(_tokenIDs.length == _URIs.length, "BEP1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_URIs[i], _tokenIDs[i]);
    }
  }

  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }

  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    balances[_to][_id] = balances[_to][_id].add(_amount);
    powers[_to] = (powers[_to].add(settings[_id].pave.mul(_amount))).div(_amount.add(1));

    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    _callonBEP1155Received(address(0x0), _to, _id, _amount, _data);
  }

  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "BEP1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    uint256 nMint = _ids.length;

    for (uint256 i = 0; i < nMint; i++) {
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
      powers[_to] = (powers[_to].add(settings[_ids[i]].pave.mul(_amounts[i]))).div(_amounts[i].add(1));
    }

    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    _callonBEP1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
  }

  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    balances[_from][_id] = balances[_from][_id].sub(_amount);
    powers[_from] = powers[_from].mul(_amount.add(1)).sub(settings[_id].pave.mul(_amount));
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "BEP1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    uint256 nBurn = _ids.length;

    for (uint256 i = 0; i < nBurn; i++) {
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      powers[_from] = powers[_from].mul(_amounts[i].add(1)).sub(settings[_ids[i]].pave.mul(_amounts[i]));
    }

    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

  function uri(uint256 _id) external view returns (string memory) {
    require(_exists(_id), "BEP1155Tradable#uri: NONEXISTENT_TOKEN");
    return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "BEP1155Tradable#uri: NONEXISTENT_TOKEN");
    return Strings.strConcat(baseMetadataURI, Strings.uint2str(tokenId));
  }
  
  function contractURI() external view returns (string memory) {
    return Strings.strConcat(baseMetadataURI, "contractURI");
  }

  function totalSupply(uint256 _id) external view returns (uint256) {
    return tokenSupply[_id];
  }

  function maxSupply(uint256 _id) external view returns (uint256) {
    return tokenMaxSupply[_id];
  }
  
  function price(uint256 _id) external view returns (uint256) {
    return tokenPrice[_id];
  }

  function setBaseMetadataURI(string memory _newBaseMetadataURI) external onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }
  
  function powerOf(address account) public view returns (uint256) {
      return powers[account];
  }

  function create(
    uint256 _maxSupply,
    uint256 _price,
    uint256 pd, // Power Damage
    uint256 pk, // Power Kinetics
    uint256 ps, // Power Speed 
    uint256 pc, // Power Conversion
    uint256 ph // Power Healing
    
  ) external onlyOwner returns (uint256 tokenId) {
    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;
    tokenPrice[_id] = _price;
    tokenMaxSupply[_id] = _maxSupply;
    settings[_id].pd = pd;
    settings[_id].pk = pk;
    settings[_id].ps = ps;
    settings[_id].pc = pc;
    settings[_id].ph = ph;
    settings[_id].pave = (pd+pk+ps+pc+ph).div(5);
    return _id;
  }

  
  function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return operators[_owner][_operator];
  }

  function _exists(uint256 _id) internal view returns (bool) {
    return creators[_id] != address(0);
  }

  function _getNextTokenID() private view returns (uint256) {
    return _currentTokenID.add(1);
  }

  function _incrementTokenTypeId() private {
    _currentTokenID++;
  }
  
  function addLendingPool(address pool) external onlyOwner {
    isPool[pool] = true;
  }
  
  function delLendingPool(address pool) external onlyOwner {
    delete(isPool[pool]);
  }
  
  function isExist(uint256 _id) external view returns (bool) {
    return creators[_id] != address(0);
  }

  function mintTo(address _to, uint256 _tokenId) external onlyLendingPool  returns (uint256 _tokenPrice) {
    uint256 tokenId = _tokenId;
    require(tokenSupply[tokenId] < tokenMaxSupply[tokenId], "Max supply reached");
    balances[_to][tokenId] = balances[_to][tokenId].add(1);
    powers[_to] = (powers[_to].add(settings[tokenId].pave)).div(2);
    emit TransferSingle(msg.sender, address(0x0), _to, tokenId, 1);
    tokenSupply[tokenId] = tokenSupply[tokenId].add(1);
    return tokenPrice[tokenId];
  }
  
  function mint(uint256 _tokenId) external onlyOwner  returns (uint256 _tokenPrice) {
    uint256 tokenId = _tokenId;
    require(tokenSupply[tokenId] < tokenMaxSupply[tokenId], "Max supply reached");
    balances[msg.sender][tokenId] = balances[msg.sender][tokenId].add(1);
    powers[msg.sender] = (powers[msg.sender].add(settings[tokenId].pave)).div(2);
    emit TransferSingle(msg.sender, address(0x0), msg.sender, tokenId, 1);
    tokenSupply[tokenId] = tokenSupply[tokenId].add(1);
    return tokenPrice[tokenId];
  }
  
  function burn(address _from, uint256 _id, uint256 _amount) external {
    balances[_from][_id] = balances[_from][_id].sub(_amount);
    powers[_from] = powers[_from].mul(_amount.add(1)).sub(settings[_id].pave.mul(_amount));
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  function totalExist() external view returns (uint256) {
    return _currentTokenID;
  }
}