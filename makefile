-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil initiateVote

# Default network is anvil/localhost. Override with make deploy NETWORK=sepolia
NETWORK ?= anvil

# Network-specific configurations
ifeq ($(NETWORK),anvil)
	RPC_URL := http://localhost:8545
	PRIVATE_KEY := $(DEFAULT_ANVIL_KEY)
else
	RPC_URL := $($(NETWORK)_RPC_URL)
	PRIVATE_KEY := $($(NETWORK)_PRIVATE_KEY)
endif

# Addresses
ADMIN_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
CEO_CHAIN_CONTRACT_ADDRESS := 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
CANDIDATE1 := 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
CANDIDATE2 := 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
CANDIDATE3 := 0x90F79bf6EB2c4f870365E785982E1f101E93b906

# Network configuration
NETWORK_ARGS := --rpc-url $(RPC_URL) --private-key $(DEFAULT_ANVIL_KEY) 

help:
	@echo "Usage:"
	@echo "  make deploy [NETWORK=network_name]\n    example: make deploy NETWORK=sepolia"
	@echo "  make fund [NETWORK=network_name]\n    example: make fund NETWORK=sepolia"
	@echo "  make initiateVote [NETWORK=network_name]\n    example: make initiateVote NETWORK=sepolia"
	@echo "\nAvailable targets:"
	@echo "  all          - Clean, remove, install, update, and build"
	@echo "  clean        - Clean the repo"
	@echo "  install      - Install dependencies"
	@echo "  test         - Run tests"
	@echo "  deploy       - Deploy the contract"
	@echo "  initiateVote - Initiate voting with candidates"
	@echo "  anvil        - Start local Anvil chain"

all: clean remove install update build

# Clean the repo
clean:
	forge clean

# Remove modules
remove:
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:
	forge install https://github.com/foundry-rs/forge-std.git --no-commit && forge install cyfrin/foundry-devops --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit 

update:
	forge update

build:
	forge build

test:
	forge test

snapshot:
	forge snapshot

format:
	forge fmt

anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy: 
	@forge script script/CeoChainDeployer.s.sol:CeoChainDeployer $(NETWORK_ARGS) --sig "run(address)" $(ADMIN_ADDRESS) --broadcast

# Admin Functionallity
## 1
initiateVote: 
	@forge script script/Interactions.s.sol:InitateVoteScript $(NETWORK_ARGS) \
		--sig "run(address[],address)" \
		[$(CANDIDATE1),$(CANDIDATE2),$(CANDIDATE3)] \
		$(ADMIN_ADDRESS) --broadcast

## 3
approveToWhitelist:
	@forge script script/Interactions.s.sol:ApproveToWhiteListScript $(NETWORK_ARGS) \
		--sig "run(address,address)" $(CANDIDATE1) $(ADMIN_ADDRESS) --broadcast
	
removeFromWhitelist:
	@forge script script/Interactions.s.sol:RemoveFromWhiteListScript $(NETWORK_ARGS) \
		--sig "run(address,address)" $(CANDIDATE1) $(ADMIN_ADDRESS) --broadcast

# Voter Functionallity
## 2
applyToWhitelist:
	@forge script script/Interactions.s.sol:ApplyToWhiteListScript $(NETWORK_ARGS) \
		--sig "run(address,address)" $(CANDIDATE1) $(ADMIN_ADDRESS) \
		$(ADMIN_ADDRESS) --broadcast

castVote:
	@forge script script/Interactions.s.sol:CastVoteScript $(NETWORK_ARGS) \
		--sig "run(address,address)" $(CANDIDATE1) $(CANDIDATE1) --broadcast

finaliseVote:
	@forge script script/Interactions.s.sol:FinaliseVoteScript $(NETWORK_ARGS) \
		--sig "run()" --broadcast
