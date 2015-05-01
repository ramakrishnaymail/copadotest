trigger GNE_SFA2_Spkr_Contract_Trigger on Speaker_Contract_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	
	if (!GNE_SFA2_Util.isAdminMode())
	{
		
		 
		
	   if(Trigger.IsAfter && Trigger.isInsert){
			
			GNE_SFA2_Spkr_Contract_Field_Updates.onAfterInsert(trigger.new);
			
		}
		else if(Trigger.isAfter && Trigger.isUpdate){
			
			GNE_SFA2_Spkr_Contract_Field_Updates.onAfterUpdate(trigger.new);
			 
		}
		
		
	}
	
	

}