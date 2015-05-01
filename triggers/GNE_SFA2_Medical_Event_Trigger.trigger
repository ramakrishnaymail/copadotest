trigger GNE_SFA2_Medical_Event_Trigger on Medical_Event_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {


	if (!GNE_SFA2_Util.isAdminMode())
	{
		
		
	   if(Trigger.IsBefore && Trigger.isInsert){
			
			GNE_SFA2_Medical_Event_Validation_Rules.onBeforeInsert(trigger.new);
			
		} 
		 
		
	   if(Trigger.IsBefore && Trigger.isUpdate){
			
			GNE_SFA2_Medical_Event_Validation_Rules.onBeforeUpdate(trigger.new);
			
		}
		
		
	   if(Trigger.IsBefore && Trigger.isDelete){
			
			GNE_SFA2_Medical_Event_Validation_Rules.onBeforeDelete(trigger.oldMap.keySet(),trigger.Old);
			
		}
	}
}