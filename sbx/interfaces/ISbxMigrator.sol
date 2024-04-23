// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISbxMigrator {
    function iouTokens(address _token) external view returns (address);
}
