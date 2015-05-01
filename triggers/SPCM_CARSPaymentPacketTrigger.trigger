trigger SPCM_CARSPaymentPacketTrigger on SPCM_CARS_Payment_Packet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_CARSPaymentPacketUtils handler = new SPCM_CARSPaymentPacketUtils();
    
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