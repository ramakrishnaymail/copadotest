trigger GNE_CM_Service_View_Processing on Task (after insert, after update)
{
    if (GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_Service_View_Processing'))
    {
        return;
    }   
    GNE_CM_Service_View_Utils.updateTasksForServiceViewProcessing(trigger.new);
    
    if (trigger.isInsert)
    {
        List<Task> tasks = new List<Task>();
        for (Task t : trigger.new)
        {
            if (t.subject!= null && t.subject != '' && t.Subject.toLowerCase() == 'coordinate starter shipment')
            {
                tasks.add(new Task(
                    Subject = 'Starter Service Update: Eligibility Established: Approved',
                    ActivityDate = system.today(),
                    Process_Category_gne__c = 'Managing a Case',
                    Status = 'Completed',
                    WhatId = t.WhatId,
                    OwnerId = t.OwnerId
                ));
            }
        }        
        if (tasks != null && tasks.size() > 0)
        {
            insert tasks;
        }
    }
}