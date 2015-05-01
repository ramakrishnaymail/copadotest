/** @date 25/9/2014
* @Author Konrad Malinowski
* @description Trigger for update AGS Spend Expense Transaction CMS Dispute Id from AGS ST Dispute List
*/
trigger AGS_ST_UpdateCmsDisputeId on AGS_ST_Dispute_List_gne__c (before insert, after insert, before update, after update, after delete) {
    if(Trigger.isBefore) {
        for(AGS_ST_Dispute_List_gne__c d : Trigger.New) {
            if( String.isBlank(d.CmsDisputeId_gne__c) ) {
                d.CmsDisputeIdDateTime_gne__c = null;
            } else {
                Boolean isCmsDisputeIdUpdated = (
                    Trigger.isUpdate &&
                    Trigger.oldMap.get(d.Id).CmsDisputeId_gne__c != Trigger.newMap.get(d.Id).CmsDisputeId_gne__c
                );
                if(Trigger.isInsert || isCmsDisputeIdUpdated) {
                    d.CmsDisputeIdDateTime_gne__c = System.now();
                }
            }
        }
    }
    if(Trigger.isAfter) {
        List<Id> spendIds = new List<Id>();
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(AGS_ST_Dispute_List_gne__c d : Trigger.New) {
                Boolean isCmsDisputeIdInserted = (
                    Trigger.isInsert &&
                    String.isNotBlank( Trigger.newMap.get(d.Id).CmsDisputeId_gne__c )
                );
                Boolean isCmsDisputeIdUpdated = (
                    Trigger.isUpdate &&
                    Trigger.oldMap.get(d.Id).CmsDisputeId_gne__c != Trigger.newMap.get(d.Id).CmsDisputeId_gne__c
                );
                if(isCmsDisputeIdInserted || isCmsDisputeIdUpdated) {
                    spendIds.add(d.AGS_Spend_Expense_Transaction_gne__c);
                }
            }
        } else {
            for(AGS_ST_Dispute_List_gne__c d : Trigger.Old) {
                if( String.isNotBlank( Trigger.oldMap.get(d.Id).CmsDisputeId_gne__c ) ) {
                    spendIds.add(d.AGS_Spend_Expense_Transaction_gne__c);
                }
            }
        }
        List<AGS_Spend_Expense_Transaction_gne__c> spends = [
            SELECT Id, CmsDispute_gne__c, CmsDisputeId_gne__c, (
                SELECT  Id, CmsDisputeId_gne__c
                FROM    AGS_ST_Dispute_Lists__r
                WHERE   IsCmsDispute_gne__c = true
                ORDER BY CmsDisputeIdDateTime_gne__c DESC
            )
            FROM    AGS_Spend_Expense_Transaction_gne__c
            WHERE   Id IN :spendIds
        ];
        for(AGS_Spend_Expense_Transaction_gne__c s : spends) {
            s.CmsDispute_gne__c = !s.AGS_ST_Dispute_Lists__r.isEmpty();
            s.CmsDisputeId_gne__c = ( s.AGS_ST_Dispute_Lists__r.isEmpty() ? null : s.AGS_ST_Dispute_Lists__r[0].CmsDisputeId_gne__c );
        }
        update spends;
    }
}