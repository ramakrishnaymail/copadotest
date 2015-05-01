/*************************************************************
*  Description: This is a trigger for handling My_Setup_Products_vod__c validations, field updates and child record updates
*  Test class: GNE_My_Setup_Products_Trigger_Test
*************************************************************/
trigger My_Setup_Products_Trigger on My_Setup_Products_vod__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(Trigger.isBefore && Trigger.isUpdate){
        GNE_My_Setup_Products_External_Id_Fill.onBeforeUpdate(Trigger.old, Trigger.new);
    } else if(Trigger.isAfter && Trigger.isUpdate){
        GNE_SFA2_MySetup_ChildRecord_Update.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    } else if(Trigger.isBefore && Trigger.isInsert){
        GNE_My_Setup_Products_External_Id_Fill.onBeforeInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isInsert){
        GNE_SFA2_MySetup_ChildRecord_Update.OnAfterInsert(Trigger.new);
    }
}