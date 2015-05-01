/*------------      Name of trigger : GNE_CM_caseID_prepopulate   --------------*/
/*------------      Created by : GDC                              --------------*/
/*------------      Last Modified on :05/15/2009, added new BI type values in validations PL-25---------*/
/*------------      Last Modified on :10/19/2009, by Digamber Prasad added new Task for Actemra C&R Standard Case---------*/
/*------------      Last Modified on :02/25/2010, by Shweta Bhardwaj for Enhancement T-372C---------*/
/*------------      Last Modified on :05/31/2012, by Kanima Singh for CMR4 Release---------*/
/*------------      twardoww [02/20/2014]: PFS-1083 related : do not stamp BI_Obtained_Date_gne__c if it's already been set in the eBI flow---------*/
/*------------      PKambalapally  3/4/2014 PFS-1084. 
                                        Added checks using GNE_CM_EBI_Util and also the fields on bi, similar to how the 'MPS Instant BI' is calculated on the UI.
/*------------      PKambalapally  3/10/2014 PFS-1084.                                         
                                        Bulkified the code to query for Cases before the for loop on BIs.
----------*/
trigger GNE_CM_caseID_prepopulate on Benefit_Investigation_gne__c (before insert,before update,after insert,after update) 
{
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger || GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_caseID_prepopulate')){
        return;
    }
    
    Set<Id> insidset = new Set<Id>();    
    Map<Id, Insurance_gne__c> Ins_map;
    Set<String> variable = new Set<String>{'AllObjects_CaseClosed_48hrs_chk_Profiles', 'BI_Skip_Auto_Task_ESB_Admin','BI_Supervisor_Profiles'};
    List<Environment_Variables__c> env_var = new List<Environment_Variables__c>();
    Map<String, String> Case_Profiles = new Map<String, String>();
    Map<String, String> skip_auto_task_Profile = new Map<String, String>();
    Map<String, String> BI_Supervisor_Profile = new Map<String, String>();
    String ProfileId = Userinfo.getProfileId();
    String Profile_name ='';
    String errMessage = '';
    List<Error_Log_gne__c> errorLogList = new List<Error_Log_gne__c>();
    List<Alerts_gne__c> autoAlertList = new List<Alerts_gne__c>();
    List<Task> tsk_list = new List<Task>();
    String objectName, errorLevel, snippetName, codeType, error;
    
    //PKambalapally  3/4/2014 PFS-1084. Added to be used for instantBI task.
    // twardoww [03/17/2014]: remove once EBI-193 is in effect
    //ID TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
    final String INSTANT_BI_YES_AUTH_NEEDED = 'Yes, Auth needed';  
    final String INSTANT_BI_YES = 'Yes';
    final String INSTANT_BI_NO = 'No'; 
    String mpsInstantBi;
    
    if (Trigger.isAfter && Trigger.isUpdate)
    {
        // check if BI Publish date has changed, if yes, reset BI Reviewed fields on the associated case
        GNE_CM_BI_Utils.resetBIReviewed(Trigger.oldMap, Trigger.newMap);
        
        // twardoww [03/17/2014]: create a Task for every BI record meeting criteria; refer to EBI-193
        Set<Id> caseIds = new Set<Id>();
        for (Benefit_Investigation_gne__c bi : Trigger.new) {
        	caseIds.add(bi.Case_BI_gne__c);
        }
        caseIds.remove(null);
        Map<Id,Case> caseIdsToCases = new Map<Id,Case>([
        	SELECT Id, Case_Manager__c, Patient_Enrollment_Request_gne__c, RecordType.Name
        	FROM Case
        	WHERE Id IN :caseIds
        ]);
        
        List<Benefit_Investigation_gne__c> validBIs = new List<Benefit_Investigation_gne__c>();
        for (Benefit_Investigation_gne__c bi : Trigger.new) {
        	Case c = caseIdsToCases.get(bi.Case_BI_gne__c);
        	if (bi.Case_BI_gne__c != null && Trigger.oldMap.get(bi.Id).Case_BI_gne__c != bi.Case_BI_gne__c
        		&& c != null && c.RecordType.Name == 'C&R - Standard Case' && c.Patient_Enrollment_Request_gne__c == bi.Patient_Enrollment_Request_gne__c
        		&& bi.BI_Method_gne__c == GNE_CM_EBI_Util.MPS_INSTANT_BI_METHOD
        	) {
        		validBIs.add(bi);
        	}
        }
        Map<Id,Task> biIdsToTasks = GNE_CM_BI_Utils.createReviewBiPriorAuthorizationRequiredTasks(validBIs);
        if (!biIdsToTasks.isEmpty()) {
        	tsk_list.addAll(biIdsToTasks.values());
        }
    }
    
    Database.saveresult[] SR;
    try
    {
        //JH 10/21/2013 - SOQL Optimization
        Profile_name = GNE_SFA2_Util.getCurrentUserProfileName();
        env_var = GNE_CM_Environment_variable.get_env_variable(variable);
        for(integer MI = 0; MI<env_var.size(); MI++)
        {   
            if(env_var[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
                Case_Profiles.put(env_var[MI].Value__c, env_var[MI].Value__c);
            
            if(env_var[MI].Key__c == 'BI_Skip_Auto_Task_ESB_Admin')
                skip_auto_task_Profile.put(env_var[MI].Value__c, env_var[MI].Value__c); 
            
            if(env_var[MI].Key__c == 'BI_Supervisor_Profiles')
                BI_Supervisor_Profile.put(env_var[MI].Value__c, env_var[MI].Value__c);     
        }
        
    }
    catch(exception e)
    {
        for(Benefit_Investigation_gne__c bierr :Trigger.new)
            bierr.adderror('Error encountered while getting Profile Name: ' + e.getmessage());
    }   //end of catch
    
    // twardoww [03/17/2014]: remove once EBI-193 is in effect
    //Set<Id>caseIdSetForInstantBI = new Set<Id>();
    for(Benefit_Investigation_gne__c b : Trigger.new)
    {
        try
        {   
            if (b.BI_Insurance_gne__c != null)
            {
                insidset.add(b.BI_Insurance_gne__c);                
            }//end of if on b.BI_Insurance_gne__c
            //PKambalapally  3/10/2014 PFS-1084. Bulkified
            
            // twardoww [03/17/2014]: remove once EBI-193 is in effect
            /*if(b.Case_BI_gne__c !=null){
                caseIdSetForInstantBI.add(b.Case_BI_gne__c);
            }*/
        }   //end of try
        catch(exception e)
        {
            b.adderror('Error encountered in creation of insurance list for BI' + e.getmessage());
        }   //end of catch
    } //end of for
    system.debug('INSIDSET: ' + insidset);
    try
    {   
        Ins_map = new Map<Id, Insurance_gne__c>([select Rank_gne__c, Group_Num_gne__c,Subscriber_Num_gne__c,Subscriber_Name_gne__c,
                                                        Subscriber_First_Name_gne__c,Policy_Number_gne__c,Patient_Insurance_gne__c,
                                                        Payer_gne__c,Case_Insurance_gne__c, Case_Insurance_gne__r.Status, 
                                                        Case_Insurance_gne__r.ClosedDate, Case_Insurance_gne__r.recordtype.Name,
                                                        Case_Insurance_gne__r.ownerid,Case_Insurance_gne__r.Reimbursement_Specialist_gne__c, 
                                                        Product_Insurance_gne__c 
                                                    from Insurance_gne__c 
                                                    where Id  in :insidset]);
    }   //end of try
    catch(exception e)
    {
        for(Benefit_Investigation_gne__c bb :Trigger.new)
            bb.adderror('Error encountered while creating Insurance Map' + e.getmessage());
    }   //end of catch
    
    // twardoww [03/17/2014]: remove once EBI-193 is in effect
    //PKambalapally  3/10/2014 PFS-1084. Bulkified. Get all cases in one query.
    //Run this query only for After Update trigger.
    /*Map<Id,Case>caseIdToCaseMap = new Map<Id,Case>();
    if(Trigger.isAfter && Trigger.isUpdate){
        try{
            caseIdToCaseMap = new Map<Id,Case>([select Case_Manager__c,Patient_Enrollment_Request_gne__c,recordType.Name from Case where id in:caseIdSetForInstantBI]);
        }catch(Exception e){
            System.debug('Error in querying for Case==========='+e.getMessage());
            Error_Log_gne__c el = GNE_CM_MPS_Utils.createError('Benefit Investigation','High','Query Cases', 'Trigger',e);
            insert el;
        }    
    }*///end check for After Update trigger.
    
    
                        
    Map<String, Schema.RecordTypeInfo> mapActemraRecTypeInfo = Schema.SObjectType.Task.getRecordTypeInfosByName();
    
    for (Benefit_Investigation_gne__c b :Trigger.new)
    {   
        try
        {
            if (trigger.isBefore)
            {
                System.debug('Insurance: ' + b.BI_Insurance_gne__c);
                if (b.BI_Insurance_gne__c != null && Ins_map.containsKey(b.BI_Insurance_gne__c))
                {
                    System.debug('Update subscriber: ' + Ins_map.get(b.BI_Insurance_gne__c).Subscriber_Num_gne__c);
                    //b.Case_BI_gne__c=Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c; krzyszwi commented out per SFDC-76 build 3 req
                    b.Product_BI_gne__c=Ins_map.get(b.BI_Insurance_gne__c).Product_Insurance_gne__c;
                    b.Payer_BI_gne__c=Ins_map.get(b.BI_Insurance_gne__c).Payer_gne__c;
                    b.Patient_BI_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Patient_Insurance_gne__c;
                    
                    system.debug('[RK] Updated BI with patient ' + b.Patient_BI_gne__c);
                    
                    b.Subscriber_Num_BI_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Subscriber_Num_gne__c;

                    //Do not allow user to edit/create BI when case has been closed for 48 hours
                    if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c!=null)
                    {
                        if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.Status.startsWith('Closed') && System.now() >= (Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.ClosedDate.addDays(2)) && Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)))  
                        {
                            b.adderror('Benefit Investigation cannot be created/edited once the case associated with selected Insurance has been Closed for 48 hours or more.');
                        }//end of closed case check
                    } 
                }   //end of if b.BI_Insurance_gne__c is not null 
                                
                //T-372C
                if(trigger.isupdate)
                {
                    if(b.No_Denial_Letter_Available_gne__c != trigger.oldmap.get(b.Id).No_Denial_Letter_Available_gne__c) 
                    {
                        if(!BI_Supervisor_Profile.containsKey(Profile_name))
                            b.No_Denial_Letter_Available_gne__c.adderror('Field is not editable.');
                    }
                }
                else
                if(b.No_Denial_Letter_Available_gne__c == true && !BI_Supervisor_Profile.containsKey(Profile_name))
                    b.No_Denial_Letter_Available_gne__c.adderror('Field is not editable.');      
                
                //JH 10/21/2013 GNE_CM_MPS_BI_Publish_Date_Update WFR Replacement
                if(trigger.isUpdate) {
                    if(b.Display_on_Web_if_PAN_valid_gne__c!=trigger.oldmap.get(b.Id).Display_on_Web_if_PAN_valid_gne__c && b.Display_on_Web_if_PAN_valid_gne__c=='Yes' && b.IsPANValid_gne__c=='True') {
                        b.GNE_CM_MPS_Publish_Date__c = System.now();
                    }
                } else if (trigger.isInsert) {
                    if(b.Display_on_Web_if_PAN_valid_gne__c=='Yes' && b.IsPANValid_gne__c=='True') {
                        b.GNE_CM_MPS_Publish_Date__c = System.now();
                    }
                }
            }
            
            if(Trigger.isAfter)
            {
                if(b.BI_Insurance_gne__c!=null && Ins_map.containsKey(b.BI_Insurance_gne__c)&& b.BI_BI_Status_gne__c !=null && b.Product_BI_gne__c !=null && b.BI_Type_gne__c !=null )
                {
                    if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c !=null)
                    {
                        if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.recordtype.Name == 'C&R - Standard Case'
                                && b.BI_BI_Status_gne__c == 'Denied' && b.Product_BI_gne__c =='Raptiva' 
                                && b.BI_Type_gne__c == 'Full BI' && !skip_auto_task_Profile.containsKey(profile_name))
                        {
                            Task taskInsert = new Task (OwnerId =  Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.ownerid, 
                            Subject = 'Follow up on payer denial from specialty pharmacy triage', WhatId = b.Id,
                            Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,ActivityDate=system.today(), 
                            Activity_Type_gne__c = 'Follow-up on payer denial from SP triage', Process_Category_gne__c = 'Managing a Case');
                            tsk_list.add(taskInsert);                               
                        }
                    }
                }                
                
                //Added by Digamber Prasad on 10/19/2009 to add a Task for Actemra - C&R Standard Case
                //Modified by Kishore on 1/15/2010 removing the product condition (it means that this activity needs to be created for all products).
                if(Trigger.isInsert){
                    if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.recordtype.Name == 'C&R - Standard Case'
                            && !skip_auto_task_Profile.containsKey(profile_name)){
                        String recTaskTypeID =  mapActemraRecTypeInfo.get('CM Task').getRecordTypeId(); // Id of CM Task record type
                        Task taskInsert = new Task (OwnerId =  b.CreatedById, 
                                                WhatId = b.Id, 
                                                Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                                ActivityDate = system.today(), 
                                                Activity_Type_gne__c = 'Perform Benefit Investigation',
                                                Process_Category_gne__c = 'Investigating Benefits',
                                                Status = 'Completed',
                                                RecordTypeId = recTaskTypeID
                                                );                        
                        tsk_list.add(taskInsert);
                    }                    
                }
                if(Trigger.isInsert)// new Completed task for Service View
                {
                    if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.recordtype.Name == 'C&R - Standard Case'
                            && !skip_auto_task_Profile.containsKey(profile_name) && b.BI_BI_Status_gne__c == 'BI Pending')
                    {
                        String recTaskTypeID =  mapActemraRecTypeInfo.get('CM Task').getRecordTypeId(); // Id of CM Task record type
                        Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                                WhatId = b.Id, 
                                                Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                                ActivityDate = system.today(), 
                                                Activity_Type_gne__c = 'Service Update: BI Response Pending',
                                                Process_Category_gne__c = 'Investigating Benefits',
                                                Status = 'Completed',
                                                RecordTypeId = recTaskTypeID
                                                );                        
                        tsk_list.add(taskInsert);
                    }                    
                }
                if(Trigger.isUpdate)// new Completed task for Service View
                {
                    if(Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__r.recordtype.Name == 'C&R - Standard Case'
                            && !skip_auto_task_Profile.containsKey(profile_name) && b.BI_BI_Status_gne__c == 'BI Pending'
                            && Trigger.oldMap.get(b.Id).BI_BI_Status_gne__c != b.BI_BI_Status_gne__c)
                    {
                        String recTaskTypeID =  mapActemraRecTypeInfo.get('CM Task').getRecordTypeId(); // Id of CM Task record type
                        Task taskInsert = new Task (OwnerId =  UserInfo.getUserId(), 
                                                WhatId = b.Id, 
                                                Case_Id_gne__c = Ins_map.get(b.BI_Insurance_gne__c).Case_Insurance_gne__c,
                                                ActivityDate = system.today(), 
                                                Activity_Type_gne__c = 'Service Update: BI Response Pending',
                                                Process_Category_gne__c = 'Investigating Benefits',
                                                Status = 'Completed',
                                                RecordTypeId = recTaskTypeID
                                                );                        
                        tsk_list.add(taskInsert);
                    }
                    
                    // twardoww [03/17/2014]: remove once EBI-193 is in effect 
                    /*------------Prashanth Kambalapally, 03/4/2014 - PFS-1084 
                            Added checks using GNE_CM_EBI_Util and also the fields on bi, similar to how the 'MPS Instant BI' is calculated on the UI.
                   */
                    //Run this code for After Update only.
               
                    //Case c = caseIdToCaseMap.get(b.Case_BI_gne__c);
                    
                    // Logic for creating a task if MPS Instant BI value is yes
                    /*if (b.Case_BI_gne__c!=null && Trigger.oldMap.get(b.Id).Case_BI_gne__c != b.Case_BI_gne__c
                         && c!=null && c.recordtype.Name == 'C&R - Standard Case'&& c.Patient_Enrollment_Request_gne__c == b.Patient_Enrollment_Request_gne__c
                         && b.BI_Method_gne__c!=null && b.BI_Method_gne__c=='MPS Instant BI')// Standard C&R Case
                    {
                        System.debug('CaseID========='+b.Case_BI_gne__c);*/
                        /* PKambalapally 3/10/2014. PFS-1084. Bulkified. 
                        Query needed only for future enhancements where there'll be multiple BIs per Case.
                        List<Benefit_Investigation_gne__c> bis = [SELECT Id, Name, IN_Prior_Authorization_Required_gne__c, IN_Predetermination_Available_gne__c, IN_Notification_Required_gne__c,
                                                                    BI_Method_gne__c, BI_Insurance_gne__c, IN_Admin_Prior_Auth_Required_gne__c, IN_Admin_Predetermination_Available_gne__c
                                                                    //,
                                                                   // (select id 
                                                                    //  FROM Tasks 
                                                                    //  WHERE Activity_Type_gne__c = 'Review BI/Prior Authorization Results' 
                                                                    //  AND Process_Category_gne__c = 'Managing A Case' 
                                                                    //  AND Status<>'Completed')
                                                                    FROM Benefit_Investigation_gne__c
                                                                    WHERE Patient_Enrollment_Request_gne__c = :perId
                                                                    AND BI_Method_gne__c = 'MPS Instant BI'
                                                                    AND Case_BI_gne__c = :b.Case_BI_gne__c 
                                                                    order by createddate desc 
                                                                    limit 1
                                                                  ];
                    
                        System.debug('[RK] Found BIs: ' + bis.size());
                        */
                        //{
                            /*????????????  FUTURE TODO PER BSA ROSANO SILVERIA ?????????????
                                When there are multiple BIs for a case, have the task only on the latest BI.
                                What to do when there are Tasks with other BIs that are not closed?
                            */
                          
                            /*if (String.isBlank(GNE_CM_EBI_Util.instantBiDisplayCriteriaError(c.Patient_Enrollment_Request_gne__c))) {
                                mpsInstantBi = (
                                    (String.isNotBlank(b.IN_Prior_Authorization_Required_gne__c) && b.IN_Prior_Authorization_Required_gne__c.equalsIgnoreCase('Yes') )||
                                    (String.isNotBlank(b.IN_Predetermination_Available_gne__c) && b.IN_Predetermination_Available_gne__c.equalsIgnoreCase('Yes')) ||
                                    (String.isNotBlank(b.IN_Notification_Required_gne__c) && b.IN_Notification_Required_gne__c.equalsIgnoreCase('Yes')) ||
                                    (String.isNotBlank(b.IN_Admin_Prior_Auth_Required_gne__c) && b.IN_Admin_Prior_Auth_Required_gne__c.equalsIgnoreCase('Yes')) ||
                                    (String.isNotBlank(b.IN_Admin_Predetermination_Available_gne__c) && b.IN_Admin_Predetermination_Available_gne__c.equalsIgnoreCase('Yes'))
                                ) ? INSTANT_BI_YES_AUTH_NEEDED : INSTANT_BI_YES;
                            }
                            Set<String> instantBIYesStatuses = new Set<String>{INSTANT_BI_YES_AUTH_NEEDED,INSTANT_BI_YES};
                            System.debug('instantBIYesStatuses===='+instantBIYesStatuses);
                            System.debug('mpsInstantBi===='+mpsInstantBi);
                            
                           if(String.isNotEmpty(mpsInstantBi) && instantBIYesStatuses.contains(mpsInstantBi)){
                                Task newTask = new Task (OwnerId =  c.Case_Manager__c, 
                                                            WhatId = b.Id, 
                                                            ActivityDate = system.today(), 
                                                            Activity_Type_gne__c = 'Review BI/Prior Authorization Results',
                                                            Process_Category_gne__c = 'Managing A Case',
                                                            Status = 'Not Started',
                                                            RecordTypeId = TaskRecTypeId
                                                           );   
                                System.debug('[RK] New task: ' + newTask);                     
                                tsk_list.add(newTask);
                           }//end check on mpsInsantBi
                     }*///end check on RT
                
                     /*------------End changes for Prashanth Kambalapally, 03/4/2014 - PFS-1084 */                   
                }//end check for Trigger.isUpdate
            }//End check for Trigger.isAfter 
        }   //end of try
        
        catch(Exception e)
        {
            b.adderror('Error encountered while filling information from Insurance to BI: ' + e.getmessage() + ' [GNE_CM_caseID_prepopulate.trigger, line ' + e.getLineNumber() + ']');
        }
    } //end of for
    
    if(autoAlertList.size() > 0 && trigger.isafter) {
        errorLogList = new List<Error_Log_gne__c>();
        SR = database.insert(autoAlertList, false);
        for(database.saveresult lsr:SR)
        {
            if(!lsr.issuccess())
            {   
                for(Database.Error err : lsr.getErrors())
                {                       
                    errMessage = 'Failed to auto create Alert for Case ' + err.getMessage();
                    errorLogList.add(GNE_CM_MPS_Utils.createError('Benefit Investigation', 'High', 'Auto Create Alert', 'Trigger', errMessage));
                }
            }
        }       
        if(errorLogList.size() > 0)
        {
            insert errorLogList;
        }
    }
    if(tsk_list.size()>0 && trigger.isafter)
    {
        errorLogList = new List<Error_Log_gne__c>();
        SR = database.insert(tsk_list, false);
        for(database.saveresult lsr:SR)
        {
            if(!lsr.issuccess())
            {
                //Krzysztof Wilczek - 29/03/2011 - this piece of error logging is not working since you cannot get id of failed record.                             
                //trigger.newMap.get(lsr.getId()).addError('Error encountered in creation of Task' + lsr.getErrors()[0].getmessage());
                //error logging to Error Log implemented instead
                for(Database.Error err : lsr.getErrors())
                {                       
                    errMessage = 'Failed to update Case ' + err.getMessage();
                    GNE_CM_MPS_Utils.createError('Benefit Investigation', 'High', 'GNE_CM_caseID_prepopulate', 'Trigger', errMessage);
                }
            }
        }       
        if(errorLogList.size() > 0)
        {
            insert errorLogList;
        }
    } 
    Case_Profiles.clear();  
    Ins_map.clear();    //to clear the map once trigger records had been processed
    insidset.clear();   //to clear the set once trigger records had been processed
    skip_auto_task_Profile.clear();



    //Prathap Rao.
    // The below set of code has been written  
    // To set : Status on Alert object to be 'Closed' 
    //--> When? --> Display on Web status = 'No' on Benefit Investigation Object or IS PAN Valid?. 
    Set<Id> BIIdset = new Set<Id>();
    for (Integer i = 0; i < Trigger.new.size(); i ++)
    {
        BIIdset.add(Trigger.new[i].Id);
    }
    List<Alerts_gne__c> AlertList=[select Id,case_gne__c,Activity_whatId_gne__c,Status_gne__c from Alerts_gne__c
                                where case_gne__c!= null 
                                And Activity_whatId_gne__c!=null 
                                And Status_gne__c ='Visible in Portal'
                                And Activity_whatId_gne__c In: BIIdset];    
    List<Alerts_gne__c> alertsToUpdate = new List<Alerts_gne__c>();
    for(Benefit_Investigation_gne__c BIList :trigger.new)
    {
        if(BIList.case_BI_gne__c != null )
        {
            for(Alerts_gne__c alertItem:AlertList)
            {  
                if( alertItem.case_gne__c == BIList.case_BI_gne__c
                        && alertItem.Activity_whatId_gne__c == BIList.Id)
                {
                    if
                    (
                    (BIList.Display_on_Web_if_PAN_valid_gne__c != null 
                    && BIList.Display_on_Web_if_PAN_valid_gne__c =='No')
                    ||
                    ( BIList.IsPANValid_gne__c != null
                    && BIList.IsPANValid_gne__c =='False')
                    )
                    {
                        System.debug('Setpoint : Display on web status in BI' +  BIList.Display_on_Web_if_PAN_valid_gne__c );
                        System.debug('Setpoint : Status on Alert before update ' + alertItem.Status_gne__c);
                        System.debug('Setpoint : IS PAN Valid?' +  BIList.IsPANValid_gne__c );
                        alertItem.Status_gne__c='Closed';
                        datetime myDateTime = datetime.now();
                        String mydtstring = mydatetime.format();                   
                        alertItem.Comments_gne__c = 'A new Benefits Investigation report related to this patient\'s case is available.  As needed, contact your Genentech Access Solutions Specialist for assistance.  (Note: On ' + mydtstring +' this alert was automatically closed because the Display on Web (if PAN valid) was manually changed from "Yes" to "No".)';
                        alertsToUpdate.add(alertItem);
                    }
                }
            }
        }
    }
    
    try
    {       
        update alertsToUpdate;
        System.debug('SUCCESS: Updated Alerts object Sucessfully');
    }
    catch(DMLException ex)
    {
        System.debug('Setpoint:In DML catch Block'+  ex + 'DML Exception Occured');
    }
    catch(Exception e)
    {
        System.debug('Setpoint: In Genereal catch Block'+  e + 'Exception Occured');
    }    
    
    //GDC - 8-4-2011 Code added to auto populate the BI As (Rank) to related Insurance Rank value. 
    if(trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            try
            {   
                for(Benefit_Investigation_gne__c bi : trigger.new)
                {                    
                    //KC 9/26/11: Added as part of CMR3-Stream3 - Stamp the BI obtained date for only new BI records not udpate records.
                    //twardoww [02/20/2014]: PFS-1083 related : do not stamp BI_Obtained_Date_gne__c if it's already been set in the eBI flow
                    if (BI.BI_Obtained_Date_gne__c != null && (BI.BI_Method_gne__c == GNE_CM_EBI_Util.EBI_METHOD || BI.BI_Method_gne__c == GNE_CM_EBI_Util.MPS_INSTANT_BI_METHOD)) {
                        continue;
                    }
                    BI.BI_Obtained_Date_gne__c = system.now();
                }
            }
            catch(exception e)
            {
                system.debug('Error: ' + e.getMessage());
            }
        }
    }   
    // code ends here
    
    //******************************************** Changes related to CMR4 ****************************************************************//
    //KS: CMR4 changes start here
    
    if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert))
    {
        system.debug('inside CMR4 changes....');
        List<Case_Metric_Table__c> CMListToInert = new List<Case_Metric_Table__c>(); 
        List<Case_Metric_Table__c> CMListToUpdate = new List<Case_Metric_Table__c>();
        Set<Id> CaseMetricSet = new Set<Id>();
        Set<Id> BISet = new Set<Id>();
        List<Case> CaseList = new List<Case>();
        List<Task> TaskList = new List<Task>();
        Set<Id> CaseIdSet = new Set<Id>();
        List<Case_Metric_Table__c> CMTList = new List<Case_Metric_Table__c>(); 
        List<Case_Metric_Table__c> CaseMetrixTable = new List<Case_Metric_Table__c>(); 
        Map<String, Decimal> InsertBusinessValueMap = new Map<String, Decimal>();
             
        Map<Id,Map<String, Decimal>>  UpdateBusinessValueMap = new Map<Id,Map<String, Decimal>>();  
        Map<String, Decimal> UpdateBusinessValues = new  Map<String, Decimal>();
        Map<id,DateTime> BITATopenDateMap = new Map<id,DateTime>();
        Map<id,DateTime> BITATcloseDateMap = new Map<id,DateTime>();   
        
        GNE_CM_Businesshours_Calc  Bhours = new GNE_CM_Businesshours_Calc();  
         
        String StaffCredited = '';
        DateTime TAT_Start_Date;
        DateTime TAT_End_Date;
        String BI_ActivityID;
        Id CaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Standard Case').getRecordTypeId();
        GNE_CM_Metrics_Utility CMMetricObj = new GNE_CM_Metrics_Utility();
        
       try
       {       
            for(Benefit_Investigation_gne__c BInv : trigger.new)
            {
                if(BInv.BI_BI_Status_gne__c != 'BI Pending' && trigger.isInsert)
                {
                    CaseIdSet.add(BInv.Case_BI_gne__c);
                }
                else if(BInv.BI_BI_Status_gne__c != 'BI Pending' && BInv.BI_BI_Status_gne__c != trigger.oldMap.get(BInv.Id).BI_BI_Status_gne__c)
                {
                    CaseIdSet.add(BInv.Case_BI_gne__c);
                }
            }
            
            if(CaseIdSet.Size() > 0)
            {
                CaseList = [select id, recordtypeid, (Select id, Name, Case_BI_gne__c,BI_Obtained_Date_gne__c, BI_BI_Status_gne__c, CreatedDate from Benefit_Investigation_gne__r where BI_BI_Status_gne__c != 'BI Pending') from Case where recordtypeid =: CaseRecTypeId and id in: CaseIdSet];
            }
            
            if(CaseList.Size() > 0)
            {
                for(Case cs : CaseList)
                {
                    if(cs.Benefit_Investigation_gne__r.size() > 0)
                    {
                        for(Benefit_Investigation_gne__c BI : cs.Benefit_Investigation_gne__r)
                        {
                            if(BI.BI_BI_Status_gne__c != 'BI Pending')
                            {
                                TAT_End_Date = system.now();
                                break;
                            }
                        }
                    }
                }
            }
            
            TaskList = [Select id, CreatedDate, WhatId from Task where whatid in: CaseIdSet and (subject ='Perform Benefit Investigation for Appeals Referral' OR subject = 'Perform Benefit Investigation' OR subject = 'Reverify Benefit Investigation' OR subject = 'Perform ProActive Benefit Investigation') order by CreatedDate DESC];
          
            if(TaskList != null && TaskList.Size() > 0)
            {
                TAT_Start_Date = TaskList[0].CreatedDate;
                BI_ActivityID = TaskList[0].Id;
            }
            
            if(TAT_Start_Date != null)
            {
              
                InsertBusinessValueMap = Bhours.CalculateBusinessHoursDates(TAT_Start_Date , TAT_End_Date );
                for(Benefit_Investigation_gne__c bi : trigger.new)
                {  
                    BISet.add(bi.id);
                        
                    Case_Metric_Table__c CaseMetrix = new Case_Metric_Table__c (Case__c = bi.Case_BI_gne__c,
                                                                                Metric_Type__c = 'BI Metric', 
                                                                                BI_TAT_End_Date__c = TAT_End_Date, 
                                                                                BI_TAT_Start_Date__c  =  TAT_Start_Date,
                                                                                BI_Activity_ID__c  = BI_ActivityID,  
                                                                                BI_sfdc_id__c = bi.id,
                                                                                Benefit_Investigation_ID__c = bi.Name,
                                                                                Staff_Credited__c = UserInfo.getUserId(),
                                                                                BI_TAT_in_Hours__c = InsertBusinessValueMap.get('TotalNofBHours'),
                                                                                BI_TAT_in_Days__c = InsertBusinessValueMap.get('TotalNofBDays'),
                                                                                BI_Status__c = bi.BI_BI_Status_gne__c,
                                                                                Product_Franchise_Name__c = GNE_CM_Metrics_Utility.getProductName(bi.Product_BI_gne__c)
                                                                                );                        
                    CMTList.add(CaseMetrix);
                }
                system.debug('BISet -----------------> ' + BISet);
                if(CMTList != null && CMTList.Size() > 0)
                {
                    CaseMetrixTable = [Select id, Metric_Type__c, BI_Status__c, BI_sfdc_id__c,BI_TAT_Start_Date__c 
                                       from Case_Metric_Table__c 
                                       where Metric_Type__c = 'BI Metric' and BI_sfdc_id__c in: BISet]; // Benefits_Investigation_Id__c
                    
                    for(Case_Metric_Table__c CMTab : CaseMetrixTable)
                    {
                        CaseMetricSet.add(CMTab.BI_sfdc_id__c);
                    }
                    

                    
                    
                     if(CaseMetrixTable.Size() > 0)
                    {
                        for(Case_Metric_Table__c CM : CMTList)
                        {
                            for(Case_Metric_Table__c CMTable : CaseMetrixTable)
                            {
                                if(CaseMetricSet.contains(CM.BI_sfdc_id__c) && CM.BI_sfdc_id__c == CMTable.BI_sfdc_id__c)
                                {                                       
                                    BITATopenDateMap.put(CM.BI_sfdc_id__c,CMTable.BI_TAT_Start_Date__c);
                                    BITATcloseDateMap.put(CM.BI_sfdc_id__c,CM.BI_TAT_End_Date__c);
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    
                    if((BITATopenDateMap.size() >0) && (BITATcloseDateMap.size() >0)){                      
                    UpdateBusinessValueMap =  Bhours.CalculateBusinessHoursMaps(BITATopenDateMap, BITATcloseDateMap);
                    
                                            
                    }

                    //updating existing CM records
                    if(CaseMetrixTable.Size() > 0)
                    {
                        for(Case_Metric_Table__c CM : CMTList)
                        {
                            for(Case_Metric_Table__c CMTable : CaseMetrixTable)
                            {
                                if(CaseMetricSet.contains(CM.BI_sfdc_id__c) && CM.BI_sfdc_id__c == CMTable.BI_sfdc_id__c)
                                {    
                                    UpdateBusinessValues =  UpdateBusinessValueMap.get(CM.BI_sfdc_id__c);
                                    
                                    CMTable.BI_Status__c = CM.BI_Status__c; 
                                    CMTable.BI_TAT_in_Hours__c = UpdateBusinessValues.get('TotalNofBHours');
                                    CMTable.BI_TAT_in_Days__c =  UpdateBusinessValues.get('TotalNofBDays');
                                    CMTable.BI_Activity_ID__c = CM.BI_Activity_ID__c;
                                    CMTable.BI_TAT_End_Date__c = CM.BI_TAT_End_Date__c;
                                    CMTable.Staff_Credited__c = UserInfo.getUserId();
                                    CMTable.Product_Franchise_Name__c = CM.Product_Franchise_Name__c;
                                    CMListToUpdate.add(CMTable);
                                }
                            }
                        }
                    }
                    //inserting new CM records
                    for(Case_Metric_Table__c CM : CMTList)
                    {
                        if(!CaseMetricSet.contains(CM.BI_sfdc_id__c))
                        {
                            CMListToInert.add(CM);
                            break;
                        }
                    }

                    if(CMListToInert != null && CMListToInert.Size() > 0)
                    {
                        try
                        {
                            insert CMListToInert;
                        }
                        catch(DMLException ex)
                        {
                            objectName = 'Case Metric'; 
                            errorLevel = 'High';
                            snippetName = 'Benefit_Investigation_gne__c'; 
                            codeType = 'Trigger';
                            error = 'Failure while inserting Case Metric Table Records.' + ex;
                            CMMetricObj.insertError(objectName, errorLevel, snippetName, codeType, error);
                        }
                    }
                    
                    if(CMListToUpdate != null && CMListToUpdate.Size() > 0)
                    {
                        try
                        {
                            update CMListToUpdate;
                        }
                        catch(DMLException ex)
                        {
                            objectName = 'Case Metric'; 
                            errorLevel = 'High';
                            snippetName = 'Benefit_Investigation_gne__c'; 
                            codeType = 'Trigger';
                            error = 'Failure while updating Case Metric Table Records.' + ex;
                            CMMetricObj.insertError(objectName, errorLevel, snippetName, codeType, error);
                        }
                    }
                }
            }
        }
        catch(exception e)
        {
            objectName = 'Benefit Investigation'; 
            errorLevel = 'High';
            snippetName = 'Benefit_Investigation_gne__c'; 
            codeType = 'Trigger';
            error = 'Error while Inserting/Updating CM records.' + e;
            CMMetricObj.insertError(objectName, errorLevel, snippetName, codeType, error);
        }
        finally
        {
            CMListToInert.clear();
            CMListToUpdate.clear();
            CaseMetricSet.clear();
            CaseList.clear();
            TaskList.clear();
            CaseIdSet.clear();
            CMTList.clear();
            BIIdSet.clear();
            CaseMetrixTable.clear();
        }
    }
    //KS: CMR4 changes end here
    
    // Moved from GNE_CM_Bi_eBi.trigger
    if (trigger.isAfter && (trigger.isUpdate || trigger.isInsert)) {
        updateInsurancesAndBIs();
    }
    if (trigger.isBefore && trigger.isInsert) {
        checkTransactionPayer();
        onInsert();
    }
    
    private static void onInsert()
    {
        Set<Id> insuranceIds = new Set<Id>();
        for (Benefit_Investigation_gne__c bi : trigger.new) {
            if (bi.BI_Insurance_gne__c != null) {
                insuranceIds.add(bi.BI_Insurance_gne__c);
            }
        }
        
        Map<Id,Insurance_gne__c> insurances = new Map<Id,Insurance_gne__c>([
            SELECT Payer_gne__c, Product_Insurance_gne__c
            FROM Insurance_gne__c
            WHERE Payer_gne__c != null
            AND Id IN :insuranceIds
        ]);
        
        Set<Id> insurancePayers = new Set<Id>();
        for (Insurance_gne__c i : insurances.values()) {
            insurancePayers.add(i.Payer_gne__c);
        }
        
        Set<Id> mappedPayers = new Set<Id>();
        for (GNE_CM_EBI_Payer_Mapping__c pm : [
            SELECT Account_gne__c
            FROM GNE_CM_EBI_Payer_Mapping__c
            WHERE Account_gne__c IN :insurancePayers
        ]) {
            mappedPayers.add(pm.Account_gne__c);
        }
        
        for (Benefit_Investigation_gne__c bi : trigger.new) {
            Insurance_gne__c i = insurances.get(bi.BI_Insurance_gne__c);
            bi.Is_eBI_Eligible_gne__c = (i != null && mappedPayers.contains(i.Payer_gne__c) && GNE_CM_EBI_Util.isProductEbiEligible(i.Product_Insurance_gne__c)) ? true : false;
        }
        
        // for McKesson vendor, set the BI method to manual
        if (GNE_CM_User_Utils.getLoggedUserProfileName() == 'GNE-CM-REIMBSPECIALIST-VENDOR') {
            for (Benefit_Investigation_gne__c bi : trigger.new) {
                bi.BI_Method_gne__c = 'Manual';
            }
        }
    }
    
    private static void checkTransactionPayer()
    {
        Map<String, Boolean> existingBis = GNE_CM_EBI_Util.isBiForPayer(Trigger.new);
        
        List<Id> payerIds = new List<Id>();
        for (String s : existingBis.keySet())
        {
            List<String> parts = s.split('_');
            payerIds.add(parts[1]);
        }
        
        Map<Id, String> payerNames = new Map<Id, String>();
        for (Account acc : [select Id, Name from Account where Id in :payerIds])
        {
            payerNames.put(acc.Id, acc.Name);
        }
        
        String txPayerKey = null;
        for (Benefit_Investigation_gne__c bi : Trigger.new) {
            txPayerKey = bi.eBI_Transaction_Num_gne__c + '_' + bi.Payer_BI_gne__c;
            if (existingBis.containsKey(txPayerKey) && existingBis.get(txPayerKey)) {
                bi.addError('Benefit Investigation created from transaction: ' + bi.eBI_Transaction_Num_gne__c + ', with payer: ' + payerNames.get(bi.Payer_BI_gne__c) + ', already exists in the database');
            }
        }
        
    }
    
    private static void updateInsurancesAndBIs()
    {   
        List<Benefit_Investigation_gne__c> changedBis = new List<Benefit_Investigation_gne__c>();
        if (trigger.old == null || trigger.old.size() == 0) {
            changedBis = trigger.new;
        }
        else {
            Integer changedBisCount = trigger.new.size();
            for (Integer i = 0; i < changedBisCount; i++) {
                Benefit_Investigation_gne__c oldBi = trigger.old[i];
                Benefit_Investigation_gne__c newBi = trigger.new[i];
                system.debug('OLDBI: planPrd : '+oldBi.Plan_Plan_Product_lookup_gne__c);
                system.debug('NEWBI: planPrd : '+newBi.Plan_Plan_Product_lookup_gne__c);
                //There is not enought information who changed this on cmgt 24.09.2013.     
                if ((oldBi.Plan_Plan_Product_lookup_gne__c == null && newBi.Plan_Plan_Product_lookup_gne__c != null) ||
                     (oldBi.Plan_Plan_Product_lookup_gne__c != newBi.Plan_Plan_Product_lookup_gne__c )
                     && newBi.Plan_Plan_Product_lookup_gne__c != null)
                    {               
                    //system.debug('NewBI record: '+ newBI);
                    changedBis.add(newBi);
                }
            }
        }       
        system.debug('changedBis:' + changedBis);
        List<Benefit_Investigation_gne__c> bisWithInsurances = [
            SELECT Id, Name, Plan_Plan_Product_lookup_gne__r.Plan_Type_gne__c , Plan_Plan_Product_lookup_gne__r.Plan_Product_Type_gne__c,
                BI_Insurance_gne__r.Plan_gne__c, BI_Insurance_gne__r.Plan_Type_gne__c, BI_Insurance_gne__r.Plan_Product_Type_gne__c,
                BI_Insurance_gne__r.Payer_gne__c, BI_Insurance_gne__r.Payer_gne__r.Name
            FROM Benefit_Investigation_gne__c
            WHERE Id in :changedBis 
        ];
        system.debug('twardoww: bisWithInsurances: ' + bisWithInsurances);
        // update insurances
        // update BI related to updated insurances (workaround for too many soql queries issue)
        // skip triggers
        GNE_SFA2_Util.setSkipTriggersOnlyInTests( false );
        GNE_SFA2_Util.skipTrigger( 'GNE_CM_caseID_prepopulate' );
        GNE_SFA2_Util.skipTrigger( 'GNE_CM_insurance_trigger' );
        GNE_SFA2_Util.skipTrigger( 'GNE_CM_validate_BR_Vendor_Data_03_BI_Insurance' );
        GNE_SFA2_Util.skipTrigger( 'GNE_CM_Insurance_validate_case' );
        
            Map<Id, Insurance_gne__c> changedInsurancesMap = updateInsurances( bisWithInsurances );     
            updateBisRelatedToChangedInsurances( changedInsurancesMap );
        
        GNE_SFA2_Util.setSkipTriggersOnlyInTests ( true );
        GNE_SFA2_Util.stopSkipingTrigger( 'GNE_CM_caseID_prepopulate' );
        GNE_SFA2_Util.stopSkipingTrigger( 'GNE_CM_insurance_trigger' );
        GNE_SFA2_Util.stopSkipingTrigger( 'GNE_CM_validate_BR_Vendor_Data_03_BI_Insurance' );
        GNE_SFA2_Util.stopSkipingTrigger( 'GNE_CM_Insurance_validate_case' );           
    }
    
    private Map<Id,Insurance_gne__c> updateInsurances( List<Benefit_Investigation_gne__c> bisWithInsurances ) {
        system.debug('bisWithInsurances:' + bisWithInsurances);
        Map<Id, Insurance_gne__c> insurancesMap = new Map<Id, Insurance_gne__c>();
        for (Benefit_Investigation_gne__c theBi : bisWithInsurances ) {
            system.debug('theBi.Plan_Plan_Product_lookup_gne__c: ' + theBi.Plan_Plan_Product_lookup_gne__c);
            system.debug('theBi.Plan_Plan_Product_lookup_gne__r.Plan_Type_gne__c: ' + theBi.Plan_Plan_Product_lookup_gne__r.Plan_Type_gne__c);
            system.debug('theBi.Plan_Plan_Product_lookup_gne__r.Plan_Product_Type_gne__c: ' + theBi.Plan_Plan_Product_lookup_gne__r.Plan_Product_Type_gne__c);
            if (theBi.Plan_Plan_Product_lookup_gne__c != theBi.BI_Insurance_gne__r.Plan_gne__c && theBi.Plan_Plan_Product_lookup_gne__c != null) {
                theBi.BI_Insurance_gne__r.Plan_gne__c = theBi.Plan_Plan_Product_lookup_gne__c;
                theBi.BI_Insurance_gne__r.Plan_Type_gne__c = theBi.Plan_Plan_Product_lookup_gne__r.Plan_Type_gne__c;
                theBi.BI_Insurance_gne__r.Plan_Product_Type_gne__c = theBi.Plan_Plan_Product_lookup_gne__r.Plan_Product_Type_gne__c;
                insurancesMap.put(theBi.BI_Insurance_gne__c, theBi.BI_Insurance_gne__r);
            }
        }
        system.debug('insurances:' + insurancesMap);
        List<Insurance_gne__c> insurancesList = insurancesMap.values();
        update insurancesList;
        return insurancesMap;   
    }
    
    private void updateBisRelatedToChangedInsurances( Map< Id, Insurance_gne__c > changedInsurancesMap ){
        List<Benefit_Investigation_gne__c> bis = [
            SELECT Id, Name, Payer_BI_gne__c, Plan_Plan_Product_lookup_gne__c, BI_Insurance_gne__c
            FROM Benefit_Investigation_gne__c
            WHERE BI_Insurance_gne__c in :changedInsurancesMap.keySet() 
        ];
        Set<Benefit_Investigation_gne__c> changedBis = new Set<Benefit_Investigation_gne__c>();
        for (Benefit_Investigation_gne__c theBi : bis ) {
            Insurance_gne__c theChangedInsurance = changedInsurancesMap.get(theBi.BI_Insurance_gne__c);
            if ((theBi.Payer_BI_gne__c != theChangedInsurance.Payer_gne__c) ||
                theBi.Plan_Plan_Product_lookup_gne__c != theChangedInsurance.Plan_gne__c) {
                
                theBi.Payer_BI_gne__c = theChangedInsurance.Payer_gne__c;
                theBi.Plan_Plan_Product_lookup_gne__c = theChangedInsurance.Plan_gne__c;
                changedBis.add(theBi);
            }
        }
        List<Benefit_Investigation_gne__c> changedBisList = new List<Benefit_Investigation_gne__c>(changedBis);
        update changedBisList;  
    }
    
}   //end of trigger