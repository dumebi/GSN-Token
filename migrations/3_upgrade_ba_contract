
const { scripts, ConfigManager } = require('@openzeppelin/cli');

const { add, push, update } = scripts;

async function deploy(options) {
  add({ contractsData: [{ name: 'ANO', alias: 'ANO' }] });
  await push(options);
  await update(Object.assign({ contractAlias: 'ANO', methodName: 'initialize',
  methodArgs: [
    "Kolokodess", "KK", "NGN", 18, accounts[0], accounts[0], 10
  ] }, options));
}

module.exports = (deployer, networkName, accounts) => {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName })
    await deploy({ network, txParams })
  })
}