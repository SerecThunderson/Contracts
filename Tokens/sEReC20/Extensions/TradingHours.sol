// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../sEReC20.sol";

contract TradingHours is sEReC20 {

    constructor(string memory name_, string memory symbol_, uint decimals_, uint supply_) 
        sEReC20(name_, symbol_, decimals_, supply_) {}

    modifier onlyDuringTradingHours() {
        // 14:30:00 to 21:00:00 corresponds to 9:30 AM - 4:00 PM ET in UTC time
        require(block.timestamp % 86400 >= 14 * 3600 + 30 * 60 && block.timestamp % 86400 <= 21 * 3600, "Not trading hours");
        
        // Assuming that Sunday = 0, Monday = 1, ..., Saturday = 6
        // Trading days are Monday (1) to Friday (5)
        uint dayOfWeek = (block.timestamp / 86400 + 4) % 7;  // +4 because 1970-01-01 was a Thursday
        require(dayOfWeek >= 1 && dayOfWeek <= 5, "Not a business day");
        _;
    }

    function transfer(address to, uint amount) public virtual override onlyDuringTradingHours returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint amount) public virtual override onlyDuringTradingHours returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
