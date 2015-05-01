/************************************************************
*  @author: Michal Hrycenko, Roche
*  Date: 2012-09-19
*  Description: This is a trigger for handling TSF
*  Test class: GNE_SFA2_TSF_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
* 2014-12-03 : Mateusz Michalczyk : Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*            
*************************************************************/
trigger GNE_SFA2_TSF_Trigger on TSF_vod__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_TSF_Trigger__c') && !GNE_SFA2_TSF_Trigger_Helper.inTSFTrig()){
    	GNE_SFA2_TSF_Trigger_Helper.setTSFTrig(true);
    	
        if(Trigger.isBefore && Trigger.isInsert){
            if(!GNE_SFA2_Util.isMergeMode()){
                GNE_SFA2_TSF_Field_Updates.onBeforeInsert(Trigger.new);
            }
        } else if(Trigger.isBefore && Trigger.isUpdate) {
            if(!GNE_SFA2_Util.isMergeMode()){
                GNE_SFA2_TSF_Field_Updates.onBeforeUpdate(Trigger.new);
            }
        }  else if(Trigger.isAfter && Trigger.isInsert){
        	if(!GNE_SFA2_Util.isMergeMode()){
        		GNE_SFA2_TSF_Child_Record_Updates.onAfterInsert(Trigger.new);
        	}
        }  else if (Trigger.isAfter && Trigger.isDelete ){
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, TSF_vod__c.getSObjectType());            
        }
            //GNE_SFA2_TSF_Validation_Rules
            //GNE_SFA2_TSF_Child_Record_Updates
            //GNE_SFA2_TSF_Email_Notifications
            
        GNE_SFA2_TSF_Trigger_Helper.setTSFTrig(false);
    }
}