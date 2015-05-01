/*------------      Name of trigger : GNE_CM_validate_BR_Vendor_Data_04_Task  --------------*/
/*------------                                                                --------------*/
/*------------      This code addresses the Task record validation            --------------*/
/*------------      for Cases for Business Rule BR-Vendor_Data-04             --------------*/
/*------------                                                                --------------*/
/*------------      Created by: Marc Friedman                                 --------------*/
/*------------      Last Modified: 01/24/2009                                 --------------*/
/*------------      Modified by: Kishore Chandolu                             --------------*/
/*------------      Last Modified: 02/12/2009                                 --------------*/
/*------------      Modified by: Ravinder Singh                             --------------*/
/*------------      Last Modified: 06/18/2009                                 --------------*/
/*------------      Modified by: Hardy                                        --------------*/
/*------------      Last Modified: 07/13/2009                                 --------------*/

trigger GNE_CM_validate_BR_Vendor_Data_04_Task on Task (before update, before delete)
{

    // SFA2 bypass. Please not remove!
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_validate_BR_Vendor_Data_04_Task')) {
        return;
    }
    
    // Declare local variables
    Set<ID> allCaseIds = new Set<ID>();
    Set<ID> whatIds = new Set<ID>();
    Set<ID> okCaseIds = new Set<ID>();
    //Get recordtypeid of CM Task record type for Task
    //Map<String, Schema.RecordTypeInfo> mapRecTypeInfo = new Map<String, Schema.RecordTypeInfo>();        
    //mapRecTypeInfo = Schema.SObjectType.Task.getRecordTypeInfosByName();            
    String recTypeID =  GNE_CM_Task_Helper.getCMTaskRecordTypeId(); // Id of CM Task record type
    
    // Create a Set of all WhatIDs for the Trigger Tasks
    for (Task t : Trigger.old) 
    {
        if(t.recordtypeid !=null && t.recordtypeid == rectypeID) // to check if task belongs to CM Task record type
        whatIds.add(t.WhatId);
    }
    
    if(whatIds.size()>0)    //TO check if we have received any task which belongs to CM Task record type
    {
        // Get all Nutropin / Vendor Data Cases for the Trigger Tasks
        List<Case> caseList = new List<Case>([SELECT id FROM Case WHERE id IN :whatIds AND Product_gne__c = 'Nutropin' AND Case_Being_Worked_By_gne__c = 'EXTERNAL - MCKESSON' AND (Function_Performed_gne__c = 'Benefits Investigation' OR Function_Performed_gne__c = 'Appeals Follow-up')]);
        
        // Create a Set of Nutropin / Vendor Data Cases IDs for the Trigger Tasks
        for (Case c : caseList) 
        {
            allCaseIds.add(c.Id);
        }
        
        // Get all Prepare and send case to vendor Tasks for Nutropin / McKesson / BI or Appeals Cases that are not in the Trigger
        List<Task> taskList = new List<Task>([SELECT id, WhatId, recordtypeid FROM Task WHERE WhatId IN :caseList AND id NOT IN :Trigger.oldMap.keySet() AND Subject = 'Prepare and send case to vendor']);// added recordtypeid to SOQL to fix bug Offshore request244
        
        // Add the Case ID for the non-Trigger Tasks to the list of Cases that will be valid regardless
        for (Task ta : taskList) 
        {
            if(ta.recordtypeid !=null && ta.recordtypeid == rectypeID) // to check if task belongs to CM Task record type
            okCaseIds.add(ta.WhatId);
        }
        
        // If this is an update
        if (Trigger.isUpdate) 
        {
                
            // Add the Case Ids from any Prepare and send case to vendor Tasks from the newMap to the List of valid Cases with at least one Prepare and send case to vendor
            for (Task t2 : Trigger.new) {
                if(t2.recordtypeid !=null && t2.recordtypeid == rectypeID) // to check if task belongs to CM Task record type
                {
                    // If the Task is for a Nutropin / Vendor Data Case as opposed to another object
                    if (allCaseIds.contains(t2.WhatId) && t2.Subject == 'Prepare and send case to vendor') {
                        okCaseIds.add(t2.WhatId);
                    }
                }
            }
        }   
        
        // Loop through the Task records
        for (Integer i = 0; i < Trigger.old.size(); i++) 
        {
            if (Trigger.isUpdate && Trigger.new[i].recordtypeid !=null && Trigger.new[i].recordtypeid == rectypeID) // to check if task belongs to CM Task record type
            { 
                if (!okCaseIds.contains(Trigger.new[i].WhatId) && allCaseIds.contains(Trigger.new[i].WhatId)) 
                {
                    Trigger.new[i].addError('This Task cannot be updated since Nutropin Cases being worked by McKesson for benefits investigation or appeals follow-up must have at least one Task with the Subject "Prepare and send case to vendor".');
                }
            } 
            else if (Trigger.isDelete && Trigger.old[i].recordtypeid !=null && Trigger.old[i].recordtypeid == rectypeID) // to check if task belongs to CM Task record type
            { 
                if (!okCaseIds.contains(Trigger.old[i].WhatId) && allCaseIds.contains(Trigger.old[i].WhatId)) 
                {
                Trigger.old[i].addError('This Task cannot be deleted since Nutropin Cases being worked by McKesson for benefits investigation or appeals follow-up must have at least one Task with the Subject "Prepare and send case to vendor".');
                }   
            }
        }  
    }   //End of if whatids.size>0     
}