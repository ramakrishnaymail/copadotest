trigger GNE_SFA2_AccSocMem_Trigger on SFA2_Account_Society_Membership_gne__c (before insert, before update, after delete) {
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_AccSocMem_Trigger') 
        && !GNE_SFA2_AccSocMem_Trigger_Helper.inAccSocMemTrig()) {
                           
        GNE_SFA2_AccSocMem_Trigger_Helper.setAccSocMemTrig(true);

        if(Trigger.isBefore && Trigger.isInsert) {
        	GNE_SFA2_AccSocMem_Validation_Rules.onBeforeInsert(Trigger.new);
            GNE_SFA2_AccSocMem_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) {
        	GNE_SFA2_AccSocMem_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new); 
            GNE_SFA2_AccSocMem_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isDelete){            
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, SFA2_Account_Society_Membership_gne__c.getSObjectType());            
        }     

        GNE_SFA2_AccSocMem_Trigger_Helper.setAccSocMemTrig(false);
    }
}