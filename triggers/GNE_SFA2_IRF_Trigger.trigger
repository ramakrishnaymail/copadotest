/************************************************************
*  @author: Michal Hrycenko, Roche
*  Date: 2012-09-12
*  Description: This is a trigger for handling IRF
*  Test class: GNE_SFA2_IRF_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_IRF_Trigger on Issue_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_IRF_Trigger__c')){
        if(Trigger.isBefore && Trigger.isInsert){
            GNE_SFA2_IRF_Field_Updates.onBeforeInsert(Trigger.new);
        }else if(Trigger.isBefore && Trigger.isUpdate){
            GNE_SFA2_IRF_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        }
            //GNE_SFA2_IRF_Validation_Rules
            //GNE_SFA2_IRF_Child_Record_Updates
            //GNE_SFA2_IRF_Email_Notifications
    }
}