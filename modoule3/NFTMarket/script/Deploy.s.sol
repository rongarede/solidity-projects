pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "../src/MyCollectible.sol";
import "../src/NFTMarketDutchAuction.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        MyCollectible nft = new MyCollectible("NFT", "NFT", "https://api.example.com/");
        NFTMarketDutchAuction market = new NFTMarketDutchAuction();
        
        vm.stopBroadcast();
    }
}