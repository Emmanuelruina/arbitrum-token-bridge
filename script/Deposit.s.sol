// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2024 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.21;

import "forge-std/Script.sol";

import { ScriptTools } from "dss-test/ScriptTools.sol";
import { Domain } from "dss-test/domains/Domain.sol";
import { RetryableTickets } from "script/utils/RetryableTickets.sol";

interface GemLike {
    function approve(address, uint256) external;
}

interface GatewayLike {
    function outboundTransfer(
        address l1Token,
        address to,
        uint256 amount,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (bytes memory);
    function getOutboundCalldata(
        address l1Token,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) external pure returns (bytes memory);
}

// Test deployment in config.json
contract Deposit is Script {
    using stdJson for string;

    function run() external {
        string memory config = ScriptTools.readInput("config"); // loads from FOUNDRY_SCRIPT_CONFIG
        string memory deps = ScriptTools.loadDependencies(); // loads from FOUNDRY_SCRIPT_DEPS
        
        Domain l1Domain = new Domain(config, getChain(string(vm.envOr("L1", string("mainnet")))));
        Domain l2Domain = new Domain(config, getChain(vm.envOr("L2", string("arbitrum_one"))));
        l1Domain.selectFork();
       
       (,address deployer, ) = vm.readCallers();
        address l1Gateway = deps.readAddress(".l1Gateway");
        address l2Gateway = deps.readAddress(".l2Gateway");
        address nst = deps.readAddress(".l1Nst");
        RetryableTickets retryable = new RetryableTickets(l1Domain, l2Domain, l1Gateway, l2Gateway);

        uint256 amount = 1 ether;
        bytes memory finalizeDepositCalldata = GatewayLike(l1Gateway).getOutboundCalldata({
            l1Token: nst, 
            from:    deployer,
            to:      deployer, 
            amount:  amount,
            data:    ""
        });
        uint256 maxGas = retryable.getMaxGas(finalizeDepositCalldata) * 150 / 100;
        uint256 gasPriceBid = retryable.getGasPriceBid() * 200 / 100;
        uint256 maxSubmissionCost = retryable.getSubmissionFee(finalizeDepositCalldata) * 250 / 100;
        uint256 l1CallValue = maxSubmissionCost + maxGas * gasPriceBid;

        vm.startBroadcast();
        GemLike(nst).approve(l1Gateway, type(uint256).max);
        GatewayLike(l1Gateway).outboundTransfer{value: l1CallValue}({
            l1Token:     nst, 
            to:          deployer, 
            amount:      amount, 
            maxGas:      maxGas, 
            gasPriceBid: gasPriceBid,
            data:        abi.encode(maxSubmissionCost, bytes(""))
        });
        vm.stopBroadcast();
    }
}