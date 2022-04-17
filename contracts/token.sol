pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Doge is ERC20 {

    constructor() ERC20("Doge", "DOGE"){
        _mint(msg.sender, 100000);
    }
}