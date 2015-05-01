trigger GNE_CM_Metrics_Case_Trigger on Case (after insert, after update)
{  
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode()){
        return;
    }
    
    //skip this trigger if it is triggered from transfer wizard
    if (GNE_CM_MPS_TransferWizard.isDisabledTrigger)
    {
        return;
    }
  
    Id stdrectypId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Continuous Care Case').getRecordTypeId();
    Id elgrectypId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('C&R - Standard Case').getRecordTypeId();
  
    GNE_CM_Businesshours_Calc bhoursobj = new GNE_CM_Businesshours_Calc();
  
    Map<Id,Map<String, Decimal>>  CRCRBusinessValuesMap = new Map<Id,Map<String, Decimal>>();    
    Map<String, Decimal> CRCRBusinessValues = new  Map<String, Decimal>();   
   
    Map<id,Case> CaseMap = new Map<id,Case>(); 
    Map<id,DateTime> CaseopenDateMap = new Map<id,DateTime>();
    Map<id,DateTime> CasecloseDateMap = new Map<id,DateTime>();
  
    List<Case_Metric_Table__c> CRCaseMetrixList = new List<Case_Metric_Table__c>();
    List<Case_Metric_Table__c> CRCaseMetrixTable = new List<Case_Metric_Table__c>();  
    List<Case_Metric_Table__c> CRCMListToUpdate = new List<Case_Metric_Table__c>();
  
    Set<Id> CaseIdSet = new Set<Id>();
  
    GNE_CM_Metrics_Utility UtilObj = new GNE_CM_Metrics_Utility();
  
    if (trigger.isAfter)
    {       
        for (Case cse : trigger.new)
        {
            if (cse.Status != null && cse.Status.contains('Closed') && (cse.RecordTypeId == stdrectypId || cse.RecordTypeId == elgrectypId))
            {
                if (trigger.isInsert || (trigger.isUpdate && cse.Status != trigger.oldMap.get(cse.Id).Status))
                {
                    CaseIdSet.add(cse.id);
                    CaseopenDateMap.put(cse.id,cse.createdDate);
                    CasecloseDateMap.put(cse.id, DateTime.now());
                }                
            }
        }
         
        if (CaseopenDateMap.size() > 0 && CasecloseDateMap.size() > 0 )
        {
            CRCRBusinessValuesMap = bhoursobj.CalculateBusinessHoursMaps(CaseopenDateMap,CasecloseDateMap);           
        }        
    
        for (Case cse : trigger.new)
        {
            if (cse.Status.contains('Closed') && (cse.RecordTypeId == stdrectypId || cse.RecordTypeId == elgrectypId) && CRCRBusinessValuesMap.size() > 0)
            {
                if (trigger.isInsert || (trigger.isUpdate && cse.Status != trigger.oldMap.get(cse.Id).Status))
                {
                    CRCRBusinessValues = CRCRBusinessValuesMap.get(cse.id);               
                    Case_Metric_Table__c CaseMetrix = new Case_Metric_Table__c (Case__c = cse.Id,
                                                                                Metric_Type__c = 'CR CR TAT', 
                                                                                CR_CR_TAT_End_Date__c = DateTime.now(),                                                                           
                                                                                CR_CR_TAT_Start_Date__c = cse.CreatedDate,                                   
                                                                                Staff_Credited__c = UserInfo.getUserId(),
                                                                                CR_CR_TAT_in_Hours__c = CRCRBusinessValues.get('TotalNofBHours'),
                                                                                CR_CR_TAT_in_Days__c = CRCRBusinessValues.get('TotalNofBDays'),
                                                                                Product_Franchise_Name__c = GNE_CM_Metrics_Utility.getProductName(cse.Product_gne__c)
                                                                                );                                    
                    CRCaseMetrixList.add(CaseMetrix);
                }
            }
        }
           
        if (CaseIdSet != null && CaseIdSet.size()>0)
        {
            CRCaseMetrixTable = [Select Case__c, Metric_Type__c from Case_Metric_Table__c where Metric_Type__c = 'CR CR TAT' and Case__c in :CaseIdSet];
            CaseMap = new Map<Id, Case>([select Id, ClosedDate from Case where Id IN:CaseIdSet]);
        }
                                  
        if (CRCaseMetrixTable.size() > 0)
        {
            for (Case_Metric_Table__c CM : CRCaseMetrixList)
            {              
                for (Case_Metric_Table__c CMTable : CRCaseMetrixTable)
                {
                    if (CM.Case__c == CMTable.Case__c && CaseMap.size() > 0)
                    {                                                                    
                        CMTable.CR_CR_TAT_End_Date__c = CM.CR_CR_TAT_End_Date__c; 
                        CMTable.CR_CR_TAT_Start_Date__c = CM.CR_CR_TAT_Start_Date__c;
                        CMTable.Staff_Credited__c = UserInfo.getUserId();
                        CMTable.CR_CR_TAT_in_Hours__c = CM.CR_CR_TAT_in_Hours__c;
                        CMTable.CR_CR_TAT_in_Days__c = CM.CR_CR_TAT_in_Days__c;
                        CMTable.Product_Franchise_Name__c = CM.Product_Franchise_Name__c;
                                     
                        CRCMListToUpdate.add(CMTable);
                    }
                }
            } 
                              
            if (CRCMListToUpdate.Size() > 0)
            {
                try
                {                            
                    update CRCMListToUpdate;                        
                }
                catch (DMLException firsterr)
                {
                    system.debug('Failure while updating Case Metric Table Records');
                    string firsterrMessage = 'Failed to update case metric table record where type is C&R CR TAT' + firsterr.getMessage();
                    UtilObj.insertError('Case_Metric_Table__c','High','GNE_CM_Metrics_Case_Trigger','Trigger',firsterrMessage);
                }
            }                  
        }
        else if (CRCaseMetrixList.Size() > 0)
        {
            try
            {                                                       
                insert CRCaseMetrixList;                            
            }
            catch (DMLException seconderror)
            {
                system.debug('Failure while inserting Case Metric Table Records');
                string seconderrMessage = 'Failed to insert case metric table record where type is CR CN TAT' + seconderror.getMessage();
                UtilObj.insertError('Case_Metric_Table__c','High','GNE_CM_Metrics_Case_Trigger','Trigger',seconderrMessage);
            }
        }        
    }

    CRCMListToUpdate.clear();
    CaseIdSet.clear();   
}