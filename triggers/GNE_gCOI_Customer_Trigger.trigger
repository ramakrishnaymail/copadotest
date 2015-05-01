trigger GNE_gCOI_Customer_Trigger on GNE_gCOI_Customer__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (!GNE_SFA2_Util.isAdminMode()) {
        if (Trigger.isBefore && Trigger.isInsert) {
            GNE_gCOI_Customer_Field_Updates.onBeforeInsert(Trigger.new);
        }
    }
}