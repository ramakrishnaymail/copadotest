trigger EMS_GSD_Detail_Trigger on EMS_GSD_Detail__c (before insert, before update, after insert, after update) {

	private boolean validationFailed = false;
	
	if(Trigger.isBefore) {      	
    	if(Trigger.isInsert){	
        	validationFailed = EMS_GSD_Detail_Validation_Rules.onBeforeInsert(Trigger.new); 
    	} else if(Trigger.IsUpdate){
    		validationFailed = EMS_GSD_Detail_Validation_Rules.onBeforeUpdate(Trigger.new);
    	}
    } else if(Trigger.isAfter) {
    	if(Trigger.isInsert || Trigger.isUpdate) {
	    	if(!validationFailed) {
	    		EMS_GSD_Detail_Child_Record_Updates.onAfterInsertUpdate(Trigger.new);
	    	}
	    }
    }
}