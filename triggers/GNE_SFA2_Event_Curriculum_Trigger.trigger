trigger GNE_SFA2_Event_Curriculum_Trigger on Event_Curriculum_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode())
    {
   	   	
   	  if(Trigger.IsBefore && Trigger.IsInsert){
   	  	
   	   	GNE_SFA2_Event_Curriculum_Field_Updates.onBeforeInsert(trigger.New);
   	   	
   	  }
   	  if(Trigger.IsBefore && Trigger.IsUpdate){
   	  	
   	  	GNE_SFA2_Event_Curriculum_Field_Updates.onBeforeInsert(trigger.New);
   	  }
   	  
    }
}