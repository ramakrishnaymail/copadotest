trigger EMS_Budget_Allocation_Trigger on EMS_Budget_Allocation_gne__c (after insert, after undelete, after update, before delete, before insert, before update, after delete) {

    private boolean validationFailed = false;
    // Before
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            validationFailed = EMS_Budget_Allocation_Validation_Rules.onBeforeInsert(Trigger.new);
            if (!validationFailed) {
                EMS_Budget_Allocation_Field_Updates.onBeforeInsert(Trigger.new);
            }
        } else if (Trigger.IsUpdate) {
            validationFailed = EMS_Budget_Allocation_Validation_Rules.onBeforeUpdate(Trigger.oldMap, Trigger.new);
            if (!validationFailed) {
                EMS_Budget_Allocation_Field_Updates.onBeforeUpdate(Trigger.oldMap, Trigger.new);
            }
        } else if (Trigger.isDelete) {
            EMS_Budget_Allocation_Child_Rec_Update.onBeforeDelete(trigger.OldMap);
        }
    }

    // After
    if (Trigger.IsAfter) {
        if (Trigger.isInsert) {
            if (!validationFailed) {
                EMS_Budget_Allocation_Child_Rec_Update.onAfterInsert(Trigger.newMap);
                EMS_Budget_Allocation_Email_Notification.onAfterInsertUpdate(Trigger.oldMap, Trigger.newMap);
            }
        } else if (Trigger.IsUpdate) {
            if (!validationFailed) {
                EMS_Budget_Allocation_Child_Rec_Update.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
                EMS_Budget_Allocation_Email_Notification.onAfterInsertUpdate(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}