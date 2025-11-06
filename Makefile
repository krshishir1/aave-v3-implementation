include .env

build:
	forge build

# Run tests (add verbosity with V=1)
testing:
	forge test --mt test_approxMaxBorrow --fork-url $(MAINNET_RPC_URL) -vvv

testing-2:
	forge test --mt test_approxMaxBorrow --fork-url $(MAINNET_RPC_URL) -vv