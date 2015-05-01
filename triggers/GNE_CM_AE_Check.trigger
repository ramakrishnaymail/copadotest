trigger GNE_CM_AE_Check on Task (before insert, before update) {
    
    String caseobjid=Schema.SObjectType.Case.getKeyPrefix();
    String hotlineobjid=Schema.SObjectType.Hotline_gne__c.getKeyPrefix();
    /*
    Map<String, Schema.RecordTypeInfo> caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName();
    Id ccCaseRecordTypeId = caseRecordType.get('C&R - Continuous Care Case').getRecordTypeId();
    Map<Id, Id> taskIdToCaseId = new Map<Id,Id>();
    for(Task task : newTasks){
        if(task.WhatId != null && task.WhatId.substring(0, 3) == caseobjid && task.Activity_Type_gne__c == 'Reported Potential Adverse Event - Identified in Document'){
            taskIdToCaseId.put(task.Id, task.WhatId);   
        }       
    }*/

    Set<Id> supervisorProfileIdSet;
    
    for (Task t : trigger.new) {
        String whid = t.WhatId;
        if(t.WhatId != null && whid.substring(0, 3) != caseobjid && whid.substring(0, 3) != hotlineobjid && t.Activity_Type_gne__c == 'Reported Potential Adverse Event - Identified in Document'){
            t.addError('Task with "Reported Potential Adverse Event - Identified in Document" subject can be assigned only to cases or hotlines');
        }        
        if (t.Original_Document_TID_gne__c != null && !t.Original_Document_TID_gne__c.isNumeric()) {
        	t.addError('Original Document TID has to be numeric');           
        }   
		if(t.WhatId != null && (whid.substring(0, 3) == caseobjid || whid.substring(0, 3) == hotlineobjid) && t.Activity_Type_gne__c == 'Reported Potential Adverse Event - Identified in Document' && t.Status != 'Completed' && (t.Document_Name_gne__c == null || t.Document_Name_gne__c == '' || t.Original_Document_TID_gne__c == '' || t.Original_Document_TID_gne__c == null)){
			t.addError('Document Name and Original Document TID fields in the "Potential Adverse Event: Document Reporting" section must be populated.');	
        }
        if(t.WhatId != null && (whid.substring(0, 3) == caseobjid || whid.substring(0, 3) == hotlineobjid) && t.Activity_Type_gne__c == 'Reported Potential Adverse Event - Identified in Document' && t.Status == 'Completed' && (t.Document_Name_gne__c == null || t.Document_Name_gne__c == '' || t.Original_Document_TID_gne__c == '' || t.Original_Document_TID_gne__c == null || t.SSP_ID_gne__c == null || t.SSP_ID_gne__c == '')){
            t.addError('All fields in the "Potential Adverse Event: Document Reporting" section must be populated before completing this activity.');
        }

        if(trigger.isUpdate && trigger.oldMap.get(t.Id).OwnerId != t.OwnerId && t.Activity_Type_gne__c == 'Reported Potential Adverse Event - Identified in Document'){
            if(supervisorProfileIdSet == null){             
                List<Profile> supervisorProfiles = [SELECT Id FROM Profile WHERE Name IN ('GNE-CM-CRSUPERVISOR','GNE-CM-GATCFSUPERVISOR','GNE-CM-INTAKESUPERVISOR')];
                supervisorProfileIdSet = new Set<Id>();
                for(Profile p : supervisorProfiles){
                    supervisorProfileIdSet.add(p.Id);
                }
            }
            if(!supervisorProfileIdSet.contains(UserInfo.getProfileId()) && UserInfo.getUserId() != trigger.oldMap.get(t.Id).OwnerId){
                t.addError('Task with "Reported Potential Adverse Event - Identified in Document" activity can be reassinged only by supervisor user or current owner');          
            }
        }

        //if(taskIdToCaseId.containsKey(task.Id) && taskCasesMap.get(taskIdToCaseId.get(task.Id)).RecordTypeId == ccCaseRecordTypeId){
        //  task.addError('Task with "Reported Potential Adverse Event - Identified in Document" subject cannot be assigned to Continuous Care Cases.');
        //}
        
        // PFS-1389
        if (t.Activity_Type_gne__c != 'Reported Potential Adverse Event - Live' && 
            t.Activity_Type_gne__c != 'Reported Potential Adverse Event - VM') {
            if (t.OTN_gne__c != null) 
                t.OTN_gne__c.addError('The field "OTN" is not applicable to the selected Activity Type, please remove.');
            if (t.Reporter_Caller_gne__c != null)
                 t.Reporter_Caller_gne__c.addError('The field "Reporter/Caller" is not applicable to the selected Activity Type, please remove.');  
            if (t.Reported_To_gne__c != null) 
                 t.Reported_To_gne__c.addError('The field "Reported To" is not applicable to the selected Activity Type, please remove.');
        }
        if (t.Activity_Type_gne__c == 'Reported Potential Adverse Event - VM') {
            if (t.OTN_gne__c != null) 
                t.OTN_gne__c.addError('The field "OTN" is not applicable to the selected Activity Type, please remove.');               
            if (t.Reported_To_gne__c != null) 
                 t.Reported_To_gne__c.addError('The field "Reported To" is not applicable to the selected Activity Type, please remove.');
            if (t.Reporter_Caller_gne__c == null)
                 t.Reporter_Caller_gne__c.addError('The field "Reporter/Caller" is required with the selected Activity Type.'); 
        } 
        if (t.Activity_Type_gne__c == 'Reported Potential Adverse Event - Live') {
            if (t.OTN_gne__c == null) 
                t.OTN_gne__c.addError('The field "OTN" is required with the selected Activity Type.');              
            if (t.Reporter_Caller_gne__c == null) 
                 t.Reporter_Caller_gne__c.addError('The field "Reporter/Caller" is required with the selected Activity Type.');
            if (t.Reported_To_gne__c == null)
                 t.Reported_To_gne__c.addError('The field "Reported To" is required with the selected Activity Type.'); 
        } 
    }
}