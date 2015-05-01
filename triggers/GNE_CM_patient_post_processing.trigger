trigger GNE_CM_patient_post_processing on Patient_gne__c (before insert, after insert,before update, after update) 
{
    // Skip this trigger if certain unit tests are running.
    // This code has no impact when not run in tests - the condition causing the trigger to exit is only fulfilled in tests and only when explicitly set.
    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_patient_post_processing'))
    {
        return;
    }
    
    List<Error_log_gne__c> errorLogList = new List<Error_log_gne__c>();
    String sErrorDescription = 'Error: Unable to execute Batch Fax AA Maint Logic, please contact System Administrator';
    Map<Id, Boolean> patientNotParticipatingMap = new Map<Id, Boolean>();
    
    //AS : Changes PFS 519 10/10/2012
    Set<Id> patId = new Set<Id>();
    Set<Id> caseId = new Set<Id>();
    Set<Id> hotLineId = new Set<Id>();
    
    List<Task> lstTask = new List<Task>();
    List<Task> lstTaskToInsert = new List<Task>();
    List<Task> lstTaskToUpdate = new List<Task>();
    List<Task> lstTaskAgainstCase = new List<Task>();
    List<Task> lstTaskAgainstCaseUpdate = new List<Task>();
    List<Task> lstTaskAgainstHotline = new List<Task>();
    List<Task> lstTaskAgainstHotLineUpdate = new List<Task>();
    List<Case> lstCase = new List<Case>();
    List<Hotline_gne__c> lstHotLine = new List<Hotline_gne__c>();
    
    Map<id,string> mapStr = new Map<id,string>();
    Map<id,string> mapStrCase = new Map<id,string>();
    Map<id,string> mapStrHotLine = new Map<id,string>();
    //AS Changes End here

    if (trigger.isBefore && (trigger.isUpdate || trigger.isInsert))
    {
        GNE_CM_Patient_Trigger_Util.updatePatientPANFields(trigger.new);  
    }
    
    if (trigger.isAfter && trigger.isUpdate)
    {
        // update publish date on related case BIs
        GNE_CM_Patient_Trigger_Util.updateBIPublishDateForAssociatedCases(trigger.oldMap, trigger.newMap);
    }
    
    if (trigger.isAfter && trigger.isInsert)
    {
        for (Patient_gne__c patient : trigger.new)
        {   
            if (patient.Not_Participating_Anticipated_Access_gne__c != null)
            {
                patientNotParticipatingMap.put(patient.id, patient.Not_Participating_Anticipated_Access_gne__c);
            }
            
            if (patient.pat_patient_deceased_gne__c == 'Yes')
            {
                Task task = new Task (OwnerId = UserInfo.getUserId(), Subject = 'Reminder to Report Potential Adverse Event', WhatId = patient.Id, ActivityDate = system.today());
                lstTaskToInsert.add(task);              
            }
        }

        if (lstTaskToInsert != null && lstTaskToInsert.size() > 0)
        {
            insert lstTaskToInsert;
        }
    }
    
    if (trigger.isUpdate)
    {
        for(Patient_gne__c patient :trigger.new)
        {
            if(trigger.oldMap.get(patient.Id).Not_Participating_Anticipated_Access_gne__c != patient.Not_Participating_Anticipated_Access_gne__c)
                patientNotParticipatingMap.put(patient.id, patient.Not_Participating_Anticipated_Access_gne__c);
        }
    }
    
    // GDC - 8/4/2011 Code added to update insurance rec on patient rec update.
    if(trigger.isAfter && trigger.isUpdate)
    {
        try
        {
            system.debug('HERE...........');
            List<Insurance_gne__c> ins = new List<Insurance_gne__c>();
            List<Insurance_gne__c> updateins = new List<Insurance_gne__c>();
            ins = [select id, Subscriber_Name_gne__c, ssn_gne__c, Subscriber_DOB_gne__c, Patient_Relationship_to_Subscriber_gne__c from Insurance_gne__c where Patient_Insurance_gne__c =: trigger.old[0].id];
            for(Patient_gne__c patient :trigger.new)
            {
                for(integer i=0; i<ins.size(); i++)
                {
                    if(ins[i].Patient_Relationship_to_Subscriber_gne__c == 'Self' && (ins[i].ssn_gne__c != patient.ssn_gne__c || ins[i].Subscriber_DOB_gne__c != patient.pat_dob_gne__c))
                    {
                        // commented on 8/16/2011
                        //ins[i].Subscriber_Name_gne__c = patient.Full_Name_gne__c;
                        ins[i].ssn_gne__c = patient.ssn_gne__c;
                        ins[i].Subscriber_DOB_gne__c = patient.pat_dob_gne__c;
                        system.debug('ins[i].Subscriber_Name_gne__c.....1' + ins[i].Subscriber_Name_gne__c);
                        system.debug('ins[i].ssn_gne__c.....2' + ins[i].ssn_gne__c);
                        system.debug('ins[i].Subscriber_DOB_gne__c.....3' + ins[i].Subscriber_DOB_gne__c);
                        updateins.add(ins[i]);
                    }
                }
            }
            system.debug('updateins.............' + updateins );
            update updateins;
        }
        catch(exception e)
        {
            system.debug('Error occured while updating Insurance rec....' + e.getMessage());
        }
    }
    //Code ends here

    // GDC - 8/5/2011 To update Phone and Phone Type fields.
    /*
    if((trigger.isinsert || trigger.isUpdate) && trigger.isBefore)
    {
        List<Patient_gne__c> listpat = new List<Patient_gne__c>();
        try
        {
            system.debug('HERE...........');
            for(Patient_gne__c patient :trigger.new)
            {
                    if(patient.pat_home_phone_gne__c != null && patient.pat_home_phone_gne__c != '')
                    {
                        system.debug('Point 1');
                        patient.Phone_gne__c = patient.pat_home_phone_gne__c;
                        patient.Phone_Type_gne__c = 'Home';
                    }
                    else if((patient.pat_home_phone_gne__c == null || patient.pat_home_phone_gne__c == '') && (patient.pat_other_phone_gne__c != null && patient.pat_other_phone_gne__c != ''))
                    {
                        system.debug('Point 2');
                        patient.Phone_gne__c = patient.pat_other_phone_gne__c;
                        patient.Phone_Type_gne__c = 'Other';
                    }
                    else if((patient.pat_home_phone_gne__c == null || patient.pat_home_phone_gne__c == '') && (patient.pat_other_phone_gne__c == null || patient.pat_other_phone_gne__c == '') && (patient.pat_work_phone_gne__c != null && patient.pat_work_phone_gne__c != ''))
                    {
                        system.debug('Point 3');
                        patient.Phone_gne__c = patient.pat_work_phone_gne__c;
                        patient.Phone_Type_gne__c = 'Work';
                    }
                }   
            } 
        catch(exception e)
        {
            system.debug('Error:::::' + e.getMessage());
        }
    }
    
    // code ends here
    */
    
    try
    {
        if(GNE_CM_Batch_Fax_AA_post_processing.executionDisabled == false)
        {
            GNE_CM_Batch_Fax_AA_post_processing.processPatientData(patientNotParticipatingMap);
        }
    }
    catch(Exception e)
    {
        sErrorDescription += GlobalUtils.getExceptionDescription(e);
        sErrorDescription += ' Non processed patientNotParticipatingMap: ' + patientNotParticipatingMap;
        errorLogList.add(new Error_log_gne__c(Error_Level_gne__c = 'High',
           Code_Type__c       = 'Trigger',
           Snippet_Name__c    = 'GNE_CM_patient_post_processing',
           User_Name__c       = UserInfo.getUserName(),
           Object_Name__c     = 'Patient_gne__c',    
           Error_Description__c  = sErrorDescription
           ));
    }
    finally
    {                       
        if(errorLogList.size() > 0)
            insert errorLogList;
    }
    
    //AS : Changes PFS 519 10/10/2012
    if(trigger.isAfter && trigger.isUpdate)
    {
        Set<Id> patientIdsToUpdateManagePatients = new Set<Id>();
        for(Patient_gne__c pat : trigger.new)
        {
            if(pat.Preferred_Language_gne__c != trigger.oldmap.get(pat.id).Preferred_Language_gne__c)
            {
                patId.add(pat.id);
                mapStr.put(pat.id,pat.Preferred_Language_gne__c);
            }
            
            if(pat.pat_patient_deceased_gne__c == 'Yes' && trigger.oldmap.get(pat.id).pat_patient_deceased_gne__c != 'Yes'){
                Task task = new Task (OwnerId = UserInfo.getUserId(),Subject = 'Reminder to Report Potential Adverse Event', WhatId = pat.Id, ActivityDate = system.today());
                lstTaskToInsert.add(task);              
            }
            else if(pat.pat_patient_deceased_gne__c == 'No' && trigger.oldmap.get(pat.id).pat_patient_deceased_gne__c == 'Yes')
            {
                patientIdsToUpdateManagePatients.add(pat.id);
            }
        }
        
        //If the patient deceased flag has been flipped from No to Yes, update related Manage Patient records
        //The case when it is flipped from Yes to No, is handled by the GNE_CM_MPSActiveUserList_Batch class
        if(!patientIdsToUpdateManagePatients.isEmpty())
        {
            List<Case> casesList = new List<Case>();
            Integer queryLimit = Limits.getLimitQueryRows() - 1000;
            casesList = [SELECT Id, Patient_Deceased_gne__c,CreatedDate,Status, Address_gne__c, 
                            Patient_gne__c, Patient_gne__r.Id, Patient_Enrollment_Request_gne__c,
                            MPS_Registration__c, Case_Treating_Physician_gne__c 
                        FROM Case 
                        WHERE Patient_gne__c in:patientIdsToUpdateManagePatients
                        ORDER BY CREATEDDATE desc limit:queryLimit ];
            if(!casesList.isEmpty())
            {
                GNE_CM_CaseTriggerHandler.updateManagePatientsForCases(casesList);    
            }
            
        }

        
        if(lstTaskToInsert != null && lstTaskToInsert.size() > 0)
        {
            insert lstTaskToInsert;
        }
        lstTaskToInsert.clear();
        
        if(patId != null && patId.size() > 0)
        {
            lstTask = [Select id,Preferred_Language_gne__c,WhatId,status from Task where whatId in :patId and status != 'Completed'];
            lstCase = [Select id,Patient_gne__r.Preferred_Language_gne__c from Case where Patient_gne__c in :patId and Status = 'Active'];
            if(lstCase != null && lstCase.size() > 0)
            {
                for(case cas: lstCase)
                {
                    caseId.add(cas.id);
                    mapStrCase.put(cas.id,cas.Patient_gne__r.Preferred_Language_gne__c);
                }
            }
            
            if (caseId != null && caseId.size() > 0) 
            {
            lstTaskAgainstCase = [Select Preferred_Language_gne__c,WhatId,Case_Id_gne__c from Task where Case_Id_gne__c in :caseId and status != 'Completed'];
            	lstHotLine = [Select id,Related_Case_gne__r.Patient_gne__r.Preferred_Language_gne__c from Hotline_gne__c where Related_Case_gne__c in :caseId];
            }
            
            if(lstTaskAgainstCase != null && lstTaskAgainstCase.size() > 0)
            {
                for(Task tsk : lstTaskAgainstCase)
                {
                    tsk.Preferred_Language_gne__c = mapStrCase.get(tsk.Case_Id_gne__c);
                    lstTaskAgainstCaseUpdate.add(tsk);
                }
            } 
            
            if(lstTask != null && lstTask.size() > 0)
            {
                for(Task tsk : lstTask)
                {
                    tsk.Preferred_Language_gne__c = mapStr.get(tsk.whatId);
                    lstTaskToUpdate.add(tsk);
                }
            }
            if(lstHotLine != null && lstHotLine.size() > 0)
            {
                for(Hotline_gne__c ht : lstHotLine)
                {
                    hotLineId.add(ht.id);
                    mapStrHotLine.put(ht.id,ht.Related_Case_gne__r.Patient_gne__r.Preferred_Language_gne__c);
                }
                
            lstTaskAgainstHotline = [Select id,Preferred_Language_gne__c,WhatId from Task where whatId in :hotLineId and status != 'Completed'];
            if(lstTaskAgainstHotline != null && lstTaskAgainstHotline.size() > 0)
            {
                for(Task tsk : lstTaskAgainstHotline)
                {
                    tsk.Preferred_Language_gne__c = mapStrHotLine.get(tsk.whatId);
                    lstTaskAgainstHotLineUpdate.add(tsk);
                }
            }
            }
             
            lstTaskToUpdate.addAll(lstTaskAgainstCaseUpdate);
            lstTaskToUpdate.addAll(lstTaskAgainstHotLineUpdate);
            
            if (lstTaskToUpdate.size() > 0)
            {
            update lstTaskToUpdate;   
            }
            lstTaskToUpdate.clear();
            lstTaskAgainstCaseUpdate.clear();
            lstTaskAgainstHotLineUpdate.clear();
        }   
    } 
}