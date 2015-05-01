trigger GNE_generateStagBrandToSalesforceExternalId on Staging_Brand_2_Salesforce_gne__c (before insert,before update) {

  Map<String, GNE_Foun_Brand_Map_gne__c> configItemsMap = GNE_Foun_Brand_Map_gne__c.getAll();     
  for(Staging_Brand_2_Salesforce_gne__c stgBrandToSalesforce : Trigger.New) {
    if ((configItemsMap.containsKey(stgBrandToSalesforce.CDM_Brand_Code_gne__c)) && 
        (configItemsMap.get(stgBrandToSalesforce.CDM_Brand_Code_gne__c).SFA_Brand_Name_gne__c.length() > 0) &&
        (configItemsMap.get(stgBrandToSalesforce.CDM_Brand_Code_gne__c).Is_Active_gne__c)) {   
         
            stgBrandToSalesforce.External_Id_gne__c =  stgBrandToSalesforce.Salesforce_Code_gne__c  + '_' +
                                                       stgBrandToSalesforce.Salesforce_SubTeam_Code_gne__c  + '_' +
                                                       stgBrandToSalesforce.CDM_Brand_Code_gne__c;   
                                                                                                                                            
            stgBrandToSalesforce.SFA_Brand_Name_gne__c = configItemsMap.get(stgBrandToSalesforce.CDM_Brand_Code_gne__c).SFA_Brand_Name_gne__c;
    } else
        stgBrandToSalesforce.addError('CDM Brand Code to SFA Brand Name missing or invalid. Please contact SFA support (custom setting: GNE_Foun_Brand_Map_gne__c)');
  }
}