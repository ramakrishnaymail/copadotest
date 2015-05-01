trigger GNE_SFA2_Product_Team_Trigger on Speaker_Bureau_Product_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	
	
	if (!GNE_SFA2_Util.isAdminMode())
	{
	  
	  if(trigger.IsBefore && trigger.IsInsert){
	  	GNE_SFA2_Product_Team_Field_Updates.onBeforeInsert(trigger.new);
	  } 
	  
	  
	  if(trigger.IsBefore && trigger.IsUpdate){
	  	GNE_SFA2_Product_Team_Field_Updates.onBeforeUpdate(trigger.new);
	  }
	  
	  
	  if(trigger.IsAfter && trigger.IsInsert){
	  	GNE_SFA2_Product_Team_Field_Updates.onAfterInsert(trigger.new);
	  }
	  
	  
	  if(trigger.IsAfter && trigger.IsUpdate){
	  	GNE_SFA2_Product_Team_Field_Updates.onAfterUpdate(trigger.new);
	  }
	  
	}
		
	
	

}