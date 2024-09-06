// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
contract Insurance{

    address payable public ins_provider;
    uint private premium = 10000000000000000;
    uint private indemnity = 20000000000000000;

    //used to manually add funds to the contract. (no need to use it if a value is entered correctly)
    receive() external payable {}
    fallback() external payable{}

    struct Policy { 
        string pass_name;
        address payable pass_address;
        string flight_no;
        string flight_date;
        string departure_city;
        string destination_city;
        string policy_status;
    }

    event newCustomer(address customer_address, string name, string flight_no, string flight_date, string departure_city, string destination_city, string status);

    address[] private customer_list;
    address[] private indemnity_list;
    uint256 private num_indemnity;

    mapping (address => Policy) private policy_list;

    modifier OnlyPassenger {
        require(
            msg.sender != ins_provider,
            "Only a passenger can perform this action!"
        );
        _;
    }

    modifier OnlyProvider {
        require(
            msg.sender == ins_provider,
            "Only the insurance provider can perform this action!"
        );
        _;
    }

    constructor(address payable _ins_provider){
        ins_provider = _ins_provider;
    }

    //This function allows a customer to purchase a policy
    function purchase_policy(string calldata name, string calldata _flight_no, string calldata _flight_date, 
                            string calldata _departure_city, string calldata _destination_city) external payable OnlyPassenger{

        //Setup struct with the buyer's address
        policy_list[msg.sender] = Policy(name, payable(msg.sender), _flight_no, _flight_date, _departure_city, _destination_city, "Purchased");
        //add the customer's address to the list of customers (to use during iteration)
        customer_list.push(msg.sender);
        //transfer premium to the insurance provider
        ins_provider.transfer(premium);
        
    }

    //This function allows anyone to see the offered policy
    function view_available_policy() external pure returns(string memory){
        return "Policy Premium = 0.01ETH , Indemnity = 0.02ETH , Coverage: Extreme Weather(Hail or Flood)";
    }

    //This function allows a customer to view their purchased policy
    function view_purchased_policy() external view OnlyPassenger returns(string memory name, string memory flight_no, string memory flight_date, 
                            string memory departure_city, string memory destination_city, string memory policy_status){
        Policy memory mypolicy = policy_list[msg.sender];
        return (mypolicy.pass_name, mypolicy.flight_no, mypolicy.flight_date, mypolicy.departure_city, mypolicy.destination_city, mypolicy.policy_status);
    }

    //This function does an event emit of all the items in the policy list. String return was too annoying
    function view_all_policies() external OnlyProvider{
        uint len = customer_list.length;
        address customer;
        uint i;
        for ( i = 0; i<len; i++) 
        {
            customer = customer_list[i];
            emit newCustomer(customer, policy_list[customer].pass_name, policy_list[customer].flight_no, policy_list[customer].flight_date, 
            policy_list[customer].departure_city, policy_list[customer].destination_city, policy_list[customer].policy_status);
        }
    }

    //This function goes through all the customer policies and 
    //adds to a list of customers that will get indemnity (that are not already claimed)
    function verify(string[] calldata date, string[] calldata city, string[] calldata weather) public OnlyProvider{

        uint len = customer_list.length;
        address customer;
        uint i; uint j;
        uint check = 0; //this variable becomes 3 if all criteria are met for a passenger's flight. Then add them to idemnity list
        uint num_tests = date.length;

        for( j = 0; j<num_tests;j++){
            check = 0;
            for ( i = 0; i<len; i++) 
            {
                customer = customer_list[i];        
                if( keccak256(abi.encodePacked(policy_list[customer].policy_status)) != keccak256(abi.encodePacked("Claimed")) ){
                    //now check if date, city and weather all match.
                    if(keccak256(abi.encodePacked(policy_list[customer].flight_date)) == keccak256(abi.encodePacked(date[j]))){ check++; }
                    if(keccak256(abi.encodePacked(policy_list[customer].departure_city)) == keccak256(abi.encodePacked(city[j]))){ check++; }
                    if(check == 2){
                        //now check weather
                        if(keccak256(abi.encodePacked(weather[j])) == keccak256(abi.encodePacked("Hail")) || keccak256(abi.encodePacked(weather[j])) == keccak256(abi.encodePacked("Flood")) ){
                            check++;
                        }  
                    }
                }
                //if all criteria meet, add it to list of customers who get indemnity
                if(check==3){
                    indemnity_list.push(customer);
                    num_indemnity++;
                }
                check = 0;
            }

        }

    }

    function get_numIndemnity() public view returns (uint256){
        return num_indemnity;
    }

    //This function pays customers in the indemnity_list and then finally removes them from the list
    function pay_indemnity() public payable{

        uint len = indemnity_list.length;
        address customer;

        //go backwards in the array (so that we can use push() to remove after payment)
        while(len>0){
            //get address of customer
            customer = indemnity_list[len-1];
            //transaction
            payable(customer).transfer(indemnity);
            //set their policy to "Claimed"
            policy_list[customer].policy_status = "Claimed";
            //remove from list
            indemnity_list.pop();
            //get new length
            len = indemnity_list.length;
            //reduce value of num_indemnity
            num_indemnity--;
        }
    }

}
