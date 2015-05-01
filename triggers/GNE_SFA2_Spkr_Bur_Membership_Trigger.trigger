trigger GNE_SFA2_Spkr_Bur_Membership_Trigger on Speaker_Bureau_Membership_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode()) {				
		if(Trigger.IsBefore && Trigger.IsInsert){			
			GNE_SFA2_Spkr_Bur_Mem_Validation_Rules.onBeforeInsert(trigger.New);			
		} else if(Trigger.IsBefore && Trigger.IsUpdate){			
			GNE_SFA2_Spkr_Bur_Mem_Validation_Rules.onBeforeUpdate(trigger.Old,trigger.New,trigger.OldMap,trigger.newMap);
		} else if(Trigger.IsAfter && Trigger.isInsert){			
			GNE_SFA2_Spkr_Bur_Mem_Field_Updates.onAfterInsert(trigger.new);			
		} else if(Trigger.isAfter && Trigger.isUpdate){			
			GNE_SFA2_Spkr_Bur_Mem_Field_Updates.onAfterUpdate(trigger.old,trigger.new);			 
		} else if(Trigger.isAfter && Trigger.isDelete){            
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Speaker_Bureau_Membership_gne__c.getSObjectType());            
        }		
	}
}