trigger GNE_SFA2_Influence_Metrics_Trigger on Influence_Metrics_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	
	if (!GNE_SFA2_Util.isAdminMode())
	{
	 
	  if(trigger.IsBefore && trigger.IsInsert){
	  	GNE_SFA2_Influence_Metrics_Field_Updates.onBeforeInsert(trigger.new);
	  } 
	  
	  
	  if(trigger.IsBefore && trigger.IsUpdate){
	  	GNE_SFA2_Influence_Metrics_Field_Updates.onBeforeUpdate(trigger.new);
	  }
	}
}