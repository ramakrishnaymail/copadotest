trigger GNE_CM_Metrics_Task_Trigger on Task (before insert, before update, after insert, after update) {
	
	// SFA2 bypass. Please not remove!
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_Metrics_Task_Trigger')) {
		return;
	}

    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_Metrics_Task_Trigger'))
    {
        return;
    }   
	
	 String  errorLevel = 'High';
     String  snippetName = 'GNE_CM_Metrics_Task_Trigger';
     String  codeType = 'Trigger';
       
     Set<Id> GATCFTaskSet = new Set<Id>();
     Set<Id> CRTaskSet = new Set<Id>();
     Set<Id> TaskIdSet = new Set<Id>();
     Set<Id> TaskOwnerSet = new Set<Id>();
     Set<Id> CaseIdSet = new Set<Id>();
     Set<Id> CRCNCDSet = new Set<Id>();

     
     Map<id,Case> CR_CaseMap ;
     Map<Id,Task> CR_TaskMap ;
     Map<id,Case> GATCF_CaseMap  ;
     Map<Id,Map<String, Decimal>>  GATCFBusinessValuesMap = new Map<Id,Map<String, Decimal>>();    
     Map<String, Decimal> GATCFBusinessValues = new  Map<String, Decimal>(); 
     Map<Id,Map<String, Decimal>>  CRBusinessValuesMap = new Map<Id,Map<String, Decimal>>();      
     Map<String, Decimal> CRBusinessValues = new  Map<String, Decimal>();
     Map<id,DateTime> GATCFTaskopenDateMap = new Map<id,DateTime>();
     Map<id,DateTime> GATCFTaskcloseDateMap = new Map<id,DateTime>();
     Map<id,DateTime> CRTaskopenDateMap = new Map<id,DateTime>();
     Map<id,DateTime> CRTaskcloseDateMap = new Map<id,DateTime>();
     
     List<Case_Metric_Table__c> GATCFCaseMetrixList = new List<Case_Metric_Table__c>();
     List<Case_Metric_Table__c> GATCFCaseMetrixTable = new List<Case_Metric_Table__c>();
     List<Case_Metric_Table__c> GATCFCMListToUpdate = new List<Case_Metric_Table__c>();
     
     List<Case_Metric_Table__c> CRCaseMetrixList = new List<Case_Metric_Table__c>();
     List<Case_Metric_Table__c> CRCaseMetrixTable = new List<Case_Metric_Table__c>();
     List<Case_Metric_Table__c> CRCMListToInsert = new List<Case_Metric_Table__c>();
     
     List<Task> CRTaskList = new List<Task>();
     
     
     
     List<CM_Error_Log_gne__c> IntakeErrLog = new List<CM_Error_Log_gne__c>();
     Map<id,User> User_Map  ;
     List<Task> lstInsertNewTask = new List<Task>();
     
     ID GATCF_CRType_Id =   Schema.SObjectType.Case.getRecordTypeInfosByName().get('GATCF - Standard Case').getRecordTypeId();
     ID CR_Contcase_Id  =   Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Continuous Care Case').getRecordTypeId();
     ID CR_stdcase_Id   =   Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Standard Case').getRecordTypeId();
     ID EE_TRType_Id    =   Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
     Id TaskRecTypeId   =   Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Issues').getRecordTypeId();
     
   
     GNE_CM_Metrics_Utility UtilObj = new GNE_CM_Metrics_Utility();     
     GNE_CM_Businesshours_Calc bhoursobj = new GNE_CM_Businesshours_Calc();
     
 
        // RM :  -----------------------------------------CMR4 GATCF TAT calculation -----------------------------------------------------------------Start
   
         if( (Trigger.isInsert && Trigger.isAfter)) {        
           
         For (Task newtsk : Trigger.New ) {             
         if(newtsk.Subject == 'GATCF Service Update: Eligibility Established' && newtsk.Status == 'Completed' && newtsk.RecordTypeId == EE_TRType_Id) {     
            GATCFTaskSet.add(newtsk.Whatid);           
            }              
           } 
            
            if(GATCFTaskSet != null && GATCFTaskSet.size()>0)
            {
                GATCF_CaseMap = new Map<Id, Case>([select Id, CreatedDate from Case where Id IN:GATCFTaskSet]);
                GATCFCaseMetrixTable = [Select Case__c, Metric_Type__c, BI_Status__c from Case_Metric_Table__c where Metric_Type__c = 'GATCF CR TAT' and Case__c in :GATCFTaskSet];  
            }
            
            
           For (Task newtsk : Trigger.New ) {             
          if(newtsk.Subject == 'GATCF Service Update: Eligibility Established' && newtsk.Status == 'Completed' && newtsk.RecordTypeId == EE_TRType_Id && GATCF_CaseMap.size() > 0 ) {                
            GATCFTaskopenDateMap.put(newtsk.Id,GATCF_CaseMap.get(newtsk.WhatId).CreatedDate);
            GATCFTaskcloseDateMap.put(newtsk.Id,DateTime.now()); 
           
            }              
           } 
            
            
            If( GATCFTaskopenDateMap != null && GATCFTaskopenDateMap.size() > 0 && GATCFTaskcloseDateMap != null && GATCFTaskcloseDateMap.size() > 0 ){
                GATCFBusinessValuesMap = bhoursobj.CalculateBusinessHoursMaps( GATCFTaskopenDateMap, GATCFTaskcloseDateMap); 
                                            
             }
            
            For (Task newtsk : Trigger.New ) {  
            
            if(newtsk.Subject == 'GATCF Service Update: Eligibility Established' && newtsk.Status == 'Completed' && newtsk.RecordTypeId == EE_TRType_Id && GATCFBusinessValuesMap.size() > 0){               
                              
             
                  
            GATCFBusinessValues = GATCFBusinessValuesMap.get(newtsk.id);
                                          
            Case_Metric_Table__c CaseMetrix = new Case_Metric_Table__c (Case__c = newtsk.Whatid,
                                                                          Metric_Type__c = 'GATCF CR TAT', 
                                                                          GATCF_CR_TAT_End_Date__c = DateTime.now(),                                                                           
                                                                          GATCF_CR_TAT_Start_Date__c = GATCF_CaseMap.get(newtsk.WhatId).CreatedDate,                                   
                                                                          Staff_Credited__c = UserInfo.getUserId(),
                                                                          GATCF_CR_TAT_in_Hours__c = GATCFBusinessValues.get('TotalNofBHours'),
                                                                          GATCF_CR_TAT_in_Days__c = GATCFBusinessValues.get('TotalNofBDays')
                                                                          );          
             GATCFCaseMetrixList.add(CaseMetrix);
             }  
            }
             
           if(GATCFCaseMetrixTable.size() > 0 )
           {
                for(Case_Metric_Table__c CM : GATCFCaseMetrixList)
                {
                    for(Case_Metric_Table__c CMTable : GATCFCaseMetrixTable)
                    {
                        if(CM.Case__c == CMTable.Case__c)
                        {                                   
                            CMTable.GATCF_CR_TAT_End_Date__c = CM.GATCF_CR_TAT_End_Date__c; 
                            CMTable.GATCF_CR_TAT_Start_Date__c = CM.GATCF_CR_TAT_Start_Date__c;
                            CMTable.Staff_Credited__c = UserInfo.getUserId();
                            CMTable.GATCF_CR_TAT_in_Hours__c = CM.GATCF_CR_TAT_in_Hours__c;
                            CMTable.GATCF_CR_TAT_in_Days__c  = CM.GATCF_CR_TAT_in_Days__c;
                            GATCFCMListToUpdate.add(CMTable);
                        }
                    }
                } 
                        
              if(GATCFCMListToUpdate.Size() > 0)
                    {
                        try
                        {                            
                            update GATCFCMListToUpdate;
                        }
                        catch(DMLException firsterr)
                        {
                            string firsterrMessage = 'Failed to update case metric table record where type is GATCF CR TAT' + firsterr;
                            String  objectName = 'Case_Metric_Table__c'; 
                            For(Task newtsk : Trigger.New ) 
                            { 
                            UtilObj.insertError(objectName,errorLevel,snippetName,codeType,firsterrMessage);
                           }
                       }
                    }           
            
                
           } else {
                
                if(GATCFCaseMetrixList.Size() > 0)
                     {
                        try
                        {                                                       
                            insert GATCFCaseMetrixList;
                        }
                        catch(DMLException seconderr)
                        
                        {
                            string seconderrMessage = 'Failed to insert case metric table record where type is GATCF CR TAT' + seconderr;
                            String  objectName = 'Case_Metric_Table__c'; 
                           For(Task newtsk : Trigger.New ) 
                           { 
                           UtilObj.insertError(objectName,errorLevel,snippetName,codeType,seconderrMessage);
                          }
                        }
                     }
                        
                 }
         
        GATCFCMListToUpdate.clear();
        GATCFTaskSet.clear();
     }
     
        // RM :  -----------------------------------------CMR4 GATCF TAT calculation -----------------------------------------------------------------End
     
     
     
    
        // RM :  ----------------------------------CMR4  C&R Coverage Notification TAT calculation ---------------------------------------------------Start
   
   
        if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert))  
        {   
                            
        For(Task crtsk : Trigger.New ) {     
        
        if( trigger.isInsert  &&  crtsk.Subject == 'Notify Customer of Cvg results' && crtsk.RecordTypeId == EE_TRType_Id && crtsk.status == 'Completed') {   
          //AS Changes 1/25/2013
          if(crtsk.Case_Id_gne__c != null)
          		CRTaskSet.add(crtsk.Case_Id_gne__c);  
          CRCNCDSet.add(crtsk.WhatId);
                               
          }else if(crtsk.Subject == 'Notify Customer of Cvg results' && crtsk.status == 'Completed'  && crtsk.Status != trigger.oldMap.get(crtsk.Id).Status && crtsk.RecordTypeId == EE_TRType_Id) {                    
          //AS Changes 1/25/2013
          if(crtsk.Case_Id_gne__c != null)
          		CRTaskSet.add(crtsk.Case_Id_gne__c);
          CRCNCDSet.add(crtsk.WhatId);
           
          }
         }
         
        If(CRCNCDSet.size() > 0)  {
            
           CRTaskList = [Select id, CreatedDate, WhatId from Task where ( whatid in: CRCNCDSet or whatid in: CRCNCDSet) and Subject = 'Notify Customer of Cvg results' order by CreatedDate DESC];
             
          }    
                
               
         if(CRTaskSet != null && CRTaskSet.size() > 0)
         {      
            CR_CaseMap = new Map<Id, Case>([select Id, CreatedDate,CaseNumber,RecordtypeId,Product_gne__c from Case where Id IN:CRTaskSet]); 
                        
            CRCaseMetrixTable = [Select Case__c, Metric_Type__c from Case_Metric_Table__c where Metric_Type__c = 'CR CN TAT' and Case__c in :CRTaskSet];            
           }
           if(CR_CaseMap != null && CR_CaseMap.size() > 0) 
           {
	           		  For(Task crtsk : Trigger.New ) {  
					          if( trigger.isInsert  &&  crtsk.Subject == 'Notify Customer of Cvg results' && crtsk.RecordTypeId == EE_TRType_Id && crtsk.status == 'Completed'  ) {   //AS Changes 1/25/2013    && CR_CaseMap != null && CR_CaseMap.size() > 0
					          CRTaskopenDateMap.put(crtsk.Id,CR_CaseMap.get(crtsk.Case_Id_gne__c).CreatedDate); 
					          CRTaskcloseDateMap.put(crtsk.Id,crtsk.CreatedDate);                       
					          }else if( trigger.isUpdate && crtsk.Subject == 'Notify Customer of Cvg results' && crtsk.status == 'Completed'  && crtsk.Status != trigger.oldMap.get(crtsk.Id).Status && crtsk.RecordTypeId == EE_TRType_Id ) {//AS Changes 1/25/2013   && CR_CaseMap != null && CR_CaseMap.size() > 0 
					          CRTaskopenDateMap.put(crtsk.Id,CR_CaseMap.get(crtsk.Case_Id_gne__c).CreatedDate); 
					          CRTaskcloseDateMap.put(crtsk.Id,crtsk.CreatedDate);                    
					          }
	         			}
                    
			           If( CRTaskopenDateMap != null && CRTaskopenDateMap.size() > 0 &&  CRTaskcloseDateMap != null  && CRTaskcloseDateMap.size() > 0  && CRCaseMetrixTable.size() == 0  ){
			            
			           CRBusinessValuesMap = bhoursobj.CalculateBusinessHoursMaps(CRTaskopenDateMap, CRTaskcloseDateMap); 
			                      
			           }
			          For(Task crtsk : Trigger.New ) 
			          {  
			              if(crtsk.Subject == 'Notify Customer of Cvg results' && crtsk.RecordTypeId == EE_TRType_Id && crtsk.status == 'Completed' && CRBusinessValuesMap.size() > 0) 
			              {
			                     CRBusinessValues = CRBusinessValuesMap.get(crtsk.id);
			                                         
			                 Case_Metric_Table__c CRCaseMetrix = new Case_Metric_Table__c (Case__c = crtsk.Case_Id_gne__c,
			                                                                                   Metric_Type__c = 'CR CN TAT', 
			                                                                                   CR_CN_TAT_End_Date__c = crtsk.CreatedDate, 
			                                                                                   CN_CR_Activity_ID__c = crtsk.id,                                                                          
			                                                                                   CR_CN_TAT_Start_Date__c = CR_CaseMap.get(crtsk.Case_Id_gne__c).CreatedDate,                                   
			                                                                                   Staff_Credited__c = crtsk.CreatedById,
			                                                                                   CR_CN_TAT_in_Hours__c = CRBusinessValues.get('TotalNofBHours'),             
			                                                                                   CR_CN_TAT_in_Days__c = CRBusinessValues.get('TotalNofBDays'),
			                                                                                   Product_Franchise_Name__c = GNE_CM_Metrics_Utility.getProductName(CR_CaseMap.get(crtsk.Case_Id_gne__c).Product_gne__c)
			                                                                                   );   
			                    CRCaseMetrixList.add(CRCaseMetrix);   
			              }  
			          }
           
			        if(CRCaseMetrixTable.size() == 0 ){
			                      
			           if(CRCaseMetrixList.size() != null  && CRCaseMetrixList.size()> 0 ){
			            
			          for(Case_Metric_Table__c CM : CRCaseMetrixList)
			          {   
			                    
			            if( (CR_CaseMap.get(CM.Case__c).Recordtypeid == CR_Contcase_Id) || (CR_CaseMap.get(CM.Case__c).Recordtypeid == CR_stdcase_Id)) 
			            { 
			            CRCMListToInsert.add(CM);
			            }
			            }  
			          }     
			                                                
			           if(CRCMListToInsert.size() != null  || CRCMListToInsert.size() > 0 ){  
			                       try
			                        {                                                       
			                            insert CRCMListToInsert;
			                                                      
			                        }
			                        catch(DMLException thirderror)
			                        
			                        {
			                           string thirderrMessage = 'Failed to insert case metric table record where type is CR CN TAT' + thirderror;
			                           String  objectName = 'Case_Metric_Table__c'; 
			                          For(Task crtsk : Trigger.New ) 
			                          { 
			                           UtilObj.insertError(objectName,errorLevel,snippetName,codeType,thirderrMessage);
			                          }
			                        }
			                     }            
			                        
			                 }
         
		       CRCMListToInsert.clear();
		       CRTaskSet.clear();  
           }  
          
    }
    
   // RM :  ----------------------------------CMR4  C&R Coverage Notification TAT calculation ---------------------------------------------------End
    
   
   // RM :  CMR4  Intake error Log  --------------------------------start---------------------------------------------------------
    
    if(trigger.isupdate)
    {
            for(Task tk :Trigger.new)
            {
              if(tk.Intake_Error_Log_Id_gne__c!=null) {
                TaskIdSet.add(tk.Intake_Error_Log_Id_gne__c);
                TaskOwnerSet.add(tk.OwnerId);
              }
            }
            
            if(TaskIdSet != null && TaskIdSet.Size() > 0)
            {
                IntakeErrLog = [Select id, Action_Taken__c, For_Review_Only__c, Status__c, Comments__c, Person_Who_Triggerd__c,CreatedById from CM_Error_Log_gne__c where id in: TaskIdSet];
            }
            
             if(TaskOwnerSet != null && TaskOwnerSet.Size() > 0)
             {
              User_Map = new Map<Id, User>([select Id, Name from User where Id IN:TaskOwnerSet]);
              }
                
            
            if(trigger.isBefore)
            {
                for(Task tsk :Trigger.new)
                {
                    if(tsk.Subject == 'Review Case Management Error Log Entry' && tsk.RecordTypeId == TaskRecTypeId && IntakeErrLog.Size()>0)
                    {                           
                        for(CM_Error_Log_gne__c CMErr : IntakeErrLog)
                        {
                            if(tsk.Intake_Error_Log_Id_gne__c == CMErr.id)
                            {
                                CMErr.Action_Taken__c = tsk.Action_Taken_gne__c;
                                CMErr.For_Review_Only__c = 'Yes';
                                CMErr.Status__c = tsk.Status;
                                CMErr.Comments__c = tsk.Description;
                                CMErr.Task_Assigned_To__c = User_Map.get(tsk.OwnerId).Name;                               
                                if(tsk.Status == 'Completed' && trigger.oldMap.get(tsk.Id).Status != 'Completed')
                                {
                                    tsk.Closed_Date_gne__c = system.now();
                                }
                            }            
                        }
                    }
                  if(tsk.Status == 'Completed' && trigger.oldMap.get(tsk.Id).Status != 'Completed' && tsk.Subject == 'Case Management Error Log Resolved')                   
                  {
                     tsk.Closed_Date_gne__c = system.now();
                  }                  
                }               
                update IntakeErrLog;
                
                for(Task tk :Trigger.new)
                {
                    if(tk.RecordTypeId == TaskRecTypeId && tk.Status == 'Completed' && tk.Subject == 'Review Case Management Error Log Entry')
                    {
                        if(tk.Action_Taken_gne__c == null || tk.Action_Taken_gne__c == '--None--')
                        {
                            tk.Action_Taken_gne__c.addError('Please select the Action Taken.');
                        }
                     }
                    if(tk.RecordTypeId == TaskRecTypeId && trigger.oldMap.get(tk.Id).Status != tk.Status && tk.status == 'Completed')
                    {
                        tk.Intake_Error_Log_Rresolved_Flag_gne__c = true;
                    }
                }
            }
            
        //  KS - Inserting new activity when the status of previous crreated is changed to Completed. 
        
        if(trigger.isAfter)
        {
                for(Task tsk :Trigger.new)
                { 
                    if(GNE_CM_Metrics_Utility.flagIntakeErrorLog == true){
                            return;
                        }
                        
                    if(tsk.Status == 'Completed' && trigger.oldMap.get(tsk.id).Status != 'Completed' && tsk.Subject == 'Review Case Management Error Log Entry' && tsk.RecordTypeId == TaskRecTypeId)
                    {
                        system.debug('inside condition.....');
                        Task t = new Task();
                        t.Intake_Error_Log_Rresolved_Flag_gne__c = true;
                        t.Subject = 'Case Management Error Log Resolved'; 
                        t.ActivityDate = Date.Today(); 
                        t.Process_Category_gne__c = 'Enrolling a Patient';
                        t.RecordTypeId = TaskRecTypeId;
                        for(integer i=0; i<IntakeErrLog.Size(); i++)
                        {
                            t.OwnerId = IntakeErrLog[0].CreatedById;
                            if(tsk.Intake_Error_Log_Id_gne__c == IntakeErrLog[i].id)
                            {
                                if(IntakeErrLog[i].Comments__c != '')
                                {
                                    t.Description = IntakeErrLog[i].Comments__c;
                                }
                            }   
                        }                       
                        t.Description = tsk.Description;
                        t.Patient_ID_gne__c = tsk.Patient_ID_gne__c;
                        t.Product_Effected_gne__c = tsk.Product_Effected_gne__c;
                        t.Person_who_triggered_issue_gne__c = tsk.Person_who_triggered_issue_gne__c;
                        t.Your_Role_gne__c = tsk.Your_Role_gne__c;
                        t.Issue_Detail_gne__c = tsk.Issue_Detail_gne__c;
                        t.Duplicate_of_Case_gne__c = tsk.Duplicate_of_Case_gne__c;
                        t.Duplicate_of_Patient_ID_gne__c = tsk.Duplicate_of_Patient_ID_gne__c;
                        t.Duplicate_of_Medical_History_gne__c = tsk.Duplicate_of_Medical_History_gne__c;
                        t.Issue_Category_gne__c = tsk.Issue_Category_gne__c;
                        t.Medical_History_gne__c = tsk.Medical_History_gne__c;
                        t.Roles_Affected_gne__c = tsk.Roles_Affected_gne__c; 
                        t.Action_Taken_gne__c = tsk.Action_Taken_gne__c;
                        t.Priority = 'Normal';
                        t.For_Review_Only_gne__c = tsk.For_Review_Only_gne__c;
                        
                        if(tsk.WhatId != null)
                        {
                            t.WhatId = tsk.WhatId;
                        }
                        lstInsertNewTask.add(t);
                        GNE_CM_Metrics_Utility.flagIntakeErrorLog = true;
                   }
               }
               if(lstInsertNewTask != null && lstInsertNewTask.size() > 0)
               {
                    try
                    {   
                        insert lstInsertNewTask;                        
                    }
                    catch(Exception err)
                    {
                      String  objectName = 'Task'; 
                      String  fourtherr = 'Failed to insert Case Management Error Log Resolved Task ' + err;
                        for(Task t :Trigger.new)
                        {
                            UtilObj.insertError(objectName, errorLevel, snippetName, codeType, fourtherr);
                        }
                    }
               }
         }
     }  
    // RM :  CMR4  Intake error Log  --------------------------------end---------------------------------------------------------
}