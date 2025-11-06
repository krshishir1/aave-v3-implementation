include .env

build:
	forge build

NETWORK_ARGS := --fork-url $(MAINNET_RPC_URL) 

# Run tests (add verbosity with V=1)
testing-borrow:
	forge test --mt test_approxMaxBorrow $(NETWORK_ARGS) -vvv

testing-2:
	forge test --mt test_approxMaxBorrow $(NETWORK_ARGS) -vvv

testing-loan:
	forge test --mt test_flash $(NETWORK_ARGS) -vvv

testing-supply:
	forge test --mt test_supply $(NETWORK_ARGS) -vvv

