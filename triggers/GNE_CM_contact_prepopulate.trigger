trigger GNE_CM_contact_prepopulate on Contact (before insert, before update) 
{    
    // SFA2 bypass
    if(GNE_SFA2_Util.isAdminMode()) {
        return;
    }

    Set<String> environmentVariableKeys = new Set<String>{'GNE_CM_Account_Record_Types', 'GNE_CM_ProfileList', 'GNE_CM_contact_primary_account'};
    Map<String, List<Environment_Variables__c>> envVarMultiValues = GlobalUtils.populateEnvVariables(environmentVariableKeys);
    Set<String> accountRTSet = new Set<String>();
    Map<Id, Account> accounts = new Map<Id, Account>();     
    Profile currentProfile = [SELECT name FROM Profile WHERE id =: UserInfo.getProfileId()];
    Boolean profileMatch = false;   
    Set<Id> contactsAddress = new Set<Id>();    
    Map<Id, Address_vod__c> addresses = new Map<Id, Address_vod__c>();
    Map<Id, Id> contactToAccountMap = new Map<Id, Id>();
    Public string PrimaryAccId='';
      System.debug('----------value of environment variables is --------'+envVarMultiValues);
    //Start KC 10/5/11. CMR3 - Bug fixes: Added the below line of code not to execute this trigger for gFRS profiles.
    if (envVarMultiValues.size() == 0)
        return;
    //End    
    for(Environment_Variables__c envVar : envVarMultiValues.get('GNE_CM_Account_Record_Types'))
    {
        accountRTSet.add(envVar.value__c);
    }   
    //KC emergency fix for SFA canada project: 11/21/11
    for(Environment_Variables__c envVar : envVarMultiValues.get('GNE_CM_contact_primary_account'))
    {
        PrimaryAccId = envVar.value__c;
        system.debug('Primary acc id'+PrimaryAccId);
    }   
    
    // creating set for comparing the profile type condition
    for(Environment_Variables__c envVar : envVarMultiValues.get('GNE_CM_ProfileList'))
    {
        if(currentProfile.name.startswith(envVar.Value__c))
        {
            profileMatch = true;
            break;
        }
    }
    
    if(profileMatch == true)
    {
        // adding the curent address to the set
        for(Contact con : trigger.new)
        {
            if(con.Address_gne__c != null)
            {
                contactsAddress.add(con.Address_gne__c);
            }
        }

        if(contactsAddress.size() > 0)
        {
            try
            {            
                addresses = new Map<Id, Address_vod__c>([SELECT Account_vod__c, Account_vod__r.recordtype.name,Account_vod__r.recordtype.ispersontype from Address_vod__c where Id IN: contactsAddress]);            
            }
            catch(exception e)
            {
                for(Contact cont : trigger.new)
                {
                    cont.adderror('Error occured in querying addresses of Contact ' + e.getmessage());
                }
            }
        }

        if(trigger.isInsert)
        {
            for(Contact con : trigger.new)
            {
                if(con.Address_gne__c != null && addresses.keySet().contains(con.Address_gne__c))                
                { 
                    contactToAccountMap.put(con.Id, addresses.get(con.Address_gne__c).Account_vod__c);
                }                
                // for cloning a contact & other record types                
                else if(con.accountid != null && con.Address_gne__c == null)                
                {                       
                    contactToAccountMap.put(con.Id, con.accountid);
                }                
                else if(con.HCP_gne__c != null && con.Address_gne__c == null)                
                {                       
                    contactToAccountMap.put(con.Id, con.HCP_gne__c);                    
                }
                
                if(contactToAccountMap.size() == 0)
                {
                    con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                }
            }
            
            if(contactToAccountMap.size() > 0)
            {
                accounts = new Map<Id, Account>([select id, name, recordType.Name from Account where id IN : contactToAccountMap.values()]);
                for(Contact con : trigger.new)
                {                   
                    if(contactToAccountMap.get(con.Id) != null && accountRTSet.contains(accounts.get(contactToAccountMap.get(con.Id)).recordType.Name))
                    {
                        // checking if the user is trying to modify contact details.
                        if(con.Address_gne__c == null)
                        {
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        } 
                        //KC : 11/21/11: commented out as part of SFA Canada emergency fix.
                        /*else if(con.accountid != contactToAccountMap.get(con.Id) && con.accountid != null)
                        {
                            con.addError('This field [Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                        }*/ 
                        else if(con.HCP_gne__c != contactToAccountMap.get(con.Id) && con.HCP_gne__c != null)
                        {
                            con.addError('This field [HCP Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                        }
                        
                    }                   
                }
                
                for(Contact con : trigger.new)
                {
                    try
                    {   
                        //setting HCP Name/HCO Name during new contact creation
                        if(con.Address_gne__c != null && addresses.containsKey(con.Address_gne__c))
                        {
                            if(addresses.get(con.Address_gne__c).Account_vod__c != null)
                            {
                                if(addresses.get(con.Address_gne__c).Account_vod__r.recordtype.ispersontype == true)
                                {
                                    con.HCP_gne__c = addresses.get(con.Address_gne__c).Account_vod__c;
                                    con.accountid = PrimaryAccId;
                                    //KC commented on 11/21/11 as emergenc fix for SFA Canada issue.
                                    // error message, if the user is trying to populate both the account name fields.
                                    /*if(con.accountid != null)
                                    {
                                        con.addError('This field [Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                                    }*/
                                }
                                else if(addresses.get(con.Address_gne__c).Account_vod__r.recordtype.ispersontype == false)
                                {
                                    con.accountid = addresses.get(con.Address_gne__c).Account_vod__c;
                                    if(con.HCP_gne__c != null)
                                    {
                                        con.addError('This field [HCP Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                                    }
                                }
                            }
                        }
                    }
                    catch(Exception e)
                    {
                        con.adderror('Error occured in filling account information in Contact ' + e.getmessage());
                    }
                }
            }
            
        }
        
        if(trigger.isUpdate)
        {           
            for(Contact con : trigger.new)
            {

                if(trigger.oldMap.get(con.Id).AccountId != null)
                {
                    contactToAccountMap.put(con.Id, trigger.oldMap.get(con.Id).AccountId);
                }
                else if(trigger.oldMap.get(con.Id).HCP_gne__c != null)
                {
                    contactToAccountMap.put(con.Id, trigger.oldMap.get(con.Id).HCP_gne__c);
                }
            
            }
            
            accounts = new Map<Id, Account>([SELECT id, recordtypeid, Record_Type_Name_gne__c FROM Account WHERE id IN : contactToAccountMap.values()]);
            
            for(Contact con : trigger.new)
            {
                // checking for account record type
                if(accounts.size() > 0 && contactToAccountMap.get(con.Id) != null && accountRTSet.contains(accounts.get(contactToAccountMap.get(con.Id)).Record_Type_Name_gne__c))
                {
                    try
                    {
                        if(con.Address_gne__c == null)
                        {
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        }
                        else if((con.HCP_gne__c != trigger.oldMap.get(con.Id).HCP_gne__c) && (con.Accountid != trigger.oldMap.get(con.Id).Accountid) && (con.Address_gne__c != trigger.oldMap.get(con.Id).Address_gne__c))
                        {
                            system.debug('inside point 1');
                            con.addError('These fields [HCP Name/Name] are not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        }
                        else if((con.HCP_gne__c != trigger.oldMap.get(con.Id).HCP_gne__c) && (con.Accountid != trigger.oldMap.get(con.Id).Accountid ))
                        {
                            system.debug('inside point 2');
                            con.addError('These fields [HCP Name/Name] are not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                        }
                        else if((con.HCP_gne__c != trigger.oldMap.get(con.Id).HCP_gne__c) && (con.Address_gne__c != trigger.oldMap.get(con.Id).Address_gne__c))
                        {
                            system.debug('inside point 3');
                            con.addError('These fields [HCP Name/Address] are not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        }
                        else if((con.Accountid != trigger.oldMap.get(con.Id).Accountid) && (con.Address_gne__c != trigger.oldMap.get(con.Id).Address_gne__c))
                        {
                            system.debug('inside point 4');
                            con.addError('--point 4 ---This field [Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        }
                        else if(con.HCP_gne__c != trigger.oldMap.get(con.Id).HCP_gne__c) //&& trigger.oldMap.get(con.Id).HCP_gne__c != null)
                        {
                            system.debug('inside point 5');
                            con.addError('This field [HCP Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                        }
                        else if(con.Accountid != Trigger.oldMap.get(con.Id).Accountid)// && (con.Name == null))
                        {
                            system.debug('inside point 6');
                            con.addError('This field [Name] is not modifiable. Your update will not be saved. Press Cancel to remove change and continue.');
                        }
                        else if (con.Address_gne__c != trigger.oldMap.get(con.Id).Address_gne__c)
                        {
                            system.debug('inside point 7');
                            con.addError('The Address alignment cannot be modified or manually entered on a Contact. If the Contact you are editing/creating has no Address aligned, please create a new Contact from the Address level.');
                        }
                    }
                    catch(exception e)
                    {
                        con.adderror('Error process Contact Address Validation ' + e.getmessage());
                    }

                }
            }
        }
    }
}