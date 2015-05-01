/** @date 4/4/2014
* @Author Konrad Malinowski, Pawel Sprysak
* @description Trigger for AGS_Spend_Expense_Transaction_gne__c update, for updating CMS_Payment_ID_gne__c and Home_Payment_ID_gne__c of child Objects
*/
trigger AGS_ST_UpdateChildrenPaymentIds_gne on AGS_Spend_Expense_Transaction_gne__c (after update) {
    List<Id> changedSpendIds = new List<Id>();
    Map<Id, String> cmsPaymentIdMap = new Map<Id, String>();
    Map<Id, String> homePaymentIdMap = new Map<Id, String>();
    for(AGS_Spend_Expense_Transaction_gne__c s : Trigger.New) {
        AGS_Spend_Expense_Transaction_gne__c oldSpend = Trigger.oldMap.get(s.Id);
        if(s.CMS_Payment_ID_gne__c != oldSpend.CMS_Payment_ID_gne__c || s.Home_Payment_ID_gne__c != oldSpend.Home_Payment_ID_gne__c) {
            changedSpendIds.add(s.Id);
            cmsPaymentIdMap.put(s.Id, s.CMS_Payment_ID_gne__c);
            homePaymentIdMap.put(s.Id, s.Home_Payment_ID_gne__c );
        }
    }
    if( changedSpendIds.size() > 0 ) {
        AGS_ST_DbUtils.updateCmsAndHomeDisputeValues(changedSpendIds, cmsPaymentIdMap, homePaymentIdMap);
    }
}