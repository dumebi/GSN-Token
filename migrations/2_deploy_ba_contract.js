/* eslint-disable no-undef */
// const ExchangeContract = artifacts.require('./Exchange');
// const libExchangeFuncContract = artifacts.require('./ExchangeFunc');
// const libExchangeStructContract = artifacts.require('./ExchangeStruct');
// // const safemathContract = artifacts.require('./SafeMath');
// // const tokenICOContract = artifacts.require('./tokenICO');

// module.exports = (deployer) => {
//   deployer.then(async () => {
//     // await deployer.deploy(safemathContract);
//     await deployer.deploy(libExchangeStructContract);
//     await deployer.deploy(libExchangeFuncContract);

//     await deployer.link(libExchangeStructContract, ExchangeContract);
//     await deployer.link(libExchangeFuncContract, ExchangeContract);
//     await deployer.deploy(ExchangeContract);

//     // await deployer.link(libExchangeStructContract, tokenICOContract);
//     // await deployer.link(libExchangeFuncContract, tokenICOContract);
//     // await deployer.deploy(
//     //   tokenICOContract,
//     //   12345,
//     //   10,
//     //   5000000
//     // );
//   })
// }


const { scripts, ConfigManager } = require('@openzeppelin/cli');

const { add, push, create } = scripts;

async function deploy(options, accounts) {
  add({ contractsData: [{ name: 'ANO', alias: 'ANO' }] });
  await push(options);
  await create(Object.assign({ contractAlias: 'ANO', methodName: 'initialize',
  methodArgs: [
    "Kolokodess", "KK", "NGN", 18, accounts[0], accounts[0], accounts[0], accounts[0], 10, 50000000000
  ] }, options));
}

module.exports = (deployer, networkName, accounts) => {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName })
    await deploy({ network, txParams }, accounts)
  })
}
