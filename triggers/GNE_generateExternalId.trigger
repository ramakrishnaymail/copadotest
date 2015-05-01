trigger GNE_generateExternalId on Staging_Zip_2_Terr_gne__c (before insert,before update) {
  
  for(Staging_Zip_2_Terr_gne__c stg_zip_terr : Trigger.New)
  {
     stg_zip_terr.External_Id_gne__c = stg_zip_terr.Brand_Name_gne__c  + '-' +
                                       stg_zip_terr.Zip_Code_gne__c  + '-' +
                                       stg_zip_terr.Territory_Key_gne__c + '-' +
                                       stg_zip_terr.Activaction_Date_gne__c.format();
  }
}