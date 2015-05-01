trigger GNE_CM_PA_Post_Processing on Prior_Authorization_gne__c (before insert, before update, after insert, after update) 
{
    List<Task> tsk_list = new List<Task>();
    List<Error_Log_gne__c> errorLogList = new List<Error_Log_gne__c>();
    String errMessage = '';
    Database.saveresult[] SR;
    Id TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
                
    for(Prior_Authorization_gne__c pa : Trigger.new)
    {
        
        if(Trigger.isInsert)
        {
            if(pa.Status_gne__c == 'Approved' || pa.Status_gne__c == 'Denied')
            {
                Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = pa.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Service Update: PA Complete',
                                        Process_Category_gne__c = 'Investigating Benefits',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );                        
                tsk_list.add(taskInsert);
            }                    
        }
        if(Trigger.isUpdate)
        {
            if((pa.Status_gne__c == 'Approved' || pa.Status_gne__c == 'Denied') && trigger.oldMap.get(pa.id).Status_gne__c != pa.Status_gne__c)
            {
                Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = pa.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Service Update: PA Complete',
                                        Process_Category_gne__c = 'Investigating Benefits',
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
    
    if(tsk_list.size()>0 && trigger.isafter)
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
                                       Snippet_Name__c    = 'GNE_CM_PA_Post_Processing',
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
    } 

}