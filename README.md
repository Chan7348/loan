# loan

leveraged loan on BASE, which combines uniswap V3 + aave V3

new pair permission from the protocol is required.

available pairs:
WETH/USDC

CODING IN PROGRESS~~~~~~~

1. 无任何仓位，此时可以 openLong, openShort, 禁止 closeLong, closeShort
2. 有long仓位，此时可以 closeLong, 禁止 openLong, openShort, closeShort, closeShort
3. 有short仓位，此时可以 closeShort, 禁止 openLong, openShort, closeLong

openLong 需要的情况，无任何仓位
openShort 需要的情况，无任何仓位
closeLong 需要的情况，有Long，无Short
closeShort 需要的情况，有Short, 无Long