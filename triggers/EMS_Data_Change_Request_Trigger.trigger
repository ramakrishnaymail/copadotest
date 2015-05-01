trigger EMS_Data_Change_Request_Trigger on EMS_Data_Change_Request_gne__c (after insert, after update, before insert, before update) {
    
    private boolean validationFailed = false;
    
    if(Trigger.isBefore && Trigger.isInsert) {
      
    } else if (Trigger.isBefore && Trigger.isUpdate) {  
    
    } else if(Trigger.isAfter && Trigger.isInsert) {
		EMS_DataChRequest_Notifications.notificationsOnAfterInsertUpdate (null, Trigger.new);
		//EMS_Data_Change_Request_Child_Rec_Update.onAfterInsertUpdate(Trigger.new); 

    } else if(Trigger.isAfter && Trigger.isUpdate) {
		EMS_DataChRequest_Notifications.notificationsOnAfterInsertUpdate (Trigger.oldMap, Trigger.new);
		//EMS_Data_Change_Request_Child_Rec_Update.onAfterInsertUpdate(Trigger.new);
    }
}