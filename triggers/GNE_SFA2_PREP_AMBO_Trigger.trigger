trigger GNE_SFA2_PREP_AMBO_Trigger on SFA2_PREP_Account_MBO_gne__c (after delete, after insert, after undelete, 
after update, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PREP_AMBO_Trigger') 
        && !GNE_SFA2_PREP_Trigger_Helper.inAccMBOTrig()) {
                           
        GNE_SFA2_PREP_Trigger_Helper.setAccMBOTrig(true);

        if(Trigger.isBefore && Trigger.isInsert){   
            GNE_SFA2_PREP_AMBO_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
            GNE_SFA2_PREP_AMBO_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isInsert){
            GNE_SFA2_PREP_AMBO_Parent_Record_Updates.onAfterInsert(Trigger.new);
        } else if(Trigger.isAfter && Trigger.isUpdate){
            GNE_SFA2_PREP_AMBO_Parent_Record_Updates.onAfterUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isDelete){
            GNE_SFA2_PREP_AMBO_Parent_Record_Updates.onAfterDelete(Trigger.old);
        } else if(Trigger.isAfter && Trigger.isUndelete){
            GNE_SFA2_PREP_AMBO_Parent_Record_Updates.onAfterUndelete(Trigger.old);
        }

        GNE_SFA2_PREP_Trigger_Helper.setAccMBOTrig(false);
    }
}