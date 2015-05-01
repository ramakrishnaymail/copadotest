/*------------      Name of trigger : GNE_CM_validate_BR_Vendor_Data_03_04_Patient  --------------*/
/*------------                                                                      --------------*/
/*------------      This code addresses the Patient record validation               --------------*/
/*------------      for Cases for Business Rule BR-Vendor_Data-04                   --------------*/
/*------------                                                                      --------------*/
/*------------      Created by: Marc Friedman                                       --------------*/
/*------------      Last Modified: 06/30/2009                                       --------------*/

trigger GNE_CM_validate_BR_Vendor_Data_03_04_Patient on Patient_gne__c (before update, before delete)
{
    Set<Id> patidset = new Set<Id>(); 
    // Get Nutropin / Vendor Cases for the Patient records
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig2()) // Global check for static variable to make sure trigger executes only once
    {
        //This trigger will only execute if static variable is not set
        GNE_CM_case_trigger_monitor.setTriggerInProcessTrig2(); // Setting the static variable so that this trigger does not get executed after workflow update
        for (Case c : [SELECT Patient_gne__c FROM Case WHERE Patient_gne__c IN :Trigger.oldMap.keySet() AND Product_gne__c = 'Nutropin' AND Case_Being_Worked_By_gne__c = 'EXTERNAL - MCKESSON' AND (Function_Performed_gne__c = 'Benefits Investigation' OR Function_Performed_gne__c = 'Appeals Follow-up')])
        {
            // Flag Patients about to be deleted
            if (Trigger.isDelete)
            {
                Trigger.oldMap.get(c.Patient_gne__c).addError('This Patient cannot be deleted as it is referenced from one or more Nutropin Cases being worked by McKesson for benefits investigation or appeals follow-up.');
            
            // Flag Patients about to be updated that have blank DOBs, Genders or PAN Forms
            // NL 06/24/2009 - Adjustment of Validation Rule of PAN 1 or PAN 2
            }else if (Trigger.isUpdate && (Trigger.newMap.get(c.Patient_gne__c).pat_dob_gne__c == null || Trigger.newMap.get(c.Patient_gne__c).pat_gender_gne__c == null || (Trigger.newMap.get(c.Patient_gne__c).PAN_gne__c != 'Yes' && Trigger.newMap.get(c.Patient_gne__c).PAN_Form_2_gne__c != 'Yes') || (Trigger.newMap.get(c.Patient_gne__c).PAN_Form_1_Product_gne__c != 'Nutropin' && Trigger.newMap.get(c.Patient_gne__c).PAN_Form_2_Product_gne__c != 'Nutropin') || (Trigger.newMap.get(c.Patient_gne__c).PAN_gne__c != 'Yes' && Trigger.newMap.get(c.Patient_gne__c).PAN_Form_1_Product_gne__c == 'Nutropin') || (Trigger.newMap.get(c.Patient_gne__c).PAN_Form_2_gne__c != 'Yes' && Trigger.newMap.get(c.Patient_gne__c).PAN_Form_2_Product_gne__c == 'Nutropin')))
            {
                //NL 06/30/2009 - Workaround to allow shipment script to update Starter Flag for Pulmozyme and Nutropin
                If (Trigger.newMap.get(c.Patient_gne__c).Eligible_for_Nutropin_Starter_gne__c != 'No' && Trigger.newMap.get(c.Patient_gne__c).Eligible_for_Pulmozyme_Starter_gne__c != 'No')
                {
                  Trigger.newMap.get(c.Patient_gne__c).addError('Patients referenced from one or more Nutropin Cases being worked by McKesson for benefits investigation or appeals follow-up must have a DOB ,Gender, PAN Form 1 or PAN Form 2.');
                }
            }
        }   //end of for Case c :
    }   //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig2())
    // changes made as per offshore request 438 :- SD
            
    
    
}   //end of trigger