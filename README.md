# LOAN

## leveraged loan on BASE, which combines uniswap V3 + aave V3

##### new pair permission from the protocol is required.

#### available pairs:

WETH/USDC

# CODING IN PROGRESS~~~~~~~

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
