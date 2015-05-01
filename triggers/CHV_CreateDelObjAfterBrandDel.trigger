trigger CHV_CreateDelObjAfterBrandDel on CHV_Brand__c (before delete) {

    List<CHV_Talking_Point__c> talkingPoints = [select Id, Name from CHV_Talking_Point__c where Brand__c IN : Trigger.old];
    List<CHV_Deleted_Object__c> deletedTalkingPoints = new List<CHV_Deleted_Object__c>();
    //List<CHV_Deleted_Object__c> deletedBrandCustomerAccess = new List<CHV_Deleted_Object__c>();
    List<CHV_Deleted_Object__c> deletedBrands = new List<CHV_Deleted_Object__c>();
    //List<CHV_Brand_Customer_Access__c> brandCustomerAccessTypes = [select Id, Name from CHV_Brand_Customer_Access__c where Brand__c IN : Trigger.old];
    //List<CHV_Brand_Customer_Access_Distributor__c> brandCustomerAccessDistributors = [select Id, Name from CHV_Brand_Customer_Access_Distributor__c where Brand_Customer_Access__r.Brand__c IN : Trigger.old];
    
    if (CHV_Utils.listNotEmpty(talkingPoints)){
        for(CHV_Talking_Point__c tp : talkingPoints) {
            deletedTalkingPoints.add(new CHV_Deleted_Object__c(Name = tp.Name, Deleted_Object_Type__c = 'Talking Point', Deleted_Object_Id__c = tp.Id));
        }
    }
    
    if (CHV_Utils.listNotEmpty(deletedTalkingPoints)){
        insert deletedTalkingPoints;
    }
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
    for(CHV_Brand__c b : Trigger.old) {
        deletedBrands.add(new CHV_Deleted_Object__c(Name = b.Name, Deleted_Object_Type__c = 'Brand', Deleted_Object_Id__c = b.Id));
    }
    
    if (CHV_Utils.listNotEmpty(deletedBrands)){
        insert deletedBrands;
    }

}