(async () => {

    try {
    //account 1 (insurance provider) address: 0xE3bd93ad9Ca94542650cE836DE61Cb22510c17c2
    //account 2 address: 0xe352AF04A336c1ca96945Ca07d0b651Ae0075558
    
    //change contract address before running script
    const contractAddress = '0x3eC46E36096c90F2f5a6a339c34b79318835F616'
    console.log('start exec')
    
    const artifactsPath = `browser/contracts/artifacts/Insurance.json` // Change this for different path
    const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath))
    const accounts = await web3.eth.getAccounts()
    
    let contract = new web3.eth.Contract(metadata.abi, contractAddress)
    
    //Setup variables to call verify, and to pay_indemnity
    const weather = await remix.call('fileManager', 'readFile', 'browser/scripts/weather.txt')
    const weather_data = weather.split('\r');
    let dates=[];
    let cities=[];
    let w_conditions=[];
    let num_to_pay=0;

    //now read each line of weather and prepare 3 arrays (dates, cities, weather conditions)
    for(let i=1; i<weather_data.length; i++){
        const details = weather_data[i].split(' ')
        dates.push(String(details[0]).trim());
        cities.push(details[1]);
        w_conditions.push(details[2]);
    }

    //Now call verify to check how many passengers need to pay:
    let result = await contract.methods.verify(dates, cities, w_conditions).send({from: accounts[0]});
    console.log(result);

    //Now get # of passengers that will receive indemnity
    await contract.methods.get_numIndemnity().call(function (err, result) {
        if (err){
            console.log("An error occured", err)
            return
        } else {
            console.log("Num passengers to pay: ", result)
            num_to_pay = result;
        }
    })

    //Finally call pay_indemnity() with the appropriate value, to pay the passengers:
    let result_pay = await contract.methods.pay_indemnity().send({from: accounts[0], value: num_to_pay*20000000000000000});
    console.log(result_pay);

    } catch (e) {
        console.log("Contract Access failed!")
    }
  })()

