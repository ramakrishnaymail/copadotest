trigger GNE_UserBusinessRoleTrigger on User_Business_Role_gne__c (before insert, before delete, after insert, after delete)
{
    
    // before event
    if (Trigger.isBefore)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            GNE_UserBusinessRoleUtils.HandleBeforeInsert(Trigger.new);
        }
        
        // delete
        if (Trigger.isDelete)
        {
            GNE_UserBusinessRoleUtils.HandleBeforeDelete(Trigger.old);
        }
    }
    
    // after event
    if (Trigger.isAfter)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            GNE_UserBusinessRoleUtils.HandleAfterInsert(Trigger.new);
        }
        
        // delete
        if (Trigger.isDelete)
        {
            GNE_UserBusinessRoleUtils.HandleAfterDelete(Trigger.old);
        }
    }
}