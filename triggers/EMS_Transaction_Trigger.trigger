trigger EMS_Transaction_Trigger on EMS_Transaction_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	private boolean validationFailed = false;
	
    if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
    	validationFailed = EMS_Transaction_Validation_Rules.onBeforeInsert(Trigger.new);
        if(!validationFailed) {
    		EMS_Transaction_Field_Updates.onBeforeInsertUpdate(Trigger.old, Trigger.new);
        }
    } else if(Trigger.isBefore && Trigger.isDelete) {
            
    } else if(Trigger.isAfter && Trigger.isDelete) {
    	EMS_Transaction_Child_Record_Updates.onAfterDelete(Trigger.old);
    } else if(Trigger.isAfter && Trigger.isUpdate) {
    	if(!validationFailed) {
    		EMS_Transaction_Child_Record_Updates.onAfterUpdate(Trigger.new);
    	}
    }
}