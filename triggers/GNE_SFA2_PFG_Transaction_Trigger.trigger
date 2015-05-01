trigger GNE_SFA2_PFG_Transaction_Trigger on SFA2_PFG_Transaction_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) 
{
    if(!GNE_SFA2_PFG_TransactionTrigger_Helper.inTansTrig() && 
       !GNE_SFA2_Util.isAdminMode() && 
       !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PFG_Transaction_Trigger') &&
       !GNE_SFA2_Util.isMergeMode()) 
    {
        GNE_SFA2_PFG_TransactionTrigger_Helper.setTransTrig(true);
        
        if(Trigger.isBefore && Trigger.isInsert)
        {
            GNE_SFA2_PFG_Transaction_Field_Update.onBeforeInsert(Trigger.new);  
        } 
        else if(Trigger.isBefore && Trigger.isUpdate)
        {
            GNE_SFA2_PFG_Transaction_Field_Update.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);   
        }
        else if(Trigger.isAfter && Trigger.isInsert)
        {
            GNE_SFA2_PFG_TransactionsLogic.onAfterInsert(Trigger.newMap);
            GNE_SFA2_PFG_TransactionsNotifications.sortAndProcessTransactions(Trigger.new);
        }
        else if(Trigger.isAfter && Trigger.isUpdate)
        {
            GNE_SFA2_PFG_TransactionsLogic.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
        GNE_SFA2_PFG_TransactionTrigger_Helper.setTransTrig(false);
    }
}