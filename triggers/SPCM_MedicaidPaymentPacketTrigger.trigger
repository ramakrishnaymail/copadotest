trigger SPCM_MedicaidPaymentPacketTrigger on SPCM_Medicaid_Payment_Packet__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_MedicaidPaymentPacketUtils handler = new SPCM_MedicaidPaymentPacketUtils();
    
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