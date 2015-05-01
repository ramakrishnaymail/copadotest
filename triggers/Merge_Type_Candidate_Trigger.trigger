trigger Merge_Type_Candidate_Trigger on Merge_Type_Candidate_Stage_gne__c (before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('Merge_Type_Candidate_Trigger')) {
		if(Trigger.isBefore && Trigger.isInsert) {
			Merge_Type_Candidate_Field_Updates.onBeforeInsert(Trigger.new);
		} else if(Trigger.isBefore && Trigger.isUpdate) {
			Merge_Type_Candidate_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
		}
	}
}