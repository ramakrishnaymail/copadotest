trigger EMS_Speaker_Role_Trigger on EMS_Speaker_Role_gne__c (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
         EMS_Speaker_Role_Child_Record_Updates.onAfterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
    	EMS_Speaker_Role_Child_Record_Updates.onAfterUpdate(Trigger.new);
    }
}