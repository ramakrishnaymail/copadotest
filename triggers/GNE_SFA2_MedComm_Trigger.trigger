/************************************************************
*  @author: Michal  Hrycenko, Roche
*  Date: 2012-08-13
*  Description: This is a trigger for handling MedComm validations and field updates
*  Test class: GNE_SFA2_MedComm_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/
trigger GNE_SFA2_MedComm_Trigger on Medical_Communication_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_MedComm_Trigger__c')){
        if(Trigger.isBefore && Trigger.isInsert){
            GNE_SFA2_MedComm_Field_Updates.onBeforeInsert(Trigger.new);
        }else if(Trigger.isBefore && Trigger.isUpdate){
            GNE_SFA2_MedComm_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
            GNE_SFA2_MedComm_Field_Updates.onBeforeUpdate(Trigger.new);
        }else if(Trigger.isBefore && Trigger.isDelete){
            GNE_SFA2_MedComm_Validation_Rules.onBeforeDelete(Trigger.old);
        } else if (Trigger.isAfter && Trigger.isDelete){
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Medical_Communication_gne__c.getSObjectType());
        }
            //GNE_SFA2_MedComm_Child_Record_Updates
            //GNE_SFA2_MedComm_Email_Notifications
    }
}