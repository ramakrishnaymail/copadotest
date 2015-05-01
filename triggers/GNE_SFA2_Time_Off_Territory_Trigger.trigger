/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-04
*  Description: This is a trigger for handling Time off Territory validations, field updates and child record updates
*  Test class: GNE_SFA2_Time_Off_Territory_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Time_Off_Territory_Trigger on Time_Off_Territory_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() 
        && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Time_Off_Territory_Trigger__c')) {
        
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            GNE_SFA2_ToT_Field_Updates.onAfterInsertUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isInsert){
            GNE_SFA2_ToT_Child_Record_Updates.onAfterInsert(Trigger.new);
        } 
        //GNE_SFA2_ToT_Validation_Rules
        //GNE_SFA2_ToT_Email_Notifications
    }
}