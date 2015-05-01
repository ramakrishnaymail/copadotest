trigger CHV_CreateDelObjAfterCustomerAccessDel on CHV_Customer_Access__c (before delete) {
    
    List<CHV_Deleted_Object__c> deletedCustomerAccessTypes = new List<CHV_Deleted_Object__c>();
    //List<CHV_Deleted_Object__c> deletedBrandCustomerAccess = new List<CHV_Deleted_Object__c>();
    //List<CHV_Brand_Customer_Access__c> brandCustomerAccessTypes = [select Id, Name from CHV_Brand_Customer_Access__c where Customer_Access__c IN : Trigger.old];
    //List<CHV_Brand_Customer_Access_Distributor__c> brandCustomerAccessDistributors = [select Id, Name from CHV_Brand_Customer_Access_Distributor__c where Brand_Customer_Access__r.Customer_Access__c IN : Trigger.old];
    /*
    if (CHV_Utils.listNotEmpty(brandCustomerAccessDistributors)){
        delete brandCustomerAccessDistributors;
    }
    
    if (CHV_Utils.listNotEmpty(brandCustomerAccessTypes)){
        for(CHV_Brand_Customer_Access__c bca : brandCustomerAccessTypes) {
            deletedBrandCustomerAccess.add(new CHV_Deleted_Object__c(Name = bca.Name, Deleted_Object_Type__c = 'Brand Customer Access', Deleted_Object_Id__c = bca.Id));
        }
    }
    
    if (CHV_Utils.listNotEmpty(deletedBrandCustomerAccess)){
        insert deletedBrandCustomerAccess;
    }
    */
    for(CHV_Customer_Access__c ca : Trigger.old) {
        deletedCustomerAccessTypes.add(new CHV_Deleted_Object__c(Name = ca.Name, Deleted_Object_Type__c = 'Customer Access', Deleted_Object_Id__c = ca.Id));
    }
    
    if (CHV_Utils.listNotEmpty(deletedCustomerAccessTypes)){
        insert deletedCustomerAccessTypes;
    }
    
}