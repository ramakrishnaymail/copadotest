trigger SPCM_CARSContractSummaryFormTrigger on SPCM_CARS_Contract_Summary_Form__c (before insert, before update, before delete)
{
    
    // create utility class
    SPCM_CARSContractSummaryFormUtils handler = new SPCM_CARSContractSummaryFormUtils();
    
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