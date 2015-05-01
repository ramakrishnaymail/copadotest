trigger SPCM_MCCApprovalSheetTrigger on SPCM_MCC_Approval_Sheet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_MCCApprovalSheetUtils handler = new SPCM_MCCApprovalSheetUtils();
    
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