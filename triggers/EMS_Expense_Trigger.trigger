trigger EMS_Expense_Trigger on EMS_Expense_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if(Trigger.isAfter && Trigger.isInsert) {
    	EMS_Expense_Child_Record_Updates.onAfterInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isUpdate) {
        EMS_Expense_Child_Record_Updates.onAfterUpdate(Trigger.oldMap, Trigger.newMap);    	
    } else if(Trigger.isAfter && Trigger.isDelete) {
        EMS_Expense_Child_Record_Updates.onAfterDelete(Trigger.old);    	
    } else if(Trigger.isAfter && Trigger.isUndelete) {
        EMS_Expense_Child_Record_Updates.onAfterUndelete(Trigger.new);    	
    }
}