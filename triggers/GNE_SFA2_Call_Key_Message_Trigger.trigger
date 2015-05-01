/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-09
*  Description: This is a trigger for handling Call Key message validations, field updates and child record updates
*  Test class: GNE_SFA2_Call_Detail_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/
trigger GNE_SFA2_Call_Key_Message_Trigger on Call2_Key_Message_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode()
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Call_Key_Message_Trigger__c')) {
    	Boolean validationFailed = false;
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        	validationFailed = GNE_SFA2_Call_K_M_Validation_Rules.onBeforeInsertUpdate(Trigger.new);
        	if(!validationFailed) {
        		GNE_SFA2_Call_K_M_Field_Updates.onBeforeInsertUpdate(Trigger.new);
        	}
        } else if(Trigger.isBefore && Trigger.isDelete){
        	GNE_SFA2_Call_K_M_Validation_Rules.onBeforeDelete(Trigger.old);   
        } else if(Trigger.isAfter && Trigger.isDelete){
        	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call2_Key_Message_vod__c.getSObjectType());
        }
        
        //GNE_SFA2_Call_K_M_Field_Updates
        //GNE_SFA2_Call_K_M_Child_Record_Updates
        //GNE_SFA2_Call_K_M_Email_Notifications
    }
}