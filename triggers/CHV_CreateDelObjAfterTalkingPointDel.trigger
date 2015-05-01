trigger CHV_CreateDelObjAfterTalkingPointDel on CHV_Talking_Point__c (before delete) {
	
	List<CHV_Deleted_Object__c> deletedObjects = new List<CHV_Deleted_Object__c>();
	
	for(CHV_Talking_Point__c tp : Trigger.old) {
		deletedObjects.add(new CHV_Deleted_Object__c(Name = tp.Name, Deleted_Object_Type__c = 'Talking Point', Deleted_Object_Id__c = tp.Id));
	}
	
	if (CHV_Utils.listNotEmpty(deletedObjects)){
		insert deletedObjects;
	}
	
}