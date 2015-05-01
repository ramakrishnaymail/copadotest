trigger GNE_clearOldDataAfterETLUpdate_STGUserAssign on Staging_User_Assignment_gne__c (before update) {

    for(Staging_User_Assignment_gne__c stg_rec : Trigger.new)
    {
        if(stg_rec.Status_gne__c == 'Loaded' && (trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Processed' || trigger.oldMap.get(stg_rec.Id).Status_gne__c == 'Error Processing'))
        {
            stg_rec.Comment_gne__c = '';
            stg_rec.SFDC_User_gne__c= null;
            stg_rec.SFDC_UserTerritory_gne__c='';
        }
    }

}