trigger EMS_Budget_Territory_Trigger on EMS_Budget_Territory_gne__c (before insert, before update, before delete, after insert, after update, after delete) {
    
    private boolean validationFailed = false;
    
    // Before
    if(Trigger.isBefore && Trigger.isInsert) {
        validationFailed = EMS_Budget_Territory_Validation_Rules.onBeforeInsert(Trigger.new);
        if(!validationFailed) {
            EMS_Budget_Territory_Field_Updates.onBeforeInsert(Trigger.new);
        }
        
    } else if(Trigger.isBefore && Trigger.isUpdate) {
        validationFailed = EMS_Budget_Territory_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
        if(!validationFailed) {
            EMS_Budget_Territory_Field_Updates.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
        
    } else if(Trigger.isBefore && Trigger.isDelete) {
        EMS_Territory_Budget_Child_Rec_Updates.onBeforeDelete(trigger.Old);
    
    // After            
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert && !validationFailed) {
            EMS_Territory_Budget_Child_Rec_Updates.onAfterInsert(Trigger.new);
        } else if(Trigger.isUpdate && !validationFailed) {
            EMS_Territory_Budget_Child_Rec_Updates.onAfterUpdate(Trigger.old, Trigger.new);
        }
    }
}