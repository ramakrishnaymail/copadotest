trigger GNE_SFA2_Advocacy_Assesment_Trigger on Advocacy_Assessment_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	
	if (!GNE_SFA2_Util.isAdminMode())
   {
   	   	
   	  if(Trigger.IsBefore && Trigger.IsInsert){
   	  	
   	  	GNE_SFA2_Advocacy_Asmnt_Validation_Rules.onBeforeInsert(trigger.New);
   	  	   	  	
   	  }
   	  
   	  else if(Trigger.IsBefore && Trigger.IsUpdate){
   	  	
   	     GNE_SFA2_Advocacy_Asmnt_Validation_Rules.onBeforeUpdate(trigger.New,trigger.Old);
   	  }
   }

}