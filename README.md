# LOAN

## leveraged loan on BASE, which combines uniswap V3 + aave V3

##### new pair permission from the protocol is required.

#### available pairs:

WETH/USDC

# CODING IN PROGRESS~~~~~~~

## Such as liquidation service, limit order, batch limit order etc~

## Developed functionalities

### openLong:

##### Uniswap: quoteToken(USDC) flashswap--> baseToken(WETH)

##### Aave: 拿到 swap 得来的 baseToken(WETH)，抵押，借出 quoteToken

##### Uniswap: 还款 quoteToken

##### 结果: 更多的 baseToken(WETH) 存于 Aave，欠 Aave 一部分 quoteToken(USDC)

### openShort:

##### Uniswap: baseToken(WETH) flashswap--> quoteToken(USDC)

##### Aave: 拿到 swap 得来的 quoteToken(USDC)，抵押，借出 baseToken(WETH)

##### Uniswap: 还款 baseToken(WETH)

##### 结果: 更多的 quoteToken(USDC) 存于 Aave，欠 Aave 一部分 baseToken(WETH)

### closeLong:

##### Uniswap: baseToken(WETH) flashswap--> quoteToken(USDC)

##### Aave: 拿到 swap 得来的 quoteToken(USDC)，全部还给 aave

##### Aave: 取出作为保证金的所有 baseToken(WETH)

##### Uniswap: 还款 baseToken(WETH)

##### 结果: 资金全部换回 baseToken

### closeShort:

##### Uniswap: quoteToken(USDC) flashswap--> baseToken(WETH)

##### Aave: 拿到 swap 得来的 baseToken(WETH)，全部还给 aave

##### Aave: 取出作为保证金的所有 quoteToken(USDC)

##### Uniswap: 还款 quoteToken(USDC)

##### 结果: 资金全部换回 quoteToken

## First deploy on Sepolia:

### CustodianImpl [0x899284c788db37f8fb276a8d1c0cc25a069b2a5b](https://sepolia.etherscan.io/address/0x899284c788db37f8fb276a8d1c0cc25a069b2a5b)

### Beacon [0x53e2d352d174248eba9321783d3ac2ac26c21092](https://sepolia.etherscan.io/address/0x53e2d352d174248eba9321783d3ac2ac26c21092)

### FactoryImpl [0x937384879c2d00a01bbae6582b4121c9df571905](https://sepolia.etherscan.io/address/0x937384879c2d00a01bbae6582b4121c9df571905)

### Factory [0xbb4154dac8de1a5648a834165e58b638f461097b](https://sepolia.etherscan.io/address/0xbb4154dac8de1a5648a834165e58b638f461097b)

### ProxyAdmin [0x56b8c95a04ab7fbd485cbdd791fa73c0f676cd4c](https://sepolia.etherscan.io/address/0x56b8c95a04ab7fbd485cbdd791fa73c0f676cd4c)
