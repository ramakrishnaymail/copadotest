trigger EMS_Travel_Trigger on EMS_Travel_gne__c (after insert, after update, before insert, before update) {
		
    private boolean validationFailed = false;
    
    if(Trigger.isBefore && Trigger.isInsert) {
      
    } else if (Trigger.isBefore && Trigger.isUpdate) {  
   
    } else if(Trigger.isAfter && Trigger.isInsert) {
		EMS_Travel_Email_Notifications.notificationsOnAfterInsert (Trigger.new);
 
    } else if(Trigger.isAfter && Trigger.isUpdate) {

    }
}