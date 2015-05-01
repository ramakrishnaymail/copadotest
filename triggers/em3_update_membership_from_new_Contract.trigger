trigger em3_update_membership_from_new_Contract on Speaker_Contract_gne__c (after insert) {
    //List to hold all the contract records
    List<Speaker_Contract_gne__c> contracts = new List<Speaker_Contract_gne__c>();      

    set<ID> contract_accounts = new set<ID>();
    
    //Iterate through contracts in this trigger saving the account id's to the set  
    for(Speaker_contract_gne__c cont : trigger.new){
        if(cont.Contracted_Party_ID__c != null){
            contract_accounts.add(cont.Contracted_Party_ID__c);
        }
    }
    
    set<ID>related_accounts = new set<ID>();
    
    //retrieve all membership's in which the Account is equal to one in the previously created set
    for(Speaker_Bureau_Membership_gne__c memberships : [select id, Bureau_Member_gne__c from 
    Speaker_Bureau_Membership_gne__c where Bureau_Member_gne__c IN :contract_accounts]){
        related_accounts.add(memberships.Bureau_Member_gne__c);
    }   
    
    //for all contracts in the trigger, if the contract has a related account add the contract to
    //the list of contracts to update
    for(Speaker_contract_gne__c cont : trigger.new){
        if(cont.Contracted_Party_ID__c != null && related_accounts.contains(cont.Contracted_party_ID__c)){          
            contracts.add(cont);            
        }
    }   
    
    em3_update_membership_status.contracted_status(contracts, related_accounts);    
}