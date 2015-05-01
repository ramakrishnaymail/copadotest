trigger SPCM_MCCTrackingSheetTrigger on SPCM_MCC_Tracking_Sheet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_MCCTrackingSheetUtils handler = new SPCM_MCCTrackingSheetUtils();
    
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