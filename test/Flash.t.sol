// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, WETH, DAI} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {Flash} from "@exercises/Flash.sol";

contract FlashTest is Test {
    IERC20 private constant dai = IERC20(DAI);
    IPool private constant pool = IPool(POOL);
    Flash private target;

    function setUp() public {
        // Funding this address with ETH
        deal(DAI, address(this), 1 ether);

        // deploy initator contract (target)
        target = new Flash();

        // approve ETH to initiator (for transferring fees)
        dai.approve(address(target), 1 ether);
    }

    function test_flash() public {

        uint256 initialbalance = dai.balanceOf(address(this));
        console.log("Initial Balance: ", initialbalance);

        vm.expectCall(
            address(pool),
            abi.encodeCall(
                pool.flashLoanSimple,
                (address(target), DAI, 1 ether, abi.encode(address(this)), 0)
            )
        );

        target.flash(DAI, 1 ether);

        console.log("Final Balance: ", dai.balanceOf(address(this)));

    }
}
