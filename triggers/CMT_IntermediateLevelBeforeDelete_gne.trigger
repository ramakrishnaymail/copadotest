trigger CMT_IntermediateLevelBeforeDelete_gne on CMT_Intermediate_Level_gne__c (before delete) {
	
	//CMT_MiscUtils.onDeleteTrigger ('CMT_Intermediate_Level_gne__c', Trigger.old);
	
	List<ID> ids = new List<Id>();
	
	for (CMT_Intermediate_Level_gne__c s : Trigger.old)
	{
		ids.add(s.Id);
	}
	
	List<CMT_FranchiseToSession_gne__c> fts = [SELECT Id FROM CMT_FranchiseToSession_gne__c WHERE CMT_Intermediate_Level_gne__c in :ids];
	
	if (fts != null && !fts.isEmpty())
	{
		delete fts;
	}
}