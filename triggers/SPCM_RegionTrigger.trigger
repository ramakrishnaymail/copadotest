trigger SPCM_RegionTrigger on SPCM_Region__c (before insert, before update)
{

    // before event
    if (Trigger.isBefore)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            SPCM_RegionUtils.HandleBeforeInsert(Trigger.new);
        }
        
        // update
        if (Trigger.isUpdate)
        {
            SPCM_RegionUtils.HandleBeforeUpdate(Trigger.new);
        }
    }
}