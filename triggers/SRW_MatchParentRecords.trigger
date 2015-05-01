trigger SRW_MatchParentRecords on SRW_Trd_Prt_Product_gne__c (before insert) {
    
    map<String,Id> externalTOIdTPP = new map<String,Id>();
    map<String,Id> externalTOIdProd = new map<String,Id>();

    for(SRW_Trading_Partner_Profile__c temp : [Select Id,Matching_Id_gne__c from SRW_Trading_Partner_Profile__c]){

        externalTOIdTPP.put(temp.Matching_Id_gne__c,temp.Id);
    }
    
    for(Product_vod__c temp : [Select Id,Matching_Id_gne__c From Product_vod__c where Product_Type_vod__c = 'SRW']){

        externalTOIdProd.put(temp.Matching_Id_gne__c,temp.Id);
    }
    
    for (SRW_Trd_Prt_Product_gne__c tpProd : Trigger.new) {
        
        List<String> externalIDs = tpProd.Match_Name_gne__c.split('#');

        
        tpProd.Trading_Partner_gne__c = externalTOIdTPP.get(externalIDs[0]);
        tpProd.Product_gne__c = externalTOIdProd.get(externalIDs[1]);
        
    }
}