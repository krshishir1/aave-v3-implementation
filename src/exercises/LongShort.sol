// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Aave} from "../lib/Aave.sol";
import {Swap} from "../lib/Swap.sol";
import {Math} from "../lib/Math.sol";

// NOTE: Don't use this contract in production.
// Any caller can borrow on behalf of this contract and withdraw collateral from this contract.

contract LongShort is Aave, Swap {
    error HealthFactor_Invalid();
    error HealthFactor_SwapInvalid();

    struct OpenParams {
        address collateralToken;
        uint256 collateralAmount;
        address borrowToken;
        uint256 borrowAmount;
        // Minimum health factor after borrowing token
        uint256 minHealthFactor;
        uint256 minSwapAmountOut;
        // Arbitrary data to be passed to the swap function
        bytes swapData;
    }

    // Approve this contract to pull in collateral
    // Approve this contract to borrow
    // Task 1 - Open a long or a short position
    function open(
        OpenParams memory params
    ) public returns (uint256 collateralAmountOut) {
        // Task 1.1 - Check that params.minHealthFactor is greater than 1e18
        if (params.minHealthFactor < 1e18) {
            revert HealthFactor_Invalid();
        }

        // Task 1.2 - Transfer collateral from msg.sender
        IERC20(params.collateralToken).transferFrom(
            msg.sender,
            address(this),
            params.collateralAmount
        );

        // Task 1.3
        // - Approve and supply collateral to Aave
        // - Send aToken to msg.sender
        IERC20(params.collateralToken).approve(
            address(pool),
            params.collateralAmount
        );
        supply(params.collateralToken, params.collateralAmount, msg.sender);
        // _transferAToken(params.collateralToken, address(this), msg.sender);

        // Task 1.4
        // - Borrow token from Aave
        // - Borrow on behalf of msg.sender
        borrow(params.borrowToken, params.borrowAmount, msg.sender);

        _printBalance(
            params.collateralToken,
            params.borrowToken,
            address(this)
        );
        _printBalance(params.collateralToken, params.borrowToken, msg.sender);

        // Task 1.5 - Check that health factor of msg.sender is > params.minHealthFactor
        if (getHealthFactor(msg.sender) < params.minHealthFactor) {
            revert HealthFactor_SwapInvalid();
        }

        // Task 1.6
        // - Swap borrowed token to collateral token
        IERC20(params.borrowToken).approve(
            address(router),
            params.borrowAmount
        );
        collateralAmountOut = swap({
            tokenIn: params.borrowToken,
            tokenOut: params.collateralToken,
            amountIn: params.borrowAmount,
            amountOutMin: params.minSwapAmountOut,
            receiver: msg.sender,
            data: params.swapData
        });

        _printBalance(
            params.collateralToken,
            params.borrowToken,
            address(this)
        );
        _printBalance(params.collateralToken, params.borrowToken, msg.sender);

        // uint256 balance = IERC20(params.collateralToken).balanceOf(
        //     address(this)
        // );
        // IERC20(params.collateralToken).transfer(
        //     msg.sender,
        //     collateralAmountOut
        // );
        // - Send swapped token to msg.sender

        // _printBalance(
        //     params.collateralToken,
        //     params.borrowToken,
        //     address(this)
        // );
        // _printBalance(params.collateralToken, params.borrowToken, msg.sender);

        // console.log(IERC20())
    }

    struct CloseParams {
        address collateralToken;
        uint256 collateralAmount;
        uint256 maxCollateralToWithdraw;
        address borrowToken;
        uint256 maxDebtToRepay;
        uint256 minSwapAmountOut;
        // Arbitrary data to be passed to the swap function
        bytes swapData;
    }

    // Approve this contract to pull in collateral AToken
    // Approve this contract to pull in collateral
    // Approve this contract to pull in borrowed token if closing at a loss
    // Task 2 - Close a long or a short position
    function close(
        CloseParams memory params
    )
        public
        returns (
            uint256 collateralWithdrawn,
            uint256 debtRepaidFromMsgSender,
            uint256 borrowedLeftover
        )
    {
        // Task 2.1 - Transfer collateral from msg.sender into this contract
        // Task 2.2 - Swap collateral to borrowed token
        // Task 2.3
        // - Repay borrowed token
        // - Amount to repay is the minimum of current debt and params.maxDebtToRepay
        // - If the amount to repay is greater that the amount swapped,
        //   then transfer the difference from msg.sender
        // Task 2.4 - Withdraw collateral to msg.sender
        // Task 2.5 - Transfer profit = swapped amount - repaid amount
        // Task 2.6 - Return amount of collateral withdrawn,
        //            debt repaid and profit from closing this position
    }

    function _transferAToken(
        address baseToken,
        address user,
        address recipient
    ) internal {
        address aToken = getATokenAddress(baseToken);
        IERC20(aToken).transfer(recipient, getATokenBalance(baseToken, user));
    }

    function _printBalance(
        address collateralToken,
        address borrowToken,
        address user
    ) internal view {
        console.log(
            IERC20(collateralToken).balanceOf(user),
            IERC20(borrowToken).balanceOf(user)
        );
    }
}
