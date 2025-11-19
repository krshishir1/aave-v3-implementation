// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, ORACLE, WETH, DAI} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {IAaveOracle} from "../src/interfaces/aave-v3/IAaveOracle.sol";
import {Liquidate} from "@exercises/Liquidate.sol";

contract LiquidateTest is Test {
    IERC20 private constant weth = IERC20(WETH); // collateral token
    IERC20 private constant dai = IERC20(DAI); // debt token
    IPool private constant pool = IPool(POOL); // aave pool to handle everything
    IAaveOracle private constant oracle = IAaveOracle(ORACLE);

    Liquidate private target; // deployed contract instance

    function setUp() public {
        // Supply
        deal(WETH, address(this), 1 ether); // mint 1 ether to this contract
        weth.approve(address(pool), type(uint256).max);

        pool.supply({
            asset: WETH,
            amount: 1 ether,
            onBehalfOf: address(this),
            referralCode: 0
        }); // supply collateral to pool

        // Borrow
        vm.mockCall(
            ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(uint256(2000 * 1e8))
        ); // mock call for 1 WETH = 2000 usd

        pool.borrow({
            asset: DAI,
            amount: 1000 * 1e18,
            interestRateMode: 2,
            referralCode: 0,
            onBehalfOf: address(this)
        }); // 1000 DAI borrowed

        _printCollateralAndDebt(1);

        uint256 ethPrice = 500 * 1e8;

        vm.mockCall(
            ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(ethPrice)
        ); // mock call for 1 WETH = 500 usd

        target = new Liquidate();

        // Approve target to spend DAI
        deal(DAI, address(this), 10000 * 1e18);
        dai.approve(address(target), 10000 * 1e18);
    }

    /*
        1. Supply 1 ether. ETH price 2000, so collateral balance = 2000 usd.
        2. Borrow 1000 DAI. 
        3. Now ETH price = 500, so collateral = 500 usd
        4. Time to liquidate!
     */

    function test_liquidate() public {
        (uint256 colUsdBefore, uint256 debtUsdBefore, , , , ) = pool
            .getUserAccountData(address(this));

        _printCollateralAndDebt(2);

        target.liquidate(WETH, DAI, address(this));

        (uint256 colUsdAfter, uint256 debtUsdAfter, , , , ) = pool
            .getUserAccountData(address(this));

        _printCollateralAndDebt(3);

        assertLt(colUsdAfter, colUsdBefore, "USD collateral after");
        assertLt(debtUsdAfter, debtUsdBefore, "USD debt after");

        uint256 wethBal = weth.balanceOf(address(target));
        console.log("WETH balance: %e", wethBal);
        assertGt(wethBal, 0, "WETH balance");
    }

    function _printCollateralAndDebt(uint8 index) internal view {
        (uint256 colUsd, uint256 debtUsd, , , , ) = pool.getUserAccountData(
            address(this)
        );

        console.log(index, "Assets balance: ", colUsd, debtUsd);
    }
}
