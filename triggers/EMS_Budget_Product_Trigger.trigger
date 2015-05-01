trigger EMS_Budget_Product_Trigger on EMS_Budget_Product_gne__c (before insert, before update, before delete, after insert, after update, after delete) {
       
    private Boolean validationFailed = false;
    
    // Before
    if(Trigger.isBefore && Trigger.isInsert) {
        validationFailed = EMS_Budget_Product_Validation_Rules.onBeforeInsert(Trigger.new);
        if(!validationFailed) {
            EMS_Budget_Product_Field_Updates.onBeforeInsert(null, Trigger.new);
        }
    
    } else if(Trigger.isBefore && Trigger.isUpdate){
        validationFailed = EMS_Budget_Product_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
        if(!validationFailed) {
            EMS_Budget_Product_Field_Updates.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
    
    } else if(Trigger.isBefore && Trigger.isDelete) {
        EMS_Budget_Product_Validation_Rules.onBeforeDelete(trigger.oldMap);
        if(!validationFailed) {
            EMS_Product_Budget_Child_Rec_Updates.onBeforeDelete(trigger.Old);
        }
    
    // After
    } else if(Trigger.isAfter && !validationFailed) {
        if(Trigger.isInsert) {
            EMS_Product_Budget_Child_Rec_Updates.onAfterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            EMS_Product_Budget_Child_Rec_Updates.onAfterUpdate(Trigger.old, Trigger.new);
        }
    }
}