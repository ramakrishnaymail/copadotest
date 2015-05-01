trigger EMS_Meeting_Room_Trigger on EMS_Meeting_Room_gne__c  (before update, before insert, after insert, after update) {

	private boolean validationFailed = false;
	if(Trigger.isBefore && Trigger.isInsert) {
	    if(!validationFailed) {

	    }
	} else if (Trigger.isBefore && Trigger.isUpdate) {
	    if(!validationFailed) {

	    }    
	} else if(Trigger.isAfter && Trigger.isInsert) {
	    if(!validationFailed) {
	    	EMS_Meeting_Room_Child_Records_Update.onAfterInsert(Trigger.newMap);
	    }
	} else if(Trigger.isAfter && Trigger.isUpdate) {
	    if(!validationFailed) {
	    	EMS_Meeting_Room_Child_Records_Update.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
	    }
	}

}