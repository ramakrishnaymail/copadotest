trigger EMS_Fund_Request_Trigger on EMS_Fund_Request_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	private boolean validationFailed = false;
    
    if(!EMS_Fund_Request_Trigger_Helper.inFundRequestTrigger) {
        
        if(Trigger.isBefore && Trigger.isInsert){         
           validationFailed = EMS_Fund_Request_Validation_Rules.onBeforeInsert(Trigger.new);
           /*if(! validationFailed) {
           		EMS_Fund_Request_Field_Updates.onBeforeInsert(Trigger.new);
           }*/
        
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
           validationFailed = EMS_Fund_Request_Validation_Rules.onBeforeUpdate(Trigger.oldMap, Trigger.new);
           if(! validationFailed) {
           		EMS_Fund_Request_Field_Updates.onBeforeUpdate(Trigger.oldMap, Trigger.new);
           }
        
        } else if(Trigger.isAfter && Trigger.isInsert){
           if(! validationFailed) {
                EMS_Fund_Request_Child_RecUpdate.onAfterInsertUpdate(null, Trigger.newMap);
            }
            
        } else if(Trigger.isAfter && Trigger.isUpdate){
            if(!validationFailed) {                
                EMS_Fund_Request_Child_RecUpdate.onAfterInsertUpdate(Trigger.oldMap, Trigger.newMap);
            }
            
        } else if(Trigger.isBefore && Trigger.isDelete){
            EMS_Fund_Request_Child_RecUpdate.onBeforeDelete(Trigger.oldMap);
        } 
    }
}