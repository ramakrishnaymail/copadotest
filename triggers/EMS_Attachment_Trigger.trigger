trigger EMS_Attachment_Trigger on EMS_Attachment_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	boolean validationFailed = false;
	
	if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		validationFailed = EMS_Attachment_Validation_Rules.onBeforeInsertUpdate(Trigger.old, Trigger.new);
	} else if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
		if(!validationFailed) {
			EMS_Attachment_Child_Record_Updates.onAfterInsertUpdate(Trigger.old, Trigger.new);
		}
    }
}