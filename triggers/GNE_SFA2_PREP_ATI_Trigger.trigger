trigger GNE_SFA2_PREP_ATI_Trigger on SFA2_PREP_Account_Testing_Info_gne__c (before insert, before update, after delete) {
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PREP_ATI_Trigger') 
		&& !GNE_SFA2_PREP_Trigger_Helper.inAccTestingInfoTrig()) {
        	               
        GNE_SFA2_PREP_Trigger_Helper.setAccTestingInfoTrig(true);

        if(Trigger.isBefore && Trigger.isInsert) {
        	GNE_SFA2_PREP_ATI_Validation_Rules.onBeforeInsert(Trigger.new);
        	GNE_SFA2_PREP_ATI_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) {
        	GNE_SFA2_PREP_ATI_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
			GNE_SFA2_PREP_ATI_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isDelete){            
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, SFA2_PREP_Account_Testing_Info_gne__c.getSObjectType());            
        } 

        GNE_SFA2_PREP_Trigger_Helper.setAccTestingInfoTrig(false);
    }
}