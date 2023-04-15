pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPancakeRouter.sol";
import "./IBiswapRouter.sol";
import "./FlashLoanReceiverBase.sol";

contract FlashLoanArbitrage is FlashLoanReceiverBase {
    IPancakeRouter public pancakeRouter;
    IBiswapRouter public biswapRouter;
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(
        address _equalizerFlashLoanPool,
        address _pancakeRouter,
        address _biswapRouter,
        address _tokenA,
        address _tokenB
    ) FlashLoanReceiverBase(_equalizerFlashLoanPool) {
        pancakeRouter = IPancakeRouter(_pancakeRouter);
        biswapRouter = IBiswapRouter(_biswapRouter);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function startArbitrage(uint256 amount) external {
        require(isArbitrageProfitable(amount), "Arbitrage not profitable");

        bytes memory data = ""; // No additional data is needed for this example
        flashLoan(tokenA, amount, data);
    }

    function isArbitrageProfitable(uint256 amount) public view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory pancakeSwapAmounts = pancakeRouter.getAmountsOut(amount, path);
        uint256 tokenBAmount = pancakeSwapAmounts[1];

        uint256[] memory biswapAmounts = biswapRouter.getAmountsOut(tokenBAmount, path);
        uint256 tokenAReceived = biswapAmounts[1];

        uint256 flashLoanRepayment = amount + (amount * flashLoanFeeBps) / 10000;

        return tokenAReceived > flashLoanRepayment;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external override {
        require(msg.sender == address(pool), "Unauthorized caller");

        // Approve token allowance to routers
        tokenA.approve(address(pancakeRouter), amount);
        tokenA.approve(address(biswapRouter), amount);

        // Swap tokenA for tokenB on PancakeSwap
        address[] memory pathPancake = new address[](2);
        pathPancake[0] = address(tokenA);
        pathPancake[1] = address(tokenB);

        pancakeRouter.swapExactTokensForTokens(amount, 0, pathPancake, address(this), block.timestamp + 600);

        uint256 tokenBBalance = tokenB.balanceOf(address(this));

        // Swap tokenB back to tokenA on Biswap
        address[] memory pathBiswap = new address[](2);
        pathBiswap[0] = address(tokenB);
        pathBiswap[1] = address(tokenA);

        biswapRouter.swapExactTokensForTokens(tokenBBalance, 0, pathBiswap, address(this), block.timestamp + 600);

        uint256 tokenABalanceAfterArbitrage = tokenA.balanceOf(address(this));

        // Repay the flash loan and fees
        uint256 flashLoanRepayment = amount + fee;
        require(tokenABalanceAfterArbitrage >= flashLoanRepayment, "Not enough profit to repay flash loan");

        tokenA.transfer(address(pool), flashLoanRepayment);

        // Transfer remaining profit to the owner
        uint256 profit = tokenA.balanceOf(address(this));
        tokenA.transfer(msg.sender, profit);
    }
}