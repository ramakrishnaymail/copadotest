trigger GNE_CM_Fulfilment_Post_Processing on Fulfillment_gne__c (after insert, after update) 
{
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    List<Task> tsk_list = new List<Task>();
    List<Error_Log_gne__c> errorLogList = new List<Error_Log_gne__c>();
    String errMessage = '';
    Database.saveresult[] SR;
    Id TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
    for(Fulfillment_gne__c ff : Trigger.new)
    {
        
        if(Trigger.isInsert)
        {
            Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                    WhatId = ff.Case_Fulfillment_gne__c, 
                                    //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                    ActivityDate = system.today(), 
                                    Activity_Type_gne__c = 'Service Update: Product Fulfillment Pending',
                                    Process_Category_gne__c = 'Investigating Benefits',
                                    Status = 'Completed',
                                    RecordTypeId = TaskRecTypeId 
                                    );                        
            tsk_list.add(taskInsert);
            if(ff.Date_Fulfilled_gne__c != null)
            {
                Task taskInsertDF = new Task (OwnerId =  UserInfo.getUserId(), 
                                    WhatId = ff.Case_Fulfillment_gne__c, 
                                    //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                    ActivityDate = system.today(), 
                                    Activity_Type_gne__c = 'Service Update: Product Fulfillment Complete',
                                    Process_Category_gne__c = 'Investigating Benefits',
                                    Status = 'Completed',
                                    RecordTypeId = TaskRecTypeId 
                                    );                        
                tsk_list.add(taskInsertDF);
            }                    
        }
        
        if(Trigger.isUpdate && ff.Date_Fulfilled_gne__c != null)
        {
            if(Trigger.oldMap.get(ff.Id).Date_Fulfilled_gne__c == null  && ff.Date_Fulfilled_gne__c != null)
            {
                Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = ff.Case_Fulfillment_gne__c, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Service Update: Product Fulfillment Complete',
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
                                       Snippet_Name__c    = 'GNE_CM_Fulfilment_Post_Processing',
                                       User_Name__c       = UserInfo.getUserName(),
                                       Object_Name__c     = 'Fulfilment',    
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