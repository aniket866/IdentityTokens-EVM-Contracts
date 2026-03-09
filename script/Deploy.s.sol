// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { IdentityToken } from "../src/IdentityToken.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract Deploy is Script {
    function run() external returns (IdentityToken, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        uint256 deployerKey = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Deploy the MVP contract
        IdentityToken identityToken = new IdentityToken();

        vm.stopBroadcast();

        console.log("IdentityToken deployed at:", address(identityToken));

        return (identityToken, helperConfig);
    }
}
