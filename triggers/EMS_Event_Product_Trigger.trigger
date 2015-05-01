trigger EMS_Event_Product_Trigger on EMS_Event_Product_gne__c (before update, before insert, before delete, after insert, after update) {

	private boolean validationFailed = false;	

	if(Trigger.isBefore) {
    	if(Trigger.isInsert){
        	validationFailed = EMS_Event_Product_Validation_Rules.onBeforeInsert(Trigger.new); 

    	} else if(Trigger.isUpdate){
    		validationFailed = EMS_Event_Product_Validation_Rules.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    	}
    }
}