/** @date 9/19/2012
* @Author Pawel Sprysak
* @description Trigger for AGS_ST_DisputeManagement_gne__c update, for setting Drug Name Indicator Flag
*/
trigger AGS_ST_DrugNameIndicatorUpdate on AGS_ST_DisputeManagement_gne__c (before insert) {
    // Get all Dispute Management Id's
    List<Id> idList = new List<Id>();
    for(AGS_ST_DisputeManagement_gne__c dm : Trigger.New) {
        idList.add(dm.AGS_Spend_Expense_Transaction_gne__c);
    }
    // Setting Original values
    for(AGS_Spend_Expense_Transaction_gne__c spendExp : AGS_ST_DbUtils.getOrigSpendExpValues(idList)) {
        for(AGS_ST_DisputeManagement_gne__c dm : Trigger.New) {
            if(dm.AGS_Spend_Expense_Transaction_gne__c == spendExp.Id) {
                // Setting other original values
                dm.Orig_Allocated_Transaction_Amount_gne__c = spendExp.Allocated_Transaction_Amount_gne__c;
                dm.Orig_Form_Of_Payment_gne__c = spendExp.Form_Of_Payment_gne__c;
                dm.Orig_Nature_Of_Payment_gne__c = spendExp.Nature_Of_Payment_gne__c;
                dm.Orig_Source_Transaction_Amount_gne__c = spendExp.Source_Transaction_Amount_gne__c;
                dm.Orig_Event_Actual_Attendee_Count_gne__c = spendExp.Event_Actual_Attendee_Count_gne__c;
                dm.Orig_Event_Planned_Attendee_Count_gne__c = spendExp.Event_Planned_Attendee_Count_gne__c;
                break;
            }
        }
    }
    // Get Drug Names for given Id's
    List<AGS_Expense_Products_Interaction__c> epiList = AGS_ST_DbUtils.getExpProdInterByIdListOrderByDrugName(idList);
    // Check actual Drug/Brand Name and set Indicator
    for(AGS_ST_DisputeManagement_gne__c dm : Trigger.New) {
        String epiReturn = '';
        for(AGS_Expense_Products_Interaction__c epi : epiList) {
            if(dm.AGS_Spend_Expense_Transaction_gne__c == epi.Expense_Transaction_ID_gne__c) {
                if(epiReturn.equals('')) epiReturn = epi.AGS_Brand__c;
                else epiReturn += ',' + epi.AGS_Brand__c;
            }
        }
        dm.Orig_Drug_Name_gne__c = epiReturn;
    }
}