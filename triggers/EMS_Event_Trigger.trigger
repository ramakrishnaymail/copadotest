trigger EMS_Event_Trigger on EMS_Event__c (before update, before insert, before delete, after insert, after update) {
	
    private boolean validationFailed = false;
	if(Trigger.isBefore && Trigger.isInsert) {
		validationFailed = EMS_Event_Validation_Rules.onBeforeInsert(Trigger.new);
	    if(!validationFailed) {
	      	EMS_Event_Field_Updates.onBeforeInsert(Trigger.new);
	    }
	} else if (Trigger.isBefore && Trigger.isUpdate) {
	    validationFailed = EMS_Event_Validation_Rules.onBeforeUpdate(Trigger.oldMap, Trigger.new);
	    if(!validationFailed) {
	      	EMS_Event_Field_Updates.onBeforeUpdate(Trigger.oldMap, Trigger.new);
	    }    
	} else if(Trigger.isBefore && Trigger.isDelete) {
	    validationFailed = EMS_Event_Validation_Rules.onBeforeDelete(trigger.oldMap);
	    if(!validationFailed) {
	    	EMS_Event_Child_Records_Update.onBeforeDelete(Trigger.oldMap);
	    	
	    	// add events to already processed set to avoid re-executing trigger logic
        	EMS_Event_Trigger_Helper.addToProcessed(Trigger.old);   
	    }
	} else if(Trigger.isAfter && Trigger.isInsert) {
	    if(!validationFailed) {
	    	EMS_Event_Child_Records_Update.onAfterInsert(Trigger.newMap);
	    	
	    	// add events to already processed set to avoid re-executing trigger logic
        	EMS_Event_Trigger_Helper.addToProcessed(Trigger.new);    		
	    }
	} else if(Trigger.isAfter && Trigger.isUpdate) {
	    if(!validationFailed) {
	    	EMS_Event_Child_Records_Update.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
	        EMS_Event_Email_Notifications.onAfterUpdate(Trigger.old, Trigger.new);
	        
	         // add events to already processed set to avoid re-executing trigger logic
        	EMS_Event_Trigger_Helper.addToProcessed(Trigger.new);
	    }
	}
}