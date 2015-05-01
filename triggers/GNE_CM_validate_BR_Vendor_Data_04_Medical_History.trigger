/*------------      Name of trigger : GNE_CM_validate_BR_Vendor_Data_04_Medical_History   --------------*/
/*------------                                                                            --------------*/
/*------------      This code addresses the Medical History record validation             --------------*/
/*------------      for Cases for Business Rule BR-Vendor_Data-04                         --------------*/
/*------------                                                                            --------------*/
/*------------      Created by: Marc Friedman                                             --------------*/
/*------------      Last Modified: 01/24/2009                                             --------------*/

trigger GNE_CM_validate_BR_Vendor_Data_04_Medical_History on Medical_History_gne__c (before update) {

    // SFA2 bypass
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_validate_BR_Vendor_Data_04_Medical_History')) {
        return;
    }

     //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    // Get Nutropin / Data Exchange Cases for the Medical History
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig2())  // Global check for static variable to make sure trigger executes only once 
    {
        for (Case c : [SELECT Medical_History_gne__c FROM Case WHERE Medical_History_gne__c IN :Trigger.oldMap.keySet() AND Product_gne__c = 'Nutropin' AND Case_Being_Worked_By_gne__c = 'EXTERNAL - MCKESSON' AND (Function_Performed_gne__c = 'Benefits Investigation' OR Function_Performed_gne__c = 'Appeals Follow-up')]) {
    
            // Flag Medical Histories about to be updated that have blank required fields
            if (Trigger.newMap.get(c.Medical_History_gne__c).ICD9_Code_1_gne__c == null || Trigger.newMap.get(c.Medical_History_gne__c).Therapy_Type_gne__c == null || Trigger.newMap.get(c.Medical_History_gne__c).Drug_gne__c == null) {
                Trigger.newMap.get(c.Medical_History_gne__c).addError('Medical Histories referenced from one or more Nutropin Cases being worked by McKesson for benefits investigation or appeals follow-up must have a value for ICD9-1, Therapy Type and Drug.');
            }
        }
        GNE_CM_case_trigger_monitor.settriggerInProcessTrig2(); // Setting the static variable so that this trigger does not get executed after workflow update
    }   //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig2())
}