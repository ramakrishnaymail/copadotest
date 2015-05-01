/************************************************************
*  @author: Rakesh Boinepalli 
*  Date: 2012-12-16
*  Description: This is a trigger for handling Speaker Training validations, field updates and child record updates
*  Test class: GNE_SFA2_Spkr_Training_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/

trigger GNE_SFA2_Spkr_Training_Trigger on Speaker_Training_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode()){
	   if(Trigger.IsAfter && Trigger.isInsert){
			GNE_SFA2_Spkr_Training_Field_Updates.onAfterInsert(trigger.new);
		}else if(Trigger.isAfter && Trigger.isUpdate){
			GNE_SFA2_Spkr_Training_Field_Updates.onAfterUpdate(trigger.new);
		}
	}
}