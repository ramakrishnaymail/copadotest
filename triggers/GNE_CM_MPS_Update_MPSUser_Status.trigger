/*
Test class: GNE_CM_MPS_Update_MPSUser_Status_Test
*/

trigger GNE_CM_MPS_Update_MPSUser_Status on GNE_CM_MPS_SIMS_User_Management__c (after update) 
{   
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_Update_MPSUser_Status'))
    {
        System.debug('Skipping trigger GNE_CM_MPS_Update_MPSUser_Status');
        return;
    }
	
    if(trigger.isUpdate)
    {
        Map<Id, String> userStatusMap = new Map<Id, String>();
        for(GNE_CM_MPS_SIMS_User_Management__c user : trigger.new)  
        {
            userStatusMap.put(user.MPS_User__c, user.Workflow_State__c);
        }
        
        List<GNE_CM_MPS_User__c> mpsUsers = [SELECT Id FROM GNE_CM_MPS_User__c WHERE Id IN : userStatusMap.keySet()];
        for(GNE_CM_MPS_User__c user : mpsUsers)
        {
            if(userStatusMap.get(user.Id) == 'ACTIVATION_EMAIL_SENT')
            {
                user.User_Status__c = 'Email Sent';
            }
            else if(userStatusMap.get(user.Id) == 'ACTIVATED')
            {
                user.User_Status__c = 'Active';
            }
            else if(userStatusMap.get(user.Id) == 'READY_FOR_PICKUP')
            {
                user.User_Status__c = 'Pending';
            }
            else if(userStatusMap.get(user.Id) == 'PICKED_UP')
            {
                user.User_Status__c = 'Pending';
            }
            else if(userStatusMap.get(user.Id) == 'SIMS_ERROR')
            {
                user.User_Status__c = 'Email Sent';
            }
            else if(userStatusMap.get(user.Id) == 'NO_ACTION_REQUIRED')
            {
                user.User_Status__c = 'Email Sent';
            }           
            else if(userStatusMap.get(user.Id) == 'REJECTED')
            {
                user.User_Status__c = 'Rejected';
            }
            else if(userStatusMap.get(user.Id) == 'APPLICATION_ADDED')
            {
                user.User_Status__c = 'Active';
            }
            else if(userStatusMap.get(user.Id) == 'ACTIVATION_LINK_EXPIRED')
            {
                user.User_Status__c = 'Expired';
            } 
            else if(userStatusMap.get(user.Id) == 'MIGRATED')
            {
                user.User_Status__c = 'Active';
            }          
        }
        update mpsUsers;    
    }
}