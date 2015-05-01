/*************************************************************
*  Description: This is a trigger for handling GNE_SFA2_Layout_Configuration validations, field updates and child record updates
*  Test class: GNE_SFA2_Layout_Config_Trigger_Test
*************************************************************/
trigger SFA2_Configuration_Trigger on SFA2_Configuration_Object_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('SFA2_Configuration_Trigger__c')) {
        
            if(Trigger.isBefore && Trigger.isUpdate){
                GNE_SFA2_Layout_Config_External_Id_Fill.onBeforeUpdate(Trigger.old, Trigger.new);
            }
            if(Trigger.isBefore && Trigger.isInsert){
                GNE_SFA2_Layout_Config_External_Id_Fill.onBeforeInsert(Trigger.new);
            }
    }
}