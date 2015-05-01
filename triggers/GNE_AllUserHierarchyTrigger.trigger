trigger GNE_AllUserHierarchyTrigger on All_User_Hierarchy_gne__c (after insert, after update)
{
    
    // after event
    if (Trigger.isAfter)
    {
    
        // insert event
        if (Trigger.isInsert)
        {
            GNE_AllUserHistoryUtils.HandleInsert(Trigger.new);
        }
        
        // update event
        if (Trigger.isUpdate)
        {
            GNE_AllUserHistoryUtils.HandleUpdate(Trigger.old, Trigger.new);
        }
    }
}