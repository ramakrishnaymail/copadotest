/**
 * Trigger responsible for creating tasks basing on various criteria when cases are inserted or updated.
            */
trigger GNE_CM_case_create_tasks on Case (after insert, after update)
{
    // skip this trigger during merge process
    if (GNE_SFA2_Util.isMergeMode())
    {
        return;
    }

    // Skip this trigger if certain unit tests are running.
    // This code has no impact when not run in tests - the condition causing the trigger to exit is only fulfilled in tests and only when explicitly set.
    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_case_create_tasks'))
    {
        return;
    }   
   
    //skip this trigger if it is triggered from transfer wizard
    if (GNE_CM_MPS_TransferWizard.isDisabledTrigger)
    {
        return;
    }
    
    List<Actual_Working_Days_gne__c> actualWorkingDays = new List<Actual_Working_Days_gne__c>();
    List<Date> businessDates = new List<Date>();
    
    try 
    {
        actualWorkingDays = [SELECT Date_gne__c FROM Actual_Working_Days_gne__c WHERE Date_gne__c > :date.today() ORDER BY Date_gne__c LIMIT 10];
    } 
    catch (QueryException e) 
    {
        system.assert(false, 'Please contact your System Administrator to review the Actual Working Days object.  Error: ' + e.getMessage());
    }

    // Throw an exception if sufficient Actual Working Days have not been defined
    if (actualWorkingDays.size() != 10)
    {
        system.assert(false, 'Please contact your System Administrator to review missing or absent Actual Working Days.');
    }

    // Move the retrieved dates into an array
    for (Actual_Working_Days_gne__c tempAWD : actualWorkingDays)
    {
        businessDates.add(tempAWD.Date_gne__c);
    }
    // Throw an exception if duplicate Actual Working Days have been defined
    if (businessDates.size() != 10)
    {
        system.assert(false, 'Please contact your System Administrator to review duplicate Actual Working Days.');
    }

    // Populate Business Date Variables from the Array
    Date businessDatePlus2 = businessDates[1];
    Date businessDatePlus5 = businessDates[4];
    Map<String, Schema.RecordTypeInfo> TaskRecordType = new Map<String, Schema.RecordTypeInfo>();
    TaskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName();
    ID CMTaskRecordTypeId = TaskRecordType.get('CM Task').getRecordTypeId();
    Id template_id;
    // Create a new single email message object that will send out a single email to the addresses in the To, CC & BCC list.
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    Map<Id,User> user_info = new Map<Id, User>();
    set<Id> user_id=new set<Id>();
    string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
    String genericUserID = GNE_CM_Task_Queue_Mgmt_Helper.getGenericUserId();
    String vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    
    //KS: 1/25/2011: Added Pertuzumab condition
    String pertuzumab_product_name = system.label.GNE_CM_Pertuzumab_Product_Name;
    String Foundation_Specialist = system.label.GNE_CM_Foundation_Specialist; 
    //KS: modifications end here 
    //  SERVICE VIEW CODE
  
    Set<Id> CaseId = new Set<Id>();
    List<GNE_CM_Requested_Services__c> lstReqService = new List<GNE_CM_Requested_Services__c>();
    List<GNE_CM_Requested_Services__c> lstReqServicetoInsert = new List<GNE_CM_Requested_Services__c>();
    List<Patient_Enrollment_Request_gne__c> lstPatientEnrollmentRequest = new List<Patient_Enrollment_Request_gne__c>();
    List<Patient_Enrollment_Request_gne__c> lstPatEnrollmentRequest = new List<Patient_Enrollment_Request_gne__c>();
    Map<String, Schema.RecordTypeInfo> caseRecordType = new Map<String, Schema.RecordTypeInfo>();   
    caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName();
    Id crCaseRecordTypeId = caseRecordType.get('C&R - Standard Case').getRecordTypeId();
    Id GATCFStandardCaseRecordTypeId = caseRecordType.get('GATCF - Standard Case').getRecordTypeId();
    Id GESCaseRecordTypeId = caseRecordType.get('GATCF - Eligibility Screening').getRecordTypeId();
    
    Set<Id> PERId  = new Set<Id>();
    Map<Id,ID> onlineSR = new Map<ID, ID>();
    Map<Id, Id> CaseRecTypeMap = new Map<ID, Id>();
    List<Task> taskList = new List<Task>();
    List<Error_Log_gne__c> errorLogList = new List<Error_Log_gne__c>();
    String errMessage = '';
    Database.saveresult[] SR;
    ID TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
    Map<String, List<Environment_Variables__c>> envVarMultiValues;
    Set<String> envVarNameSet = new Set<String>{'GNE_CM_SERVICE_STARTER_PROGRAM','GNE_CM_SERVICE_APA_PROGRAM'};
    Set<String> starterProgramSet=new Set<String>();
    Set<String> apaProgramSet=new Set<String>();
    String campaignName='';
    Map<Id,String> campaignMap=new Map<Id,String>();
    
    //envVarMultiValues = GNE_CM_Requested_Service_Extention.populateEnvVariables(envVarNameSet);
    //List<Environment_Variables__c> envVarList = envVarMultiValues.get('GNE_CM_SERVICE_STARTER_PROGRAM');
    
    //AS Changes 2/07/2013    
    Map<Id,Case> mapPERSource = new Map<Id,Case>([Select id, Patient_Enrollment_Request_gne__r.PER_Source_gne__c , Patient_Enrollment_Request_gne__r.Secondary_Insurance_Carrier_Name_gne__c, Patient_Enrollment_Request_gne__r.Primary_Insurance_Carrier_Name_gne__c, Patient_Enrollment_Request_gne__r.Anticipated_Date_of_Treatment_gne__c,Patient_Enrollment_Request_gne__r.Primary_Payer_gne__r.Name, Patient_Enrollment_Request_gne__r.Name, Patient_Enrollment_Request_gne__r.Status__c  
                                                from Case where id in:trigger.newmap.keyset() and Patient_Enrollment_Request_gne__c != null]); 
    
    //campaignNameList=new List<String>();
    String environment = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;  
    Map<String, GNE_CM_SERVICE_STARTER_PROGRAM__c> serviceStarterProgramEnvMap = GNE_CM_SERVICE_STARTER_PROGRAM__c.getAll();
    if (serviceStarterProgramEnvMap!=null && serviceStarterProgramEnvMap.size()>0)
    {
      
		starterProgramSet.addAll(GNE_CM_CustomSettings_Utils.getValues(GNE_CM_SERVICE_STARTER_PROGRAM__c.getall().values(), environment));
	   /*
       for (GNE_CM_SERVICE_STARTER_PROGRAM__c env : serviceStarterProgramEnvMap.values()){
            if(env.Environment__c == environment  || env.Environment__c.toLowerCase() == 'all'){
                starterProgramSet.add(env.value__c);                
            }
        }
	    */
    }
    
    Map<String, GNE_CM_SERVICE_APA_PROGRAM__c> ServiceApaProgramEnvMap = GNE_CM_SERVICE_APA_PROGRAM__c.getAll();
    //envVarList = envVarMultiValues.get('GNE_CM_SERVICE_APA_PROGRAM');
    if (ServiceApaProgramEnvMap!=null && ServiceApaProgramEnvMap.size()>0)
    {
        apaProgramSet.addAll(GNE_CM_CustomSettings_Utils.getValues(GNE_CM_SERVICE_APA_PROGRAM__c.getall().values(), environment));
        /*
        for (GNE_CM_SERVICE_APA_PROGRAM__c env : ServiceApaProgramEnvMap.values()){
            if(env.Environment__c == environment  || env.Environment__c.toLowerCase() == 'all'){
                apaProgramSet.add(env.value__c);            
            }            
        }
        */
    }
    
     system.debug('Special program name------'+trigger.new[0].Special_Program_Name_gne__r.Brand_gne__c);
     system.debug('Special program name------'+trigger.new[0].medical_history_gne__r.ICD9_Code_1_gne__r.Name);
    
    Set<Id> CampaignSet = new Set<Id>();
    
    for (Case cs : Trigger.new)
    {      
        if (cs.Special_Program_Name_gne__c != null)
        {
            CampaignSet.add(cs.Special_Program_Name_gne__c);
        }            
    }
    
    if (CampaignSet != null && CampaignSet.size() > 0)
    {  
        List<Campaign> campaignsList=[select id, name from Campaign where id in: CampaignSet];
       
        if (campaignsList!=null && campaignsList.size()>0)
        {
            for (Case cas : trigger.new)
            {
                for (Campaign cmpg : campaignsList)
                {
                    if (cas.Special_Program_Name_gne__c == cmpg.Id)
                    {
                        campaignName = cmpg.Name;
                        campaignMap.put(cas.id,cmpg.Name);
                    }
                }
            }   
        }
    }
   
    // Get the possible Actual Working Days
    if (trigger.isInsert)
    {
         // Get Case Record Type Ids
        ID standardCaseRecordTypeId = caseRecordType.get('C&R - Standard Case').getRecordTypeId();        
        ID continuousCareCaseRecordTypeId = caseRecordType.get('C&R - Continuous Care Case').getRecordTypeId();
        //ID GESCaseRecordTypeId = caseRecordType.get('GATCF - Eligibility Screening').getRecordTypeId();

        // Loop through the Cases, creating Tasks as needed
        for (Case loopCase : Trigger.new)
        {
            if (loopCase.RecordTypeId == standardCaseRecordTypeId && loopCase.Perform_Standard_BI_gne__c=='Yes' && loopcase.perform_stat_bi_gne__c != 'Yes')
            {
                if (loopcase.case_referral_reason_gne__c != 'Starter Rx Request Only'
                    && loopcase.case_referral_reason_gne__c != 'Continuous Coverage Program Only'
                    && loopcase.case_referral_reason_gne__c != 'Co-pay Assistance Only'
                    && loopcase.case_referral_reason_gne__c != 'Injection Training Coordination Only'
                    && loopcase.case_referral_reason_gne__c != 'Interim Shipment Request Only'
                    && loopcase.DDS_BI_Eligible_gne__c == true
                    && loopcase.Reimbursement_Specialist_gne__c != null)
                    {
                        Task taskIns = new Task (OwnerId = loopCase.Reimbursement_Specialist_gne__c, Subject = 'Perform Benefit Investigation', WhatId = loopCase.Id,
                            Case_Id_gne__c = loopCase.Id, Activity_Type_gne__c = 'Perform Benefit Investigation', Process_Category_gne__c = 'Investigating Benefits', 
                            ActivityDate = date.today(), Description=loopCase.Insurance__c);
                        
                        // apply blizzard logic, if applicable
                        taskIns.ActivityDate = GNE_CM_Task_Queue_Mgmt_Helper.getRSPrioritizedDate(loopcase.Product_gne__c, loopcase.Anticipated_Date_of_Treatment_gne__c);

                        //AS Changes
                        if(mapPERSource != null && mapPERSource.containsKey(loopcase.id))
                        {
                            // apply BR logic
                            if(mapPERSource.get(loopcase.id).Patient_Enrollment_Request_gne__r.PER_Source_gne__c == 'Benefits Reverification' && 
                                        (loopcase.Product_gne__c == 'Lucentis' || loopcase.Product_gne__c == 'Actemra') && 
                                        loopcase.case_referral_reason_gne__c == 'Proactive BI')
                            {
                                GNE_CM_Case_Trigger_Util.updateTaskFieldsForBR(taskIns,mapPERSource.get(loopcase.id).Patient_Enrollment_Request_gne__r);
                                
                            }
                        }
                        taskList.add(taskIns);
                    }       
            }
                
            // If the Case is a C&R Standard Case or a C&R Continuous Care Case
            if ((loopCase.RecordTypeId == standardCaseRecordTypeId || loopCase.RecordTypeId == continuousCareCaseRecordTypeId) && loopCase.Create_Activity_gne__c == true)
            {
                // Create the base task
                Task taskInsert = new Task (OwnerId = (loopCase.Case_Manager__c != null ? loopCase.Case_Manager__c : loopCase.OwnerId), Subject = 'Provide status update to customer', WhatId = loopCase.Id,
                        Case_Id_gne__c = loopCase.Id, Activity_Type_gne__c = 'Provide status update to customer', Process_Category_gne__c = 'Managing a Case');
                taskInsert.Trigger_Flag_gne__c = true;
                
                //KS: 10/27/2011: Added Vismo in the if condition as "loopCase.Product_gne__c == vismo_product_name" 
                if (loopCase.Product_gne__c == 'Rituxan RA' ||  loopCase.Product_gne__c == braf_product_name ||  loopCase.Product_gne__c == vismo_product_name || loopCase.Product_gne__c == 'Xeloda' || loopCase.Product_gne__c == 'Pegasys')
                {
                    taskInsert.ActivityDate = businessDatePlus2;            
                }
                else if (loopCase.Product_gne__c == 'Tarceva' || loopCase.Product_gne__c == 'Actemra')
                {
                    taskInsert.ActivityDate = businessDatePlus2;
                }
                else if (loopCase.Product_gne__c == 'Xolair')
                {
                    taskInsert.ActivityDate = businessDatePlus2;                
                }
                else if (loopCase.Product_gne__c == 'Lucentis')
                {
                    taskInsert.ActivityDate = businessDatePlus2;                
                }
                else
                {
                    taskInsert.ActivityDate = businessDatePlus2;
                }
                
                if(mapPERSource != null && mapPERSource.containsKey(loopcase.id))
                {
                    if(mapPERSource.get(loopcase.id).Patient_Enrollment_Request_gne__r.PER_Source_gne__c == 'Benefits Reverification' && 
                        (loopcase.Product_gne__c == 'Lucentis' || loopcase.Product_gne__c == 'Actemra') && 
                        loopcase.case_referral_reason_gne__c == 'Proactive BI' && 
                        loopcase.Enroll_Comp_Original_Receipt_gne__c == 'Yes')
                    {
                        GNE_CM_Case_Trigger_Util.updateTaskFieldsForBR(taskInsert,mapPERSource.get(loopcase.id).Patient_Enrollment_Request_gne__r);
                    }
                }

                taskList.add(taskInsert);            
            }
            
            //KS: creating Perform Combo Enrollment Task on parent case
            if (loopcase.Create_Activity_gne__c == true && loopcase.Combo_Case_gne__c == true) 
             {
                System.Debug('** Inside Combo Task');
                Task taskInsert = new Task();
                if (loopCase.RecordTypeId == standardCaseRecordTypeId)
                {
                    if (loopCase.Case_Manager__c != Foundation_Specialist)
                    {
                        taskInsert.OwnerId = loopCase.Case_Manager__c;
                    }
                    else
                    {
                        taskInsert.OwnerId = Foundation_Specialist;
                    }
                }
                else
                {
                    if (loopCase.Foundation_Specialist_gne__c != Foundation_Specialist)
                    {
                        taskInsert.OwnerId = loopCase.Foundation_Specialist_gne__c;
                    }
                    else
                    {
                        taskInsert.OwnerId = Foundation_Specialist;
                    }
                }
                
                taskInsert.Subject = 'Perform Combo Enrollment';
                taskInsert.WhatId = loopCase.Id;
                taskInsert.Case_Id_gne__c = loopCase.Id;
                taskInsert.Activity_Type_gne__c = 'Perform Combo Enrollment';
                taskInsert.Process_Category_gne__c = 'Managing a Case';
                taskInsert.Trigger_Flag_gne__c = true;
            
                if (loopcase.Product_gne__c == pertuzumab_product_name) 
                {
                    taskInsert.ActivityDate = date.Today();            
                }
                // Insert the Task
                System.Debug('***taskInsert------------> '+ taskInsert);

                taskList.add(taskInsert);            
            } 
            //KS: Perform Combo Enrollment logic ends here
            
            if (loopCase.RecordTypeId == GESCaseRecordTypeId)
            {
                //PKambalapally 3-6-2014. Fix for PFS-910,911, Task Creator_Comments_gne__c field is increased to 255 and when the value exceeds 255, it is truncated so it fits the field length.
                String creatorComments = loopCase.Documentation_gne__c;
                if (String.isNotBlank(creatorComments))
                {
                    creatorComments = '\n Missing Documents: '+ loopCase.Documentation_gne__c;
                    if (creatorComments.length()>=255)
                    {
                        creatorComments = creatorComments.substring(0,255);
                        if (creatorComments.indexOf(';') != -1)
                        {
                            creatorComments = creatorComments.substring(0,creatorComments.lastIndexOf(';') - 1);
                        }
                    }
                }
                else
                {
                    creatorComments = '';
                }
                
                // Create the base task
                Task taskInsert = new Task (OwnerId = loopCase.Foundation_Specialist_gne__c, Subject = 'Perform GES Review', WhatId = loopCase.Id,
                        Case_Id_gne__c = loopCase.Id, Activity_Type_gne__c = 'Perform GES Review', RecordTypeId=CMTaskRecordTypeId, Process_Category_gne__c = 'Access to Care', ActivityDate = system.today(),  Creator_Comments_gne__c =creatorComments);
                    
            // Insert the Task
                taskList.add(taskInsert);     
            }
            
            if (loopCase.Perform_Stat_BI_gne__c=='Yes')
            {           
            	Datetime dat;
            	       
                if (loopCase.Enrollment_Form_Rec_gne__c !=null)
                {
                    dat=loopCase.Enrollment_Form_Rec_gne__c;
                }
                if (loopCase.Reimbursement_Specialist_gne__c!=null && loopCase.Enroll_Comp_Original_Receipt_gne__c == 'Yes' && loopcase.DDS_BI_Eligible_gne__c == true)
                {
                    taskList.add(new Task (OwnerId = loopCase.Reimbursement_Specialist_gne__c, Subject = 'STAT BI – Perform BI', WhatId = loopCase.Id,
                            Case_Id_gne__c = loopCase.Id,Description=loopCase.Insurance__c, RecordTypeId=CMTaskRecordTypeId, ActivityDate = system.today(), Activity_Type_gne__c = 'STAT BI – Perform BI', Process_Category_gne__c = 'Investigating Benefits', Creator_Comments_gne__c = (loopCase.Enrollment_Form_Rec_gne__c != null ? 'Enroll/SMN Form Received: '+dat.format('M/d/yyyy h:mm a') : '')));
                    
                    user_id.add(loopCase.Reimbursement_Specialist_gne__c);
                }
                
                taskList.add(new Task (OwnerId = loopCase.Case_Manager__c, Subject = 'STAT BI - New Enrollment Review', WhatId = loopCase.Id,
                        Case_Id_gne__c = loopCase.Id, RecordTypeId=CMTaskRecordTypeId,Activity_Type_gne__c = 'STAT BI - New Enrollment Review', Process_Category_gne__c = 'Managing a Case', ActivityDate = system.today(), Creator_Comments_gne__c = (loopCase.Enrollment_Form_Rec_gne__c != null ? 'Enroll/SMN Form Received: '+dat.format('M/d/yyyy h:mm a') : '')));   
                
                user_id.add(loopCase.Case_Manager__c);
            } 
                
           // KS: Pertuzumab-Herceptin Case - Moved workflow logic "Perform New Enrollment Review" in trigger
           /*
            if ((loopCase.RecordTypeId != continuousCareCaseRecordTypeId || loopCase.RecordTypeId != GESCaseRecordTypeId) && (loopCase.Combo_Case_gne__c == true))
            {
                tsk_insert.add(new Task (OwnerId = loopCase.Case_Manager__c, Subject = 'Perform New Enrollment Review', WhatId = loopCase.Id,
                        Case_Id_gne__c = loopCase.Id, RecordTypeId=CMTaskRecordTypeId, ActivityDate = system.today(), Description = 'Perform New Enrollment Review'));   
            }
            */
             //AS Changes CMGTT-36 2/7/2013
            if((loopCase.RecordTypeId == GESCaseRecordTypeId || loopCase.RecordTypeId == GATCFStandardCaseRecordTypeId) && loopCase.Practice_gne__c == null)
            {
                // Create the base task
                Task taskInsert = new Task (OwnerId = loopCase.Foundation_Specialist_gne__c, Subject = 'Align Clinic/Practice', WhatId = loopCase.Id,
                         Activity_Type_gne__c = 'Align Clinic/Practice', RecordTypeId=CMTaskRecordTypeId, Process_Category_gne__c = 'Enrolling a Patient',
                        Status ='Not Started',Priority='Normal', ActivityDate = system.today());
                // Insert the Task
                taskList.add(taskInsert); 
            }
            if(loopCase.RecordTypeId == standardCaseRecordTypeId && loopCase.Practice_gne__c == null)
            {
                // Create the base task
                Task taskInsert = new Task (OwnerId = loopCase.Case_Manager__c, Subject = 'Align Clinic/Practice', WhatId = loopCase.Id,
                        Activity_Type_gne__c = 'Align Clinic/Practice', RecordTypeId=CMTaskRecordTypeId, Process_Category_gne__c = 'Enrolling a Patient',
                        Status ='Not Started',Priority='Normal', ActivityDate = system.today());
                    
                // Insert the Task
                taskList.add(taskInsert); 
            }
            //End Of AS Changes
        }
    
    } // End of if (trigger.isInsert)
    
    if (trigger.isUpdate && trigger.isAfter)
    {        
    //Record Type ID for C&R statndard Case
        ID standardCaseRecordTypeId = caseRecordType.get('C&R - Standard Case').getRecordTypeId();
        for (Case caseobj : trigger.new)// Closing all In Progress Services when Case is closed
        {
            string OldStatusValue = trigger.oldMap.get(caseobj.id).Status;
            string NewStatusValue = caseobj.status;
            if (OldStatusValue != '' && OldStatusValue != null)
            {
                if (!OldStatusValue.startsWith('Closed.') && NewStatusValue.startsWith('Closed.'))
                {
                    CaseId.add(caseobj.id);
                }
            }
            else
            {
                if (NewStatusValue.startsWith('Closed.'))
                {
                    CaseId.add(caseobj.id);
                }
            }
            //PKambalapally 3-6-2014. Fix for PFS-910,911, Task Creator_Comments_gne__c field is increased to 255 and when the value exceeds 255, it is truncated so it fits the field length.
            String creatorComments = caseobj.Enrollment_Not_Complete_Reason_gne__c;
            if (String.isNotBlank(creatorComments)&&creatorComments.length()>=255)
            {
                creatorComments = creatorComments.substring(0,255);
                if (creatorComments.indexOf(';') != -1)
                {
                    creatorComments = creatorComments.substring(0,creatorComments.lastIndexOf(';') - 1);
                }
            }
						
            if(mapPERSource.containsKey(caseobj.id) && caseobj.Patient_Enrollment_Request_gne__c != null && trigger.oldMap.get(caseobj.id).Patient_Enrollment_Request_gne__c != caseobj.Patient_Enrollment_Request_gne__c && 
                            mapPERSource.get(caseobj.id).Patient_Enrollment_Request_gne__r.Status__c == 'Processed by Intake' && caseobj.Status == 'Active'){
                Id taskOwnerId;
                if (caseobj.recordtypeid == caseRecordType.get('C&R - Standard Case').getRecordTypeId() || caseobj.recordtypeid == caseRecordType.get('C&R - Continuous Care Case').getRecordTypeId())
                {
                    taskOwnerId = caseobj.Case_Manager__c;
                }
                else
                {
                    taskOwnerId = caseobj.Foundation_Specialist_gne__c;
                }
                
                Task taskInsertEC = new Task (OwnerId =  taskOwnerId, 
                                        WhatId = caseobj.Id, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Review Incoming Documents',
                                        Process_Category_gne__c = 'Fax/Document Management',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId,
                                        Creator_Comments_gne__c = 'PER #: ' + mapPERSource.get(caseobj.id).Patient_Enrollment_Request_gne__r.name
                                        );                        
                                                               
                taskList.add(taskInsertEC);             
            }
            if ((caseobj.Enroll_Comp_Original_Receipt_gne__c == 'No' && caseobj.Enrollment_Not_Complete_Reason_gne__c != null)
                && (caseobj.Enroll_Comp_Original_Receipt_gne__c != trigger.oldMap.get(caseobj.id).Enroll_Comp_Original_Receipt_gne__c
                    || caseobj.Enrollment_Not_Complete_Reason_gne__c != trigger.oldMap.get(caseobj.id).Enrollment_Not_Complete_Reason_gne__c))
            {
                Task taskInsertEC = new Task (OwnerId =  caseobj.OwnerId, 
                                        WhatId = caseobj.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Follow Up on Missing Information',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId,
                                        Creator_Comments_gne__c = creatorComments
                                        );                        
                taskList.add(taskInsertEC);
            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.Approval_Date_gne__c != null && trigger.oldMap.get(caseobj.id).Approval_Date_gne__c == null)
            {
                
                Task taskInsertEC = new Task (OwnerId =  caseobj.Foundation_Specialist_gne__c, 
                                        WhatId = caseobj.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = Date.valueof(caseobj.Approval_Date_gne__c).addDays(335), 
                                        Activity_Type_gne__c = 'Perform GATCF Annual Renewal',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId,
                                        Creator_Comments_gne__c = creatorComments
                                        );                        
                taskList.add(taskInsertEC);
            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.GATCF_Status_gne__c != null)// GATCF Services
            {
                if (!caseobj.GATCF_Status_gne__c.contains('Pending') && trigger.oldMap.get(caseobj.id).GATCF_Status_gne__c != caseobj.GATCF_Status_gne__c)
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Enrollment Complete',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
            }
                    
            //AS Changes 1/17/2013
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.Date_Discussed_gne__c != null)
            {
                if(caseobj.Date_Discussed_gne__c != trigger.oldmap.get(caseobj.id).Date_Discussed_gne__c)
                {
                    system.debug('----------------------Enter into block');
                    Task taskInsert = new Task (OwnerId =  genericUserID, 
                                    WhatId = caseobj.Id, 
                                    ActivityDate = caseobj.Date_Discussed_gne__c.addMonths(3), 
                                    Activity_Type_gne__c = 'Follow-up on Insurance Information',
                                    Process_Category_gne__c = 'Access to Care',
                                    Status = 'Not Started',
                                    RecordTypeId = TaskRecTypeId 
                                    );                  
                    taskList.add(taskInsert);
                }
            }
        
            /*if (caseobj.RecordTypeId == crCaseRecordTypeId && caseobj.Cvg_gne__c != null)// GATCF Services
            {
                if (!caseobj.GATCF_Status_gne__c.contains('Pending') && trigger.oldMap.get(caseobj.id).GATCF_Status_gne__c.contains('Pending'))
                {
                     Task taskInsertEC = new Task (OwnerId =  caseobj.CreatedById, 
                                            WhatId = caseobj.Id, 
                                            //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Enrollment Complete',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
            }*/
            /*if (caseobj.RecordTypeId == GESCaseRecordTypeId)
            {
                // Create the base task
                Task taskInsert = new Task (OwnerId = caseobj.Foundation_Specialist_gne__c, Subject = 'Perform GES Review', WhatId = caseobj.Id,
                        Case_Id_gne__c = caseobj.Id, Activity_Type_gne__c = 'Perform GES Review', RecordTypeId=TaskRecTypeId, Process_Category_gne__c = 'Access to Care', ActivityDate = system.today(),  Creator_Comments_gne__c = (caseobj.Documentation_gne__c != null ? '\n Missing Documents: '+ caseobj.Documentation_gne__c : ''));
                    
            // Insert the Task
                taskList.add(taskInsert);     
            }*/
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId)
            {
                if (trigger.oldMap.get(caseobj.id).Contingent_Determination_gne__c == null && caseobj.Contingent_Determination_gne__c=='Approved')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Contingent Eligibility',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (trigger.oldMap.get(caseobj.id).Eligibility_gne__c == null && caseobj.Eligibility_gne__c != null)
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Financial Obtained',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (trigger.oldMap.get(caseobj.id).GATCF_Status_gne__c != caseobj.GATCF_Status_gne__c && (caseobj.GATCF_Status_gne__c.startsWith('Approved') || caseobj.GATCF_Status_gne__c.startsWith('Denied')) && caseobj.GATCF_Status_gne__c != 'Approved - Contingent Enrollment'  && caseobj.GATCF_Status_gne__c != 'Approved - In Appeal')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Eligibility Established',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (trigger.oldMap.get(caseobj.id).GATCF_Status_gne__c != caseobj.GATCF_Status_gne__c && caseobj.GATCF_Status_gne__c == 'Approved - In Appeal')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Pending Appeal Outcome',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                     
            }
            if (caseobj.RecordTypeId == GESCaseRecordTypeId && caseobj.GES_Status_gne__c != null)// GES Service
            {
                if (caseobj.GES_Status_gne__c.contains('Approved') && trigger.oldMap.get(caseobj.id).GES_Status_gne__c != caseobj.GES_Status_gne__c)
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GES Service Update: Eligibility Established: Approved',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (caseobj.GES_Status_gne__c.contains('Denied') && trigger.oldMap.get(caseobj.id).GES_Status_gne__c != caseobj.GES_Status_gne__c)
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GES Service Update: Eligibility Established: Denied',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
            }
            
            if (caseobj.RecordTypeId == crCaseRecordTypeId && caseobj.Special_Program_Name_gne__c != null)// APA Service
            {                
                if (caseobj.Special_Program_Name_gne__c != trigger.oldMap.get(caseobj.id).Special_Program_Name_gne__c && (starterProgramSet.contains(campaignMap.get(caseobj.id)))){
                    Task taskInsertEC = new Task (OwnerId =  caseobj.OwnerId, 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today().addDays(7), 
                                            Activity_Type_gne__c = 'Confirm eligibility of the Continuous Care Program',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Not Started',
                                            RecordTypeId = TaskRecTypeId,
                                            Creator_Comments_gne__c = creatorComments
                                            );
                    taskList.add(taskInsertEC);             
                }               
                
                if (apaProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.Special_Program_Name_gne__c != trigger.oldMap.get(caseobj.id).Special_Program_Name_gne__c)
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'APA Service Update: Eligibility Pending',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                    taskList.add(taskInsertEC);
                }
                
                if (apaProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.CCP_Approved_gne__c != trigger.oldMap.get(caseobj.id).CCP_Approved_gne__c)
                {
                    if (caseobj.CCP_Approved_gne__c == 'Yes')
                    {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                                WhatId = caseobj.Id, 
                                                ActivityDate = system.today(), 
                                                Activity_Type_gne__c = 'APA Service Update: Eligibility Established: Approved',
                                                Process_Category_gne__c = 'Managing a Case',
                                                Status = 'Completed',
                                                RecordTypeId = TaskRecTypeId 
                                                );
                        taskList.add(taskInsertEC);
                    }
                    else if (caseobj.CCP_Approved_gne__c == 'No')
                    {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                                WhatId = caseobj.Id, 
                                                ActivityDate = system.today(), 
                                                Activity_Type_gne__c = 'APA Service Update: Eligibility Established: Denied',
                                                Process_Category_gne__c = 'Managing a Case',
                                                Status = 'Completed',
                                                RecordTypeId = TaskRecTypeId 
                                                );
                        taskList.add(taskInsertEC);
                    } 
                } 
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.Special_Program_Name_gne__c != trigger.oldMap.get(caseobj.id).Special_Program_Name_gne__c)
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Enrollment Received',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                    system.debug('----------------->Inserted List'+taskList);
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.CCP_Approved_gne__c != trigger.oldMap.get(caseobj.id).CCP_Approved_gne__c)
                {
                    if (caseobj.CCP_Approved_gne__c == 'Yes')
                    {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Approved',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                        system.debug('----------------->Inserted List2'+taskList);
                    }
                    if (caseobj.CCP_Approved_gne__c == 'No')
                    {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Denied',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                        system.debug('----------------->Inserted List3'+taskList);
                    } 
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.Denial_Reason_gne__c != null && trigger.oldMap.get(caseobj.id).Denial_Reason_gne__c == null)
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = caseobj.Id, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Denied',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );
                    taskList.add(taskInsertEC);
                    system.debug('----------------->Inserted List4'+taskList);
                }
            }
            /* DDS Changes */         
	        if (caseobj.RecordTypeId == standardCaseRecordTypeId)
	        {
				//taskList.addAll(GNE_CM_DDS_Eligibility_Case_Helper.createTasksBasedOnOverrideFields(Trigger.oldMap.get(caseobj.id), caseObj, TaskRecTypeId));
                taskList.addAll(GNE_CM_DDS_Eligibility_Case_Helper.createDDSTasks(Trigger.oldMap.get(caseobj.id), caseObj, TaskRecTypeId));
	        }
            
        }
    }
    
    if (CaseId.size() > 0)// Closing all In Progress Services when Case is closed
    {
        lstReqService = [Select id,Name,Requested_Service_Status_gne__c,Case_gne__c,Date_Closed_gne__c,
                        (select status_gne__c,status_date_gne__c,Select_gne__c,Is_MileStone_gne__c,
                        LastModifiedDate from Milestone__r where Not_Applicable_gne__c=false 
                        order by Sequence_gne__c desc) 
                        from GNE_CM_Requested_Services__c 
                        where Case_gne__c in: CaseId and Requested_Service_Status_gne__c = 'In Progress'];
    }
    
    if (lstReqService != null && lstReqService.size() > 0)
    {
        for (GNE_CM_Requested_Services__c ReqSer : lstReqService)
        {
            for (GNE_CM_Milestone_and_Status__c mileStone:ReqSer.Milestone__r)
            {
                system.debug('mileStone--------->'+mileStone);
                
                if (mileStone.Select_gne__c == true)
                {
                    ReqSer.Requested_Service_Status_gne__c = 'Completed';
                    ReqSer.Date_Closed_gne__c = system.now();
                    lstReqServicetoInsert.add(ReqSer);
                    break;
                }
                else
                {
                    ReqSer.Requested_Service_Status_gne__c = 'Cancelled';
                    ReqSer.Cancellation_Reason_gne__c='Case Closed';
                    ReqSer.Date_Closed_gne__c = system.now();
                    lstReqServicetoInsert.add(ReqSer);
                    break;
                }
            }
           
        }
    }
    
    if (lstReqServicetoInsert != null && lstReqServicetoInsert.size() > 0)
    {
        update lstReqServicetoInsert;
    }
    
    if (trigger.isInsert && trigger.isAfter)
    {   
        for (Case caseobj : trigger.new)
        {
            if (caseobj.Patient_Enrollment_Request_gne__c != null)
            {
                PERId.add(caseobj.Patient_Enrollment_Request_gne__c);
                onlineSR.put(caseobj.Patient_Enrollment_Request_gne__c, caseobj.Id);
                CaseRecTypeMap.put(caseobj.Id, caseobj.REcordTypeId);
            }
            
            //PKambalapally 3-6-2014. Fix for PFS-910,911, Task Creator_Comments_gne__c field is increased to 255 and when the value exceeds 255, it is truncated so it fits the field length.
            String creatorComments = caseobj.Enrollment_Not_Complete_Reason_gne__c;
            if (String.isNotBlank(creatorComments)&&creatorComments.length()>=255)
            {
                creatorComments = creatorComments.substring(0,255);
                if (creatorComments.indexOf(';') != -1)
                {
                    creatorComments = creatorComments.substring(0,creatorComments.lastIndexOf(';') - 1);
                }
            }
            
            if (caseobj.Enroll_Comp_Original_Receipt_gne__c == 'No' && caseobj.Enrollment_Not_Complete_Reason_gne__c != null)
            {
                Task taskInsertEC = new Task (OwnerId =  caseobj.OwnerId, 
                                        WhatId = caseobj.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Follow Up on Missing Information',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId,
                                        Creator_Comments_gne__c = creatorComments
                                        );                        
                taskList.add(taskInsertEC);

            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.Approval_Date_gne__c != null)
            {
                Task taskInsertEC = new Task (OwnerId =  caseobj.Foundation_Specialist_gne__c, 
                                        WhatId = caseobj.Id, 
                                        //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                        ActivityDate = Date.valueof(caseobj.Approval_Date_gne__c).addDays(335), 
                                        Activity_Type_gne__c = 'Perform GATCF Annual Renewal',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Not Started',
                                        RecordTypeId = TaskRecTypeId,
                                        Creator_Comments_gne__c = creatorComments
                                        );                        
                taskList.add(taskInsertEC);
            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId)
            {
                Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = caseobj.Id, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'GATCF Service Update: Enrollment Pending',
                                        Process_Category_gne__c = 'Access to Care',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );                        
                taskList.add(taskInsert);
            }

            //AS  Changes 1/17/2013
            if(caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.Date_Discussed_gne__c != null)
            {
                Task taskInsert = new Task (OwnerId =  genericUserID, 
                                    WhatId = caseobj.Id, 
                                    ActivityDate = caseobj.Date_Discussed_gne__c.addMonths(3), 
                                    Activity_Type_gne__c = 'Follow-up on Insurance Information',
                                    Process_Category_gne__c = 'Access to Care',
                                    Status = 'Not Started',
                                    RecordTypeId = TaskRecTypeId 
                                    );                  
                taskList.add(taskInsert);
            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId && caseobj.GATCF_Status_gne__c != null)// GATCF Services
            {
                if (!caseobj.GATCF_Status_gne__c.contains('Pending'))
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            //Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Enrollment Complete',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
            }
            
            if (caseobj.RecordTypeId == GATCFStandardCaseRecordTypeId)
            {
                if (caseobj.Contingent_Determination_gne__c=='Approved')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Contingent Eligibility',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (caseobj.Eligibility_gne__c != null)
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Financial Obtained',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (caseobj.GATCF_Status_gne__c != null && (caseobj.GATCF_Status_gne__c.startsWith('Approved') || caseobj.GATCF_Status_gne__c.startsWith('Denied')) && caseobj.GATCF_Status_gne__c != 'Approved - Contingent Enrollment'  && caseobj.GATCF_Status_gne__c != 'Approved - In Appeal')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Eligibility Established',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (caseobj.GATCF_Status_gne__c == 'Approved - In Appeal')
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Pending Appeal Outcome',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                     
            }
            
            if (caseobj.RecordTypeId == GESCaseRecordTypeId && caseobj.GES_Status_gne__c != null)// GES Service
            {
                if (caseobj.GES_Status_gne__c.contains('Approved'))
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GES Service Update: Eligibility Established: Approved',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (caseobj.GES_Status_gne__c.contains('Denied'))
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GES Service Update: Eligibility Established: Denied',
                                            Process_Category_gne__c = 'Access To Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
            }
            
            if (caseobj.RecordTypeId == crCaseRecordTypeId && caseobj.Special_Program_Name_gne__c != null)// APA Service
            {
                if (apaProgramSet.contains(campaignMap.get(caseobj.id)))
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'APA Service Update: Eligibility Pending',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (apaProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.CCP_Approved_gne__c != null)
                {
                     if (caseobj.CCP_Approved_gne__c == 'Yes')
                     {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'APA Service Update: Eligibility Established: Approved',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                     }
                     else if (caseobj.CCP_Approved_gne__c == 'No')
                     {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'APA Service Update: Eligibility Established: Denied',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                     } 
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)))
                {
                     Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Enrollment Received',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    taskList.add(taskInsertEC);
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)))
                {                
                    Task taskInsertEC = new Task (OwnerId =  caseobj.OwnerId, 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today().addDays(7), 
                                            Activity_Type_gne__c = 'Confirm eligibility of the Continuous Care Program',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Not Started',
                                            RecordTypeId = TaskRecTypeId,
                                            Creator_Comments_gne__c = creatorComments
                                            );                        
                    taskList.add(taskInsertEC);                 
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.CCP_Approved_gne__c != null)
                {
                     if (caseobj.CCP_Approved_gne__c == 'Yes')
                     {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Approved',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                     }
                     
                     if (caseobj.CCP_Approved_gne__c == 'No')
                     {
                        Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = caseobj.Id, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Denied',
                                            Process_Category_gne__c = 'Managing a Case',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );
                        taskList.add(taskInsertEC);
                     } 
                }
                
                if (starterProgramSet.contains(campaignMap.get(caseobj.id)) && caseobj.Denial_Reason_gne__c != null)
                {
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                        WhatId = caseobj.Id, 
                                        ActivityDate = system.today(), 
                                        Activity_Type_gne__c = 'Starter Service Update: Eligibility Established: Denied',
                                        Process_Category_gne__c = 'Managing a Case',
                                        Status = 'Completed',
                                        RecordTypeId = TaskRecTypeId 
                                        );
                    taskList.add(taskInsertEC);
                }
            }
        }
        
        if (PERId != null && PERId.size() > 0)//Auto Create Service from PER
        {
            lstPatientEnrollmentRequest = [Select id,GATCF_Patient_Assistance_gne__c, Benefits_Investigation_Prior_Auth_gne__c from Patient_Enrollment_Request_gne__c where id IN :PERId];
            
            if (lstPatientEnrollmentRequest != null && lstPatientEnrollmentRequest.size() > 0)
            {
                for (Patient_Enrollment_Request_gne__c objPER : lstPatientEnrollmentRequest)
                {
                    if (objPER.Benefits_Investigation_Prior_Auth_gne__c == true  && CaseRecTypeMap.get(onlineSR.get(objPER.Id)) == crCaseRecordTypeId)
                    {
                        GNE_CM_Service_View_Utils.createNewService('BI/PA', onlineSR.get(objPER.Id), 'Online');
                    }
                    if (objPER.GATCF_Patient_Assistance_gne__c == true  &&CaseRecTypeMap.get(onlineSR.get(objPER.Id)) == GATCFStandardCaseRecordTypeId)
                    {
                        GNE_CM_Service_View_Utils.createNewService('GATCF Patient Assistance',onlineSR.get(objPER.Id), 'Online');
                    }
                }
            }
        }
    }

    List<Task> tasksToInsert = new List<Task>();
    
    // get more tasks to be inserted based on some GATCF rules
    tasksToInsert.addAll(GNE_CM_Case_Trigger_Util.getTasksOnCaseInsertUpdate(Trigger.new, Trigger.isInsert ? null : Trigger.oldMap, Trigger.isInsert));
    
    System.debug('Tasks from workflows: ' + tasksToInsert.size() + ': ' + tasksToInsert);
    System.debug('Task list: ' + taskList.size() + ': ' + taskList);
    
    if (taskList.size() > 0 && trigger.isAfter)
    {
        tasksToInsert.addAll(taskList);
    }
    
    if (!tasksToInsert.isEmpty())
    {
        errorLogList = new List<Error_Log_gne__c>();
        //GNE_CM_case_trigger_monitor.setTriggerInProcessCaseUpdate();
        SR = database.insert(tasksToInsert, false);
        
        for (database.saveresult lsr:SR)
        {
            if (!lsr.issuccess())
            {
                for (Database.Error err : lsr.getErrors())
                {                       
                    errMessage = 'Failed to create task ' + err.getMessage();
                    errorLogList.add(GNE_CM_MPS_Utils.createError('Case', 'High', 'GNE_CM_Update_Case_Service_Status', 'Trigger', errMessage));
                }
            }
        }       
        if (errorLogList.size() > 0)
        {
            insert errorLogList;
        }
            }
                        
    if (trigger.isInsert)
    {
        //send email for new task created
        if (user_id.size()>0)
        {
            user_info=new Map<Id, User>([Select email, Id from user where Id IN :user_id]);
        }

        if (trigger.new.size()==1)
        {
            for (Case cas : trigger.new) 
            {
                try
                {
                    mail = new Messaging.SingleEmailMessage();
                    if (user_info.containsKey(cas.Case_Manager__c))
                    {
                       String[] toAddresses = new String[] { user_info.get(cas.Case_Manager__c).Email };
                       mail.setToaddresses(toAddresses);    
                       // Specify the subject line for your email address.
                        mail.setSubject('STAT BI - '+cas.casenumber );

                        // Specify the text content of the email.
                        mail.setHtmlBody('This case has been marked as a STAT BI, please complete BI and communicate benefits to the MD office. Thank you.');                   
                        Messaging.sendEmail(new Messaging.singleEmailMessage[] { mail });
                    }
                 }       
                catch (exception e)
                {
                   cas.adderror('Error encountered while sending email '+e.getmessage());
                 }
            }
        }
        
        user_id.clear();
        user_info.clear();
    } // end of if trigger.isinsert
    
    system.debug('WITH TASKS: ' + Limits.getQueries());
}