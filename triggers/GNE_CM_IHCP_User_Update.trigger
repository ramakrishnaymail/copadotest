trigger GNE_CM_IHCP_User_Update on GNE_CM_IHCP_User__c (after update) 
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_IHCP_User_Update'))
    {
        System.debug('Skipping trigger GNE_CM_IHCP_User_Update');
        return;
    }
	
	List<GNE_CM_IHCP_User__c> ihcpUsers = [Select Email_Address__c,SFDC_User__c from GNE_CM_IHCP_User__c 
	                                                 where ID IN :Trigger.newMap.keySet()];
	Map<ID, String> mapIhcpUserEmails = new Map<ID, String>();                                            
	for(GNE_CM_IHCP_User__c ihcpUser: ihcpUsers)
	{
		mapIhcpUserEmails.put(ihcpUser.SFDC_User__c,String.valueof(ihcpUser.Email_Address__c));
	}
	//mps user update
	List<GNE_CM_MPS_User__c> mpsUsers = [Select Email_address__c, SFDC_User__r.ID from GNE_CM_MPS_User__c 
	                                                 WHERE SFDC_User__c IN (SELECT Id FROM User WHERE ID IN :mapIhcpUserEmails.keySet())];
	for(GNE_CM_MPS_User__c mpsUser: mpsUsers)
	{
		mpsUser.Email_address__c = mapIhcpUserEmails.get(mpsUser.SFDC_User__r.ID); 
	}
	if(!mpsUsers.IsEmpty())
		update mpsUsers;
	//lwo user update - disabled
	/* 
	List<GNE_LWO_User__c> lwoUsers = [Select Email_address__c, SFDC_User__r.ID from GNE_LWO_User__c 
	                                                 WHERE SFDC_User__c IN (SELECT Id FROM User WHERE ID IN :mapIhcpUserEmails.keySet())];
	for(GNE_LWO_User__c lwoUser: lwoUsers)
	{
		lwoUser.Email_address__c = mapIhcpUserEmails.get(lwoUser.SFDC_User__r.ID); 
	}
	if(!lwoUsers.IsEmpty())
		update lwoUsers;
		*/
}