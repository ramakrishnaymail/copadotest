trigger SPCM_GPPaymentPacketTrigger on SPCM_GP_Payment_Packet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_GPPaymentPacketUtils handler = new SPCM_GPPaymentPacketUtils();
    
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