trigger GNE_CM_Insurance_Post_Processing on Insurance_gne__c (after insert, after update) 
{
    Set<String> caseIds=new Set<String>();

    for (Insurance_gne__c ins : Trigger.new)
    {
        if (Trigger.isInsert && ins.Case_Insurance_gne__c!=null && ins.Payer_gne__c!=null)
        {
            caseIds.add(ins.Case_Insurance_gne__c);                 
        }
        
        if (Trigger.isUpdate)
        {
            Insurance_gne__c insOld = Trigger.oldMap.get(ins.Id);

            if (ins.Case_Insurance_gne__c!=insOld.Case_Insurance_gne__c || ins.Payer_gne__c!=insOld.Payer_gne__c || ins.Rank_gne__c!=insOld.Rank_gne__c  || ins.ins_Insurance_gne__c!=insOld.ins_Insurance_gne__c)
            {
                if (ins.Case_Insurance_gne__c!=null)
                {
                    caseIds.add(ins.Case_Insurance_gne__c);                  
                }

                if (insOld.Case_Insurance_gne__c!=null)
                {
                    caseIds.add(insOld.Case_Insurance_gne__c);                  
                }
            }
        }
    }

    if (!caseIds.isEmpty())
    {
    	GNE_CM_Static_Flags.setFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
    	try 
        {
        	GNE_CM_Task_Queue_Mgmt_Helper.flagTasksWithChangedInsurance(caseIds);
        } 
        finally 
        {
        	GNE_CM_Static_Flags.unsetFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
        }
    }
}