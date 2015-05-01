trigger GNE_clearOldDataAfterETLUpdate_STGZip2Terr on Staging_Zip_2_Terr_gne__c (before update) {

  for(Staging_Zip_2_Terr_gne__c stg_rec : Trigger.new)
    {
        if(stg_rec.Status_gne__c == 'Loaded' && (trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Processed' || trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Error Processing'))
        { 
            stg_rec.Comment_gne__c = '';
            stg_rec.Zip_to_Territory_gne__c= null;
        }
    }

}