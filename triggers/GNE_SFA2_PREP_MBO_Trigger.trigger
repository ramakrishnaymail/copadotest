trigger GNE_SFA2_PREP_MBO_Trigger on SFA2_PREP_MBO_gne__c (before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PREP_MBO_Trigger')
		&& !GNE_SFA2_PREP_Trigger_Helper.inMboTrig()) {
        	               
        GNE_SFA2_PREP_Trigger_Helper.setMboTrig(true);
        if(Trigger.isBefore && Trigger.isInsert){   
        	GNE_SFA2_PREP_MBO_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
			GNE_SFA2_PREP_MBO_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        }
        
        GNE_SFA2_PREP_Trigger_Helper.setMboTrig(false);
    }
}