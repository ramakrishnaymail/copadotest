trigger GNE_CM_IHCP_UserName_Unique_Trigger on GNE_CM_IHCP_User__c (before insert, before update) 
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_IHCP_UserName_Unique_Trigger'))
    {
        System.debug('Skipping trigger GNE_CM_IHCP_UserName_Unique_Trigger');
        return;
    }

    List<String> changedNames = new List<String>();
    for(GNE_CM_IHCP_User__c u : trigger.new)
    {
    	if(trigger.isUpdate)
    	{
	        if(trigger.newMap.get(u.Id).Name != trigger.oldMap.get(u.Id).Name)
	        {
	            changedNames.add(u.Name);
	        }
    	}    
    	else if(trigger.isInsert)
    	{
    		changedNames.add(u.Name);
    	}    
    }
    
    Set<String> existingNames = new Set<String>();
    for(GNE_CM_IHCP_User__c u : [SELECT Name FROM GNE_CM_IHCP_User__c WHERE Name IN: changedNames])
    {
    	existingNames.add(u.Name);    	
    }
    
    for(GNE_CM_IHCP_User__c u : trigger.new)
    {
    	if(existingNames.contains(u.Name))
    	{
    		u.addError('IHCP User Name must be unique.');
    	}
    }
}