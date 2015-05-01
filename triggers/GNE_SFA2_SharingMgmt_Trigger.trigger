/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-07-12
*  Description: This is a trigger used for managing AccountShare and CaseShare objects besed on Sharing Management object changes
*  Test class: GNE_SFA2_SharingMgmt_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/

trigger GNE_SFA2_SharingMgmt_Trigger on Sharing_Mgmt_gne__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_SharingMgmt_Trigger__c')) 
    {
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){         
            GNE_SFA2_SharingMgmt_Validation_Rules.onBeforeInsertUpdate (Trigger.old, Trigger.new);
            GNE_SFA2_SharingMgmt_Field_Updates.onBeforeInsertUpdate(Trigger.old, Trigger.new);
            GNE_SFA2_SharingMgmt_Child_Record_Update.onAfterInsertUpdate(Trigger.new);  
        }
        /*else if(Trigger.isBefore && Trigger.isDelete){
            // no action
        }
        else if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
            // no action
        }
        else if(Trigger.isAfter && Trigger.isDelete){
            // no Action
        }
        else if(Trigger.isUnDelete){
            // no action
        }*/
    }
}