//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    //Price of one Crypto Dev Token
    uint256 public constant tokenPrice = 0.001 ether;
    //Each NFT would give the user 10 tokens
    //It needs to be represented as 10 * 10 **18 as ERC20 token are represented by the smallest denomination possible for the token
    //By default ERC20 tokens have the smallest denomination of 10^(-18). This means having the balance of 1 is actually 10^(-18) tokens.
    //Owning 1 full token is equivalent to owning 10^18 tokens when you account for the decimal places
    uint256 public constant tokensPerNFT = 10 * 10**18;

    //the max total supply is 10000 for Crypto Dev Tokens;
    uint256 public constant maxTotalSupply = 10000 * 10**18;

    //CryptoDevNFT contract instance
    ICryptoDevs CryptoDevNFT;

    //Mapping to keep track of which tokenIds have been claimed
    mapping(uint256 => bool) public tokenIdsClaimed;

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevNFT = ICryptoDevs(_cryptoDevsContract);
    }

    /**
     *@dev Mints `amount` number of CrypotDevTokens
     *Requirements:
     *- `msg.value` should be equal or greater than the tokenPrice * amount
     */
    function mint(uint256 amount) public payable {
        //the value of ether that should be equal or greater than tokenPrice * amount;
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is not correct");

        uint256 amountWithDecimals = amount * 10**18;

        require(
            totalSupply() + amountWithDecimals <= maxTotalSupply,
            "Exceeds the max supply available"
        );

        _mint(msg.sender, amountWithDecimals);
    }

    /**
    *@dev Mints tokens based on the number of NFTs held by the sender
    *Requirements:
    * balance of Crypto Dev NFT's owned by the sender should be greater than 0
    * Tokens should have not been claimed for all the NFTs owned by the sender
     */
    function claim() public {
        address sender = msg.sender;
        //Get the number of CryptoDev NFTs held by the sender
        uint256 balance = CryptoDevNFT.balanceOf(sender);
        //If the balance is zero, revert the transaction
        require(balance > 0, "You don't own any Crypto Dev NFT");

        //amount keeps tracks of number of unclaimed tokenIds
        uint256 amount = 0;
        //loop over the balance and get the token ID owned by `sender` at a given `index` of its token list.
        for(uint256 i = 0; i < balance; i++){
            uint256 tokenId = CryptoDevNFT.tokenOfOwnerByIndex(sender, i);
            //if the tokenId has not been claimed, increase the amount
            if(!tokenIdsClaimed[tokenId]){
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }
        //If all the token Ids have been claimed, revert the transaction;
        require(amount > 0, "You have already claimed all the tokens");
        //call the internal function from Openzeppelin's ERC20 contract
        //Mint(amount * 10) tokens for each NFT
        _mint(msg.sender, amount * tokensPerNFT);
    }
    //Function to receive Ether. msg.data must be empty
    receive() external payable{}

    //Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
