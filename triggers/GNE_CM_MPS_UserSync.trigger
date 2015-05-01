trigger GNE_CM_MPS_UserSync on GNE_CM_MPS_User__c (after insert, after update)
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_UserSync'))
    {
        System.debug('Skipping trigger GNE_CM_MPS_UserSync');
        return;
    }    
    
    
    // only do the update if we really have a change...
    List<GNE_CM_MPS_User__c> mpsUsers2Update=new List<GNE_CM_MPS_User__c>();
    
    for (GNE_CM_MPS_User__c mpsUser : Trigger.New)
    {
    	if (mpsUser.SFDC_User__c!=null && mpsUser.Email_address__c!=null) 
    	{
	    	if (Trigger.isUpdate) 
	    	{
	    		String oldEmail = Trigger.oldMap.get(mpsUser.Id).Email_address__c;
	    		oldEmail=(oldEmail!=null ? oldEmail : '');
	    		
	    		if (oldEmail!=mpsUser.Email_address__c) 
	    		{
	    			mpsUsers2Update.add(mpsUser);
	    		}
	    	} 
	    	else 
	    	{
	    		mpsUsers2Update.add(mpsUser);
	    	}
    	}
    }
    
    if (mpsUsers2Update.size()>0) 
    {
    	GNE_CM_IHCP_Utils.updateUserContactEmails(GNE_CM_IHCP_Utils.getUserId2EmailMap(mpsUsers2Update)); 
    }   
}