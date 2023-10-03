-include .env

clean  :; forge clean

compile :; forge compile

build:; forge build

test :; forge test

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk'

deploy :; PRIVATE_KEY=${PRIVATE_KEY} ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY} INFURA_ID=${INFURA_ID} node scripts/deploy.js ${network}

deploy-anvil :; make deploy network=anvil

deploy-mainnet :; make deploy network=mainnet

deploy-goerli :; make deploy network=goerli
