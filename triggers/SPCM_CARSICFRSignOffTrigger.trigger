trigger SPCM_CARSICFRSignOffTrigger on SPCM_CARS_ICFR_Sign_Off__c (before insert, before update, before delete)
{

    // create utility class
    SPCM_CARSICFRSignOffUtils handler = new SPCM_CARSICFRSignOffUtils();
        
    // before event
    if (Trigger.isBefore)
    {
    
        // insert event
        if (Trigger.isInsert)
        {
            handler.HandleBeforeInsert(Trigger.new);
        }
        
        // update event
        if (Trigger.isUpdate)
        {
            handler.HandleBeforeUpdate(Trigger.old, Trigger.new);
        }
        
        // delete event
        if (Trigger.isDelete)
        {
            handler.HandleBeforeDelete(Trigger.old);
        }
    }
}