trigger GNE_SFA2_Configuration_Detail_Trigger on SFA2_Configuration_Object_Detail_gne__c (before insert,before update) {

    Map<String,Id>  confObjectMap = new   Map<String,Id>();
    Set<String> ExternalIdDetail = new Set<String>();

    for(SFA2_Configuration_Object_Detail_gne__c confDetail : Trigger.New){

        if(confDetail.Load_External_Id__c==null){
            return;//confDetail.Load_External_Id__c.addError('External Id is required');
        }
        
        ExternalIdDetail.add(confDetail.Load_External_Id__c);
    }

    if(ExternalIdDetail!=null && ExternalIdDetail.size()>0){
        List<SFA2_Configuration_Object_gne__c> confObjects = [select Id,External_ID_gne__c from SFA2_Configuration_Object_gne__c where External_ID_gne__c in : ExternalIdDetail];
        
        for(SFA2_Configuration_Object_gne__c confObj : confObjects) {
            confObjectMap.put(confObj.External_ID_gne__c,confObj.Id);
        }
    }
    
    if(confObjectMap!=null && confObjectMap.keyset().size()>0){
        
        for(SFA2_Configuration_Object_Detail_gne__c confDetail : Trigger.New){
            
            confDetail.Configuration_Object_ref_gne__c=confObjectMap.get(confDetail.Load_External_Id__c);
        }
    }
    
}