// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract SBLP is MintableBaseToken {
    constructor() public MintableBaseToken("SBLP", "SBLP", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "SBLP";
    }
}
