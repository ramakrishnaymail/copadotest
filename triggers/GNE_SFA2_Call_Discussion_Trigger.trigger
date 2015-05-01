/************************************************************
*  @author: Sreedhar Karukonda
*  Date: 12/31/2012
*  Description: This Trigger GNE_SFA2_Call_Discussion_Trigger Consolidates all triggers on Call2_Discussion_vod__c object
*  
*  Modification History
*  Date        Name        Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/

trigger GNE_SFA2_Call_Discussion_Trigger on Call2_Discussion_vod__c (after delete, after insert, after undelete, 
                                                                        after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode())   
    {
        if(Trigger.isInsert && Trigger.isBefore){ 
            GNE_SFA2_CallDiscussion_Validation_Rules.OnBeforeInsert(Trigger.new);
            GNE_SFA2_Call_Discussion_Field_Updates.OnBeforeInsert(null, Trigger.new);
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            GNE_SFA2_Call_Discussion_Field_Updates.OnAfterInsert(null, Trigger.new);
            GNE_SFA2_CallDiscussion_ChildRcrd_Update.OnAfterInsert(Trigger.oldMap, Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){  
            GNE_SFA2_CallDiscussion_Validation_Rules.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
            GNE_SFA2_Call_Discussion_Field_Updates.OnBeforeUpdate (Trigger.oldMap, Trigger.new);
            
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            GNE_SFA2_Call_Discussion_Field_Updates.OnAfterUpdate(Trigger.oldMap, Trigger.new);
            GNE_SFA2_CallDiscussion_ChildRcrd_Update.OnAfterUpdate(Trigger.oldMap, Trigger.new);
        }
        else if(Trigger.isDelete && Trigger.isBefore){
        	GNE_SFA2_Deleted_Records_Util.onBeforeDelete(Trigger.old, Call2_Discussion_vod__c.getSObjectType());
            GNE_SFA2_Call_Discussion_Field_Updates.OnBeforeDelete(Trigger.oldMap, null);
        }
        else if(Trigger.isDelete && Trigger.isAfter){
        	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call2_Discussion_vod__c.getSObjectType());            
            GNE_SFA2_CallDiscussion_ChildRcrd_Update.OnAfterDelete(Trigger.oldMap, Trigger.new);
        }
        else if(Trigger.isUnDelete){
            
        }
    }

}