trigger GNE_SFA2_Intelligence_Notes_Trigger on Intelligence_Notes_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if (!GNE_SFA2_Util.isAdminMode()) {
        if(Trigger.isAfter && Trigger.isInsert) {
            GNE_SFA2_Int_Notes_Child_Record_Updates.onAfterInsert(Trigger.new);
        } 
    }
}