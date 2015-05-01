/************************************************************
*  @author: Sreedhar Karukonda
*  Date: 1/6/2013
*  Description: This Trigger GNE_SFA2_Targets_and_Tiers_Trigger Consolidates all triggers on Targets_and_Tiers_can_gne__c object
*  
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/

trigger GNE_SFA2_Targets_and_Tiers_Trigger on Targets_and_Tiers_can_gne__c (after delete, after insert, after undelete, after update, 
																				before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode()) {
        if(Trigger.isInsert && Trigger.isBefore){
       		GNE_SFA2_TargetsTiers_Field_Update.onBeforeInsert(Trigger.new);
        }
        else if(Trigger.isInsert && Trigger.isAfter){
        }
        else if(Trigger.isUpdate && Trigger.isBefore){
       		GNE_SFA2_TargetsTiers_Field_Update.onBeforeUpdate(Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
        	GNE_SFA2_TargetsTiers_ChildRecord_Update.OnAfterUpdate(Trigger.oldMap, Trigger.new);
        }
        else if(Trigger.isDelete && Trigger.isBefore){  
        }
        else if(Trigger.isDelete && Trigger.isAfter){
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Targets_and_Tiers_can_gne__c.getSObjectType());
        }
        else if(Trigger.isUnDelete){
            
        }
    }

}