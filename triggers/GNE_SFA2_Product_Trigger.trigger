/************************************************************
*  @author: Michal Hrycenko, Roche
*  Date: 2012-09-21
*  Description: This is a trigger for handling Product Catalog
*  Test class: GNE_SFA2_Product_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Product_Trigger on Product_vod__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Product_Trigger__c')){
        if(Trigger.isBefore && Trigger.isInsert) {
            GNE_SFA2_Product_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) {
            GNE_SFA2_Product_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isBefore && Trigger.isDelete) {
            GNE_SFA2_Product_Validation_Rules.onBeforeDelete(Trigger.old);
        }       
            //GNE_SFA2_Product_Child_Record_Updates
            //GNE_SFA2_MedComm_Email_Notifications
    }
}