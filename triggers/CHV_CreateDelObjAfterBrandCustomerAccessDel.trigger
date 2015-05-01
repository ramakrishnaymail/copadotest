trigger CHV_CreateDelObjAfterBrandCustomerAccessDel on CHV_Brand_Customer_Access__c (before delete) {

    List<CHV_Deleted_Object__c> deletedBrandCustomerAccess = new List<CHV_Deleted_Object__c>();
   /*
    List<CHV_Brand_Customer_Access_Distributor__c> brandCustomerAccessDistributors = [select Id, Name from CHV_Brand_Customer_Access_Distributor__c where Brand_Customer_Access__c IN : Trigger.old];

    if (CHV_Utils.listNotEmpty(brandCustomerAccessDistributors)){
        delete brandCustomerAccessDistributors;
    }
    */
    for(CHV_Brand_Customer_Access__c bca : Trigger.old) {
        deletedBrandCustomerAccess.add(new CHV_Deleted_Object__c(Name = bca.Name, Deleted_Object_Type__c = 'Brand Customer Access', Deleted_Object_Id__c = bca.Id));
    }
    
    if (CHV_Utils.listNotEmpty(deletedBrandCustomerAccess)){
        insert deletedBrandCustomerAccess;
    }
    
}