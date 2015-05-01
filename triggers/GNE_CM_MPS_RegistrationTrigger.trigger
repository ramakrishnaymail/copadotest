trigger GNE_CM_MPS_RegistrationTrigger on GNE_CM_MPS_Registration__c (before update) 
{
    Id guestOwnerId = null;
    List<User> usersList = [select Id from User where Name = 'Practice Registration Site Guest User' limit 1];
    if(usersList != null && usersList.size() > 0)
    {
    	guestOwnerId = usersList[0].Id;
    }
    
    if(guestOwnerId != null)
    {
	    if(trigger.isUpdate && trigger.isBefore)
	    {
	        for(GNE_CM_MPS_Registration__c reg :trigger.new)
	        {
		    	if(trigger.oldMap.get(reg.id) != null &&
		    	   trigger.newMap.get(reg.id) != null &&
		    	   trigger.oldMap.get(reg.id).Registration_Status__c == 'Submitted' &&
		    	   trigger.newMap.get(reg.id).Registration_Status__c == 'Draft')
		    	   {
		    	   		trigger.newMap.get(reg.id).Registration_Status__c = 'Submitted';
		    	   }
		    	if(trigger.oldMap.get(reg.id) != null)
		    	{
	            	reg = GNE_CM_MPS_Registration_Utils.changeRegistrationStatus(reg, trigger.oldMap.get(reg.id), guestOwnerId);
		    	}
	        }
	    }
    }
}