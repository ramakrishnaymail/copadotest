trigger GNE_CM_AS_Post_Processing on Alternative_Funding_gne__c (after insert) 
{
    /*List<Task> tsk_list = new List<Task>();
    List<Error_Log_gne__c> errorLogList = new List<Error_Log_gne__c>();
    String errMessage = '';
    Database.saveresult[] SR;
    Id CoPayCardRecTypeId = Schema.SObjectType.Alternative_Funding_gne__c.getRecordTypeInfosByName().get('Co-Pay Card').getRecordTypeId();
    Id CoPayReferralRecTypeId = Schema.SObjectType.Alternative_Funding_gne__c.getRecordTypeInfosByName().get('Co-pay Referral').getRecordTypeId();
    Id TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
    
    for(Alternative_Funding_gne__c adsupp : Trigger.new)
    {
        
        if(Trigger.isAfter && Trigger.isInsert)
        {
            if(adsupp.RecordTypeId  == CoPayCardRecTypeId)
            { 
                Task taskInsert = new Task (OwnerId =  adsupp.CreatedById, 
                                        WhatId = adsupp.Case_gne__c, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Service Update: Referred for Co-Pay Card',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );                        
                tsk_list.add(taskInsert);
            }
            if(adsupp.RecordTypeId  == CoPayReferralRecTypeId)
            { 
                Task taskInsert = new Task (OwnerId =  adsupp.CreatedById, 
                                        WhatId = adsupp.Case_gne__c, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Service Update: Refer to AFS for co-par Referral',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );                        
                tsk_list.add(taskInsert);
            }                    
        }
    }
    
    /*if(tsk_list.size() > 0)
    {
        insert tsk_list;
    }*/
    
    /*if(tsk_list.size()>0 && trigger.isafter)
    {
        errorLogList = new List<Error_Log_gne__c>();
        SR = database.insert(tsk_list, false);
        for(database.saveresult lsr:SR)
        {
            if(!lsr.issuccess())
            {
                for(Database.Error err : lsr.getErrors())
                {                       
                    errMessage = 'Failed to create task ' + err.getMessage();
                    errorLogList.add(new Error_Log_gne__c (Error_Level_gne__c = 'High',
                                       Code_Type__c       = 'Trigger',
                                       Snippet_Name__c    = 'GNE_CM_AS_Post_Processing',
                                       User_Name__c       = UserInfo.getUserName(),
                                       Object_Name__c     = 'Prior Authorization',    
                                       Error_Description__c  = errMessage));
                }
            }
        }       
        if(errorLogList.size() > 0)
        {
            insert errorLogList;
        }
    }*/
    
     //AS Changes 2/25/2013 CMGTT-46
    List<Task> tsk_list 		= new List<Task>();
    Id CoPayReferralRecTypeId 	= Schema.SObjectType.Alternative_Funding_gne__c.getRecordTypeInfosByName().get('Co-pay Referral').getRecordTypeId();
    Id TaskRecTypeId 			= Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
    Set<Id> caseId				= new Set<Id>();
    Map<Id,Case> mapCase 		= new Map<Id,Case>();
    //Business Date Variables
    List<Date> businessDates = new List<Date>();
    List<Actual_Working_Days_gne__c> actualWorkingDays = new List<Actual_Working_Days_gne__c>();
    // Move the retrieved dates into an array
    try 
    {
        actualWorkingDays = [SELECT Date_gne__c FROM Actual_Working_Days_gne__c WHERE Date_gne__c > :date.today() ORDER BY Date_gne__c LIMIT 10];
    } 
    catch (QueryException e) 
    {
        system.assert(false, 'Please contact your System Administrator to review the Actual Working Days object.  Error: ' + e.getMessage());
    }
    if(actualWorkingDays != null && actualWorkingDays.size() > 0)
    {
    	for (Actual_Working_Days_gne__c tempAWD : actualWorkingDays) {
        	businessDates.add(tempAWD.Date_gne__c);
    	}
    }
	
	// Populate Business Date Variables from the Array
    Date businessDateToday		 = businessDates[0];
    Date businessDatePlus5 	 = businessDates[4];
        
    if (businessDates.size() != 10) {
        system.assert(false, 'Please contact your System Administrator to review duplicate Actual Working Days.');
    }
    for(Alternative_Funding_gne__c adsupp : Trigger.new )
    {
    	if(adsupp.Case_gne__c != null)
    		caseId.add(adsupp.Case_gne__c);
    }
    if(caseId != null && caseId.size() > 0)
    {
    	mapCase = new Map<Id,Case>([Select id,Case_Manager__c from Case where id in :caseId]);
    }
    for(Alternative_Funding_gne__c additionalSupport : Trigger.new)
    {
        
        if(Trigger.isAfter && Trigger.isInsert)
        {
            //PK 2/4/2014 CMGTT-90 Shouldn't create tasks if Additional Support record is created with status of 'No funds for disease state'
            if(additionalSupport.RecordTypeId  == CoPayReferralRecTypeId && additionalSupport.Case_gne__c != null && additionalSupport.Status_gne__c !='No funds for disease state')
            { 
                Task taskInsert = new Task (OwnerId =  mapCase.get(additionalSupport.Case_gne__c).Case_Manager__c, 
                                        WhatId = additionalSupport.Case_gne__c, 
                                        ActivityDate = System.Today(), 
                                        Activity_Type_gne__c = 'Send Copay intro letter to customer',
                                        Process_Category_gne__c = 'Copay Assistance',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId
                                        );
                tsk_list.add(taskInsert);
                taskInsert = new Task (OwnerId =  mapCase.get(additionalSupport.Case_gne__c).Case_Manager__c, 
                                        WhatId = additionalSupport.Case_gne__c, 
                                        ActivityDate = businessDatePlus5, 
                                        Activity_Type_gne__c = 'Follow up on Copay Referral status',
                                        Process_Category_gne__c = 'Copay Assistance',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId
                                        );
                tsk_list.add(taskInsert);
            }
        }
    }
    if(tsk_list.size() > 0)
    {
    	GNE_CM_Static_Flags.setFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
        try
        {
        	insert tsk_list;
        }
        catch(exception ex)
        {
    		GlobalUtils.getExceptionDescription(ex); 
        }
        finally 
        {
        	GNE_CM_Static_Flags.unsetFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
        }
    }
    //End Of AS Changes 
}