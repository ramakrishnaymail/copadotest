trigger GNE_SFA2_Membership_Training_Trigger on Member_Trainings_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode()){
		if(Trigger.IsInsert && Trigger.IsBefore){
			GNE_SFA2_Member_Train_Validation_Rules.onBeforeInsert(trigger.new);
		}
		if(Trigger.IsUpdate && Trigger.IsBefore){
			GNE_SFA2_Member_Train_Validation_Rules.onBeforeUpdate(trigger.new);
		}
	}
}