// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, WETH} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {Supply} from "@exercises/Supply.sol";

contract SupplyTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IPool private constant pool = IPool(POOL);
    IERC20 private aWeth;
    Supply private target;

    function setUp() public {
        // Get aWETH address
        IPool.ReserveData memory reserve = pool.getReserveData(WETH);
        aWeth = IERC20(reserve.aTokenAddress);  // => collateral token shares address

        deal(WETH, address(this), 1 ether); // transfer 1 ether to this address
        target = new Supply(); // initiator contract
    }

    function test_supply() public {
        uint256 wethBalBefore = weth.balanceOf(address(this));
        weth.approve(address(target), 1 ether); // approve the initiator
        target.supply(WETH, 1 ether);
        uint256 wethBalAfter = weth.balanceOf(address(this));

        assertEq(
            wethBalBefore - wethBalAfter, 1e18, "WETH balance of test contract"
        );
        assertEq(weth.balanceOf(address(target)), 0, "WETH balance of target");
        assertGt(aWeth.balanceOf(address(target)), 0, "aWETH balance of target");
        assertEq(
            target.getSupplyBalance(WETH),
            aWeth.balanceOf(address(target)),
            "Supply balance"
        );
    }
}
