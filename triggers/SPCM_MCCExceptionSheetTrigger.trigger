trigger SPCM_MCCExceptionSheetTrigger on SPCM_MCC_Exception_Sheet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_MCCExceptionSheetUtils handler = new SPCM_MCCExceptionSheetUtils();
    
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