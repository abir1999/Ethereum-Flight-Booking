// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running deployWithWeb3 script...')
        //account 1 address: 0xE3bd93ad9Ca94542650cE836DE61Cb22510c17c2
        //account 2 address: 0xe352AF04A336c1ca96945Ca07d0b651Ae0075558
        // const contractName = 'Insurance' // Change this for other contract
        let addr1 = '0xE3bd93ad9Ca94542650cE836DE61Cb22510c17c2'
        const constructorArgs = [addr1]    // Put constructor args (if any) here for your contract
    
        // Note that the script needs the ABI which is generated from the compilation artifact.
        // Make sure contract is compiled and artifacts are generated
        const artifactsPath = `browser/contracts/artifacts/Insurance.json` // Change this for different path

        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath))
        const accounts = await web3.eth.getAccounts()
    
        let contract = new web3.eth.Contract(metadata.abi)
        
        contract = contract.deploy({
            from:accounts[0],
            data: metadata.data.bytecode.object,
            arguments: constructorArgs
        })
    
        const newContractInstance = await contract.send({
            from: accounts[0],
        })
        console.log('Contract deployed at address: ', newContractInstance.options.address)
    } catch (e) {
        console.log(e.message)
    }
  })()