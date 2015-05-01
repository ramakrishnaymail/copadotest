trigger GNE_BusinessRoleTrigger on GNE_Business_Role__c (before insert, before update)
{
    
    // before event
    if (Trigger.isBefore)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            
            // set unique key
            for (GNE_Business_Role__c record : Trigger.new)
            {
                record.Unique_Key__c = record.Name;
            }
        }
        
        // update
        if (Trigger.isUpdate)
        {
        
            // set unique key
            for (GNE_Business_Role__c record : Trigger.new)
            {
                record.Unique_Key__c = record.Name;
            }
        }
    }
}