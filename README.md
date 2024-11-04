# loan

leveraged loan on BASE, which combines uniswap V3 + aave V3

new pair permission from the protocol is required.

available pairs:
WETH/USDC

CODING IN PROGRESS~~~~~~~

存款：用户将两种 token 之一 存到本协议中(允许 base/quote 同时贮存在协议中)
取款：用户将两种 token 之一 从本协议中取回(允许同时取回两种)

开仓：用户存入本协议的所有 base/quote 保证金都会被 supply 到 aave 当中，然后进行 flashswap
关仓：还款以从 aave 拿回用户的保证金，并存到协议中

1. 无任何仓位，此时可以 openLong, openShort, 禁止 closeLong, closeShort
2. 有 long 仓位，此时可以 closeLong, 禁止 openLong, openShort, closeShort, closeShort
3. 有 short 仓位，此时可以 closeShort, 禁止 openLong, openShort, closeLong

openLong 需要的情况，无任何仓位
openShort 需要的情况，无任何仓位
closeLong 需要的情况，有 Long，无 Short
closeShort 需要的情况，有 Short, 无 Long

deposit 过程：
拉取 token 至 address(this)，然后向 aave pool supply(), 获得 aToken

openLong:
先检查是否有 aToken

openShort:
先检查是否有 aToken

withdraw 过程:(progressing)
