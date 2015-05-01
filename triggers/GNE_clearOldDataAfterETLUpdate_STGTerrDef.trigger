trigger GNE_clearOldDataAfterETLUpdate_STGTerrDef on Staging_Territory_Def_gne__c (before update) {

    for(Staging_Territory_Def_gne__c stg_rec : Trigger.new)
    {
         if(stg_rec.Status_gne__c == 'Loaded' && (trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Processed' || trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Error Processing'))
        {
            stg_rec.Comment_gne__c = '';
            stg_rec.Territory_ID_gne__c = '';
        }
    }

}