trigger GNE_BusinessRolePermSetTrigger on GNE_Business_Role_Permission_Set__c (before insert, after insert, 
    after update, before delete)
{

    // before event
    if (Trigger.isBefore)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            for (GNE_Business_Role_Permission_Set__c record : Trigger.new)
            {
                record.Unique_Key__c = record.Business_Role__c + record.Permission_Set_Id__c;
            } 
        }
    
        // delete
        /*if (Trigger.isDelete)
        {
            for (GNE_Business_Role_Permission_Set__c record : Trigger.old)
            {
                record.addError('Record cannot be deleted, inactivate instead.');
            }
        }*/
    }
    
    // after event
    if (Trigger.isAfter)
    {
    
        // insert
        if (Trigger.isInsert)
        {
        
            // get only active inserted records and store in list
            Set<Id> activeIds = new Set<Id>();
            for (GNE_Business_Role_Permission_Set__c record : Trigger.new)
            {
                if (record.Is_Active__c)
                {
                    activeIds.add(record.Id);
                }
            }
            
            // call @future method handler
            if (activeIds.size() > 0)
            {
                GNE_BusinessRolePermSetUtils.HandleActivations(activeIds);
            }
        }
        
        // update
        if (Trigger.isUpdate)
        {
        
            // get only records where active has changed and store in lists
            Set<Id> activeIds = new Set<Id>();
            Set<Id> inactiveIds = new Set<Id>();
            for (integer i = 0; i < Trigger.old.size(); i++)
            {
                if (Trigger.new[i].Is_Active__c != Trigger.old[i].Is_Active__c)
                {
                    if (Trigger.new[i].Is_Active__c)
                    {
                        activeIds.add(Trigger.new[i].Id);
                    }
                    else
                    {
                        inactiveIds.add(Trigger.new[i].Id);
                    }
                }
            }
            
            // call @future method handlers
            if (activeIds.size() > 0)
            {
                GNE_BusinessRolePermSetUtils.HandleActivations(activeIds);
            }
            if (inactiveIds.size() > 0)
            {
                GNE_BusinessRolePermSetUtils.HandleInactivations(inactiveIds);
            }
        }
    }
}