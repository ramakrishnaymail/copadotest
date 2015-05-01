trigger GNE_CM_RS_Queue_Config_Trigger on GNE_CM_RS_Queue_Config__c (before insert, before update) {
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isTriggerDisabled('GNE_CM_RS_Queue_Config__c') || GNE_SFA2_Util.isAdminMode('GNE_CM_RS_Queue_Config__c'))
    {
        System.debug('Skipping trigger GNE_CM_RS_Queue_Config__c');
        return;
    }
    
    if (trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            GNE_CM_RS_Queue_Config_Helper.searchForDuplicates(trigger.new, null);
        }
        if(trigger.isUpdate)
        {
        	 GNE_CM_RS_Queue_Config_Helper.searchForDuplicates(trigger.new, trigger.oldMap);
        }
    }
}