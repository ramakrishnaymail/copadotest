/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-08-03
*  Description: This is a trigger for handling Contact validations, field updates and child record updates
*  Test class: GNE_SFA2_Contact_Trigger_Test
*
*  Modification History
*  Date        Name        Description
*
*************************************************************/
trigger GNE_SFA2_Contact_Trigger on Contact (after delete, after insert, after undelete,
        after update, before delete, before insert, before update) {
    private boolean validationFailed = false;
    if (!GNE_SFA2_Util.isAdminMode() 
            && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Contact_Trigger__c')) {

        if (Trigger.isBefore && Trigger.isInsert) {
            validationFailed = GNE_SFA2_Contact_Validation_Rules.onBeforeInsert(Trigger.new);
        } else if (Trigger.isBefore && Trigger.isUpdate) {
            validationFailed = GNE_SFA2_Contact_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
            if (!validationFailed) {
                GNE_SFA2_Contact_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
                GNE_SFA2_Contact_Child_Record_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
                autoContactAffiliationHandler.onContactUpdate(Trigger.old, Trigger.new);
            }
        } else if (Trigger.isBefore && Trigger.isDelete) {
            if (!validationFailed) {
                GNE_SFA2_Contact_Trigger_Helper.createContactsMap(Trigger.old);     // create contacts map, which is used later in after trigger
                GNE_SFA2_Contact_Child_Record_Updates.onBeforeDelete(Trigger.old);
            }
        } else if (Trigger.isAfter && Trigger.isInsert) {
            if (!validationFailed) {
                autoContactAffiliationHandler.onContactUpdate(Trigger.old, Trigger.new);
                GNE_SFA2_Contact_Child_Record_Updates.onAfterInsert(Trigger.new);
            }
        } else if (Trigger.isAfter && Trigger.isDelete) {
            validationFailed = GNE_SFA2_Contact_Validation_Rules.onAfterDelete(Trigger.old);
            if (!validationFailed) {
                GNE_SFA2_Contact_Child_Record_Updates.onAfterDelete(Trigger.old);
            }
        }
        //GNE_SFA2_Contact_Email_Notifications
    }
}