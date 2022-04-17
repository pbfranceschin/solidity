pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';

contract Wallet is Ownable{
    using SafeMath for uint256;

    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }
    mapping(bytes32 => Token) public tokenMapping;
    bytes32[] public tokenList;

    mapping(address => mapping(bytes32 => uint256)) public balances;

    function addToken(bytes32 _ticker, address _tokenAddress) external onlyOwner() {
        tokenMapping[_ticker] = Token(_ticker, _tokenAddress);
        tokenList.push(_ticker);
    }

    function depositEth() external payable {
        balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(msg.value);
    }

    function withdrawEth(uint amount) external payable {
        require(balances[msg.sender]["ETH"] >= amount, "Wallet: insufficient balance");
        balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(amount);
        payable(msg.sender).transfer(amount);
    }
    function deposit(uint amount, bytes32 ticker) external {
        require(tokenMapping[ticker].tokenAddress != address(0), "Wallet: token not supported");
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
               
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
    }

    function withdraw(uint amount, bytes32 ticker) external {
        require(tokenMapping[ticker].tokenAddress != address(0));
        require(balances[msg.sender][ticker] >= amount, "Wallet: insufficient funds");

        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    event tradeMade(address buyer, address seller, bytes32 ticker, uint amountETH, uint amountToken);

    function _trade ( address buyer, address seller , bytes32 ticker, uint amountETH, uint amountToken ) internal{
        balances[ buyer ][ "ETH" ] = balances[ buyer ][ "ETH" ].sub(amountETH);
        balances[ buyer ][ ticker ] = balances[ buyer ][ ticker ].add(amountToken);
        balances[ seller ][ ticker ] = balances[ seller ][ ticker ].sub(amountToken);
        balances[ seller ][ "ETH" ] = balances[ seller ][ "ETH" ].add(amountETH);
        emit tradeMade(buyer, seller, ticker, amountETH, amountToken);
    }
}