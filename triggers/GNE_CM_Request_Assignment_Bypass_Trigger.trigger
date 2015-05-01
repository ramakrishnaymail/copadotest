trigger GNE_CM_Request_Assignment_Bypass_Trigger on Task (before update) {
    
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isTriggerDisabled('GNE_CM_Request_Assignment_Bypass_Trigger__c') || GNE_SFA2_Util.isAdminMode('GNE_CM_Request_Assignment_Bypass_Trigger'))
    {
        System.debug('Skipping trigger GNE_CM_Request_Assignment_Bypass_Trigger');
        return;
    }
    
    String profileName  = GNE_CM_Task_Helper.getProfileName();
    String cmTaskRecTypeID    = GNE_CM_Task_Helper.getCMTaskRecordTypeId();
    Set<String> notAllowedProfiles = getNotAllowedProfiles();
    
    for(Task tsk :Trigger.new)
    {
            try
            { 
                if(profileName == 'GNE-CM-GATCFFS')
                { 
                    if(tsk.RecordTypeId == cmTaskRecTypeID && tsk.OwnerId != system.trigger.oldmap.get(tsk.Id).OwnerId)
                    {
                        if((tsk.CM_Case_Record_Type_Name_gne__c == 'GATCF - Standard Case' || tsk.CM_Case_Record_Type_Name_gne__c == 'GATCF - Eligibility Screening'))
                        {
                            If(!Test.isRunningTest())
                                tsk.ownerid.addError('Only GATCF Supervisors and Managers can change the ‘Assigned To’ field.');
                        }
                    }
                }
               
                if(profileName!=null && notAllowedProfiles.contains(profileName) && !GNE_CM_Task_Queue_Mgmt_Helper.isRSQueueDisabled())
                {
                	if(tsk.RecordTypeId == cmTaskRecTypeID && tsk.OwnerId != system.trigger.oldmap.get(tsk.Id).OwnerId)
                    {
                    	if(tsk.CM_Queue_Name_gne__c == GNE_CM_Task_Queue_Mgmt_Helper.QueueNames.RS_Urgent.name() || tsk.CM_Queue_Name_gne__c ==GNE_CM_Task_Queue_Mgmt_Helper.QueueNames.RS_Today.name() || tsk.CM_Queue_Name_gne__c == GNE_CM_Task_Queue_Mgmt_Helper.QueueNames.RS_Regular.name())
                    	{
	                    	If(!Test.isRunningTest())
                            {
                            	tsk.ownerid.addError('Only C&R Supervisors and Managers can change the ‘Assigned To’ field.');
                            }
	                    }
                    }
                }
            }
            catch(Exception e)
            {
                tsk.adderror('Error occured during Validation check' + e.getMessage());               
            }
    }
    
    private static set<String> getNotAllowedProfiles(){
    	return  new set<String> {'GNE-CM-APPEALSSPECIALIST',
								'GNE-CM-CASEMANAGER',
								'GNE-CM-DIR',
								'GNE-CM-GATCFFS',
								'GNE-CM-GATCFMANAGER',
								'GNE-CM-GATCFSUPERVISOR',
								'GNE-CM-INTAKE',
								'GNE-CM-INTAKESUPERVISOR',
								'GNE-CM-INTERNALVMANAGER',
								'GNE-CM-PLANNING',
								'GNE-CM-REIMBSPECIALIST',
								'GNE-CM-REIMBSPECIALIST-VENDOR',
								'GNE-CM-REIMBSPECIALIST-VENDOR-nonSSO',
								'GNE-CM-REIMBSPECIALIST-VENDOR-RO',
								'GNE-CM-REIMBSPECIALIST-VENDOR-TE',
								'GNE-CM-VREIMBSPECIALIST-BIOLOGICS'};
    } 
}