trigger GNE_CM_EBI_TransactionStagingStatusUpdate on GNE_CM_EBI_Transaction_Staging__c (after update) 
{
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_EBI_TransactionStagingStatusUpdate')) {
        system.debug('TRIGGER SKIPPED');
        return;
    }
    
	Set<Integer> ebiRequests = new Set<Integer>();
	for(GNE_CM_EBI_Transaction_Staging__c tran : trigger.new)	
	{
		if(tran.Migration_Status_tech_gne__c != trigger.oldMap.get(tran.Id).Migration_Status_tech_gne__c && 
			tran.Migration_Status_tech_gne__c == 'Not Started' &&
			trigger.oldMap.get(tran.Id).Migration_Status_tech_gne__c == 'Failed')
		{
			ebiRequests.add((Integer)tran.eBI_Request_Number_gne__c);
		}
	}
	
	List<GNE_CM_EBI_Transaction_Staging__c> transactions2Update = [SELECT Id FROM GNE_CM_EBI_Transaction_Staging__c WHERE eBI_Request_Number_gne__c IN: ebiRequests];
	
	for(GNE_CM_EBI_Transaction_Staging__c tran : transactions2Update)
	{
		tran.Migration_Status_tech_gne__c = 'Not Started';
	}
	GNE_SFA2_Util.setTriggerDisabled('GNE_CM_EBI_TransactionStagingStatusUpdate', true);
	update transactions2Update;
}