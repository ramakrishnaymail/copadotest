/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-09
*  Description: This is a trigger for handling Call Detail validations, field updates and child record updates
*  Test class: GNE_SFA2_Call_Detail_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation. Added before delete cacheWithParentCall.
*************************************************************/
trigger GNE_SFA2_Call_Detail_Trigger on Call2_Detail_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Call_Detail_Trigger__c')) {    	
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        	GNE_SFA2_Call_Detail_Validation_Rules.onBeforeInsertUpdate(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isDelete){        	
        	GNE_SFA2_Deleted_Records_Util.onBeforeDelete(Trigger.old, Call2_Detail_vod__c.getSObjectType());        	
           	GNE_SFA2_Call_Detail_Validation_Rules.onBeforeDelete(Trigger.old);           	   
        } else if(Trigger.isAfter && Trigger.isDelete){
        	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call2_Detail_vod__c.getSObjectType());            
        }
        
        //GNE_SFA2_Call_Detail_Field_Updates
        //GNE_SFA2_Call_Detail_Child_Record_Updates
        //GNE_SFA2_Call_Detail_Email_Notifications
        //GNE_SFA2_Call_Detail_Trigger_Helper
    }
}