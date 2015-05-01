/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2013-02-04
*  Description: This is a trigger for handling SFA2 UI Setting validations, field updates and child record updates
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_UI_Setting_Trigger on SFA2_UI_Setting_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode()
        && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_UI_Setting_Trigger__c')) {
        if(Trigger.isBefore && Trigger.isInsert){         
           //GNE_SFA2_UI_Setting_Validation_Rules.onBeforeInsert(Trigger.new);
           GNE_SFA2_UI_Setting_Field_Updates.onBeforeInsertUpdate(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
           //GNE_SFA2_UI_Setting_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
           GNE_SFA2_UI_Setting_Field_Updates.onBeforeInsertUpdate(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isDelete){
           //GNE_SFA2_UI_Setting_Validation_Rules.onBeforeDelete(Trigger.old);
           //GNE_SFA2_UI_Setting_Field_Updates.onBeforeInsertUpdate(Trigger.old);
        } else if(Trigger.isAfter && Trigger.isInsert){
           //GNE_SFA2_UI_Setting_Child_Record_Update.onAfterInsert(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isUpdate){
           //GNE_SFA2_UI_Setting_Child_Record_Update.onAfterUpdate(Trigger.old, Trigger.new);
        } 
        //GNE_SFA2_View_Config_Notifications
    }
}