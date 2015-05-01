trigger GNE_CM_case_post_processing on Case (after insert, after update, after delete)
{
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode()){
        return;
    }
    
    //skip this trigger if it is triggered from transfer wizard
    if (GNE_CM_MPS_TransferWizard.isDisabledTrigger)
    {
        System.debug('Skipping trigger GNE_CM_case_post_processing');
        return;
    }

    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_case_post_processing'))
    {
        return;
    }
    
    List<Error_log_gne__c> errorLogList = new List<Error_log_gne__c>();
    String sErrorDescription = 'Error: Unable to execute Batch Fax AA Maint Logic, please contact System Administrator';    
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Standard Case').getRecordTypeId();
    Set<Id> patientIDs = new Set<Id>();
    
    /*** Hardy 8/8/2012: Batch Fax Enhancement - Calculating Active GATCF Cases against a patient****/
    Id recordTypeIdGATCF = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GATCF - Standard Case').getRecordTypeId();
    Set<Id> patientIDsBF = new Set<Id>();
    
    if (trigger.isInsert)
    {    
        for (Case c :trigger.new)
        {
            if (c.RecordTypeId == recordTypeIdGATCF)
            {
                patientIDsBF.add(c.Patient_gne__c);
            }
        }
    }
    if (trigger.isUpdate)
    {    
        for (Case c :trigger.new)
        {
            if (c.RecordTypeId == recordTypeIdGATCF 
                && c.Status != trigger.oldMap.get(c.id).Status
                && c.Status != 'Active')
            {
                patientIDsBF.add(c.Patient_gne__c);
            }
        }
    }
    
    if (patientIDsBF != null && patientIDsBF.size() > 0)
    {
       // Commented for refactoring to be able to deactivate the trigger -PFS 1906 
       // GNE_CM_Case_Trigger_Util.updatePatientGATCFStatus (patientIDsBF, recordTypeIdGATCF);    
    }
    
    if (trigger.isInsert || trigger.isUpdate)
    {    
        for (Case c : trigger.new)
        {
            if (c.RecordTypeId == recordTypeId && c.Product_gne__c == 'Rituxan RA')
            {
                patientIDs.add(c.Patient_gne__c);
            }
        }
    }

    if (trigger.isDelete)
    {    
        for (Case c :trigger.old)
        {
            if (c.RecordTypeId == recordTypeId && c.Product_gne__c == 'Rituxan RA')
            {
                patientIDs.add(c.Patient_gne__c);
            }
        }
    }
    
    if (trigger.isUpdate)
    {   
        //JH 10/21/2013 - SOQL Optimization
        String curProfile = GNE_SFA2_Util.getCurrentUserProfileName();
        if (!GNE_CM_Batch_Fax_AA_post_processing.getMaintSentDateEditableProfiles().contains(curProfile.toLowerCase()))
        {           
            for (Case c :trigger.new)
            {
                if (c.RecordTypeId == recordTypeId && c.Product_gne__c == 'Rituxan RA')
                {
                    if (trigger.oldMap.get(c.Id).Batch_Fax_AA_Maint_Sent_Date_gne__c != c.Batch_Fax_AA_Maint_Sent_Date_gne__c &&
                        c.Batch_Fax_AA_Maint_Sent_Date_gne__c != null &&                
                        c.Batch_Fax_AA_Maint_Sent_Date_gne__c < Date.today())
                    {
                        c.addError('Batch Fax AA Maint Sent Date cannot be overriden with past date.');
                        if (patientIDs.contains(c.Patient_gne__c))
                        {
                            patientIDs.remove(c.Patient_gne__c);
                        } 
                    }
                }   
            }           
        }           
    }
    
    //queue management functionality            
    if (trigger.isUpdate)    
    {
        List<Case> casesWithTasksToUpdate = new List<Case>();
        for (Case newCase :trigger.new)
        {
            //check if address has changed on case
            if (trigger.oldMap.get(newCase.Id).Address_gne__c != newCase.Address_gne__c)
            {
                casesWithTasksToUpdate.add(newCase);
            }   
        }
        if (casesWithTasksToUpdate.size() > 0)
        {
            GNE_CM_Task_Queue_Mgmt_Helper.flagTasksWithChangedAddress(casesWithTasksToUpdate);
        }
    }
    
    try
    {
        if (patientIDs.size() > 0 && GNE_CM_Batch_Fax_AA_post_processing.executionDisabled == false)
        {   
            GNE_CM_Batch_Fax_AA_post_processing.processCaseData(patientIDs);
        }       
    }
    catch (Exception e)
    {
        sErrorDescription += GlobalUtils.getExceptionDescription(e);
        sErrorDescription += ' Non processed patientIDs: ' + patientIDs;
        errorLogList.add(new Error_log_gne__c(Error_Level_gne__c = 'High',
           Code_Type__c       = 'Trigger',
           Snippet_Name__c    = 'GNE_CM_case_post_processing',
           User_Name__c       = UserInfo.getUserName(),
           Object_Name__c     = 'Case',    
           Error_Description__c  = sErrorDescription
           ));
    }
    finally
    {
        if (errorLogList.size() > 0)
        {
            insert errorLogList;
        }
    }   
}