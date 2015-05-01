trigger GNE_SFA2_PFG_SL_Trigger on SFA2_PFG_Storage_Location_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    if(!GNE_SFA2_PFG_SL_Trigger_Helper.inSLTrig() && 
       !GNE_SFA2_Util.isAdminMode() && 
	   !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PFG_SL_Trigger')) {
	   	
	    GNE_SFA2_PFG_SL_Trigger_Helper.setSLTrig(true);
	    
	    if(Trigger.isBefore && Trigger.isInsert){
	      GNE_SFA2_PFG_SL_Trigger_Helper.clearFailedValidations();
	      GNE_SFA2_PFG_SL_Validation_Rules.onBeforeInsert(Trigger.new);
	      GNE_SFA2_PFG_SL_Field_Updates.onBeforeInsert(Trigger.new);
	    } else if(Trigger.isBefore && Trigger.isUpdate) {
	      GNE_SFA2_PFG_SL_Trigger_Helper.clearFailedValidations();
	    GNE_SFA2_PFG_SL_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
	      GNE_SFA2_PFG_SL_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
	    } else if(Trigger.isBefore && Trigger.isDelete){
	      GNE_SFA2_PFG_SL_Trigger_Helper.clearFailedValidations();
	    GNE_SFA2_PFG_SL_Validation_Rules.onBeforeDelete(Trigger.old);
	      GNE_SFA2_PFG_SL_Field_Updates.onBeforeDelete(Trigger.old);
	    } else if(Trigger.isAfter && Trigger.isInsert){
	      GNE_SFA2_PFG_SL_Child_Record_Updates.onAfterInsert(Trigger.new);
	    } else if(Trigger.isAfter && Trigger.isUpdate){
	      GNE_SFA2_PFG_SL_Child_Record_Updates.onAfterUpdate(Trigger.old, Trigger.new);
	    } else if(Trigger.isAfter && Trigger.isDelete){
	      GNE_SFA2_PFG_SL_Child_Record_Updates.onAfterDelete(Trigger.old);
	    }
	    
	    GNE_SFA2_PFG_SL_Trigger_Helper.setSLTrig(false);
    }
}