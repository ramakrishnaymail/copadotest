/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-04
*  Description: This is a trigger for handling Time off Territory Day validations, field updates and child record updates
*  Test class: GNE_SFA2_Time_Off_Territory_Day_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Time_Off_Territory_Day_Trigger on Time_off_Territory_Day_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() 
        && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Time_Off_Territory_Day_Trigger__c')) {
        
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            GNE_SFA2_ToT_Day_Field_Updates.onBeforeInsertUpdate(Trigger.new);
        } else if(Trigger.isAfter && Trigger.isInsert){
            GNE_SFA2_ToT_Day_Child_Record_Updates.onAfterInsert(Trigger.new);
            GNE_SFA2_ToT_Day_Email_Notifications.onAfterInsert(Trigger.new);
        } 
        //GNE_SFA2_ToT_Day_Validation_Rules
    }
}