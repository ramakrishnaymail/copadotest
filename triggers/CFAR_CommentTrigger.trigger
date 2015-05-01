trigger CFAR_CommentTrigger on CFAR_Comment_gne__c (before insert) {
	Set<Id> trialsIds = new Set<Id>();
	for (CFAR_Comment_gne__c comment : Trigger.new) {
		trialsIds.add(comment.CFAR_Trial_ref_gne__c);
	}
	List<CFAR_Trial_gne__c> trials = [select Id, Trial_Status_ref_gne__c from CFAR_Trial_gne__c where Id IN :trialsIds and Trial_Status_ref_gne__c != null];
	Map<Id,Id> trialsMap = new Map<Id,Id>();
	for(CFAR_Trial_gne__c trial : trials) {
		trialsMap.put(trial.Id, trial.Trial_Status_ref_gne__c);
	}
	
	//List<CFAR_Comment_gne__c> comments = new List<CFAR_Comment_gne__c>();
	for (CFAR_Comment_gne__c comment : Trigger.new) {
		comment.Trial_Status_ref_gne__c = trialsMap.get(comment.CFAR_Trial_ref_gne__c);
		//comments.add(comment);
	}
	//update comments;
}