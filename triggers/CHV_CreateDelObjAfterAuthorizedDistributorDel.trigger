trigger CHV_CreateDelObjAfterAuthorizedDistributorDel on CHV_Authorized_Distributor__c (before delete) {

    List<CHV_Deleted_Object__c> deletedAuthorizedDistributors = new List<CHV_Deleted_Object__c>();
    //List<CHV_Deleted_Object__c> deletedBrandCustomerAccessDistributors = new List<CHV_Deleted_Object__c>();
    //List<CHV_Brand_Customer_Access_Distributor__c> brandCustomerAccessDistributors = [select Id, Name from CHV_Brand_Customer_Access_Distributor__c where Authorized_Distributor__c IN : Trigger.old];
    /*
    if (CHV_Utils.listNotEmpty(brandCustomerAccessDistributors)){
        for(CHV_Brand_Customer_Access_Distributor__c bcad : brandCustomerAccessDistributors) {
            deletedBrandCustomerAccessDistributors.add(new CHV_Deleted_Object__c(Name = bcad.Name, Deleted_Object_Type__c = 'Brand Customer Access Distributor', Deleted_Object_Id__c = bcad.Id));
        }
    }
    
    if (CHV_Utils.listNotEmpty(deletedBrandCustomerAccessDistributors)){
        insert deletedBrandCustomerAccessDistributors;
    }
    */
    for(CHV_Authorized_Distributor__c ad : Trigger.old) {
        deletedAuthorizedDistributors.add(new CHV_Deleted_Object__c(Name = ad.Name, Deleted_Object_Type__c = 'Authorized Distributor', Deleted_Object_Id__c = ad.Id));
    }
    
    if (CHV_Utils.listNotEmpty(deletedAuthorizedDistributors)){
        insert deletedAuthorizedDistributors;
    }

}