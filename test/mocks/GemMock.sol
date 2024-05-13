// SPDX-License-Identifier: AGPL-3.0-or-later

/// Ngt.sol -- Ngt token

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
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

contract GemMock {
    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply;

    constructor(uint256 initialSupply) {
        mint(msg.sender, initialSupply);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "Gem/insufficient-balance");

        unchecked {
            balanceOf[msg.sender] = balance - value;
            balanceOf[to] += value;
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 balance = balanceOf[from];
        require(balance >= value, "Gem/insufficient-balance");

        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "Gem/insufficient-allowance");

                unchecked {
                    allowance[from][msg.sender] = allowed - value;
                }
            }
        }

        unchecked {
            balanceOf[from] = balance - value;
            balanceOf[to] += value;
        }
        return true;
    }

    function mint(address to, uint256 value) public {
        unchecked {
            balanceOf[to] = balanceOf[to] + value;
        }
        totalSupply = totalSupply + value;
    }

    function burn(address from, uint256 value) external {
        uint256 balance = balanceOf[from];
        require(balance >= value, "Gem/insufficient-balance");

        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "Gem/insufficient-allowance");

                unchecked {
                    allowance[from][msg.sender] = allowed - value;
                }
            }
        }

        unchecked {
            balanceOf[from] = balance - value;
            totalSupply     = totalSupply - value;
        }
    }
}