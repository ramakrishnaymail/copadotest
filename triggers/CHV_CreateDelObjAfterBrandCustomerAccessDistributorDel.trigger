trigger CHV_CreateDelObjAfterBrandCustomerAccessDistributorDel on CHV_Brand_Customer_Access_Distributor__c (before delete) {

	List<CHV_Deleted_Object__c> deletedObjects = new List<CHV_Deleted_Object__c>();
	
	for(CHV_Brand_Customer_Access_Distributor__c bcad : Trigger.old) {
		deletedObjects.add(new CHV_Deleted_Object__c(Name = bcad.Name, Deleted_Object_Type__c = 'Brand Customer Access Distributor', Deleted_Object_Id__c = bcad.Id));
	}
	
	if (CHV_Utils.listNotEmpty(deletedObjects)){
		insert deletedObjects;
	}
	
}