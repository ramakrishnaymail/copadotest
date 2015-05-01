/************************************************************
*  @author: Sreedhar Karukonda
*  Date: 12/10/2012 
*  Description: This Trigger GNE_SFA2_Interaction_Trigger Consolidates all triggers on Call2_vod__c object
*  
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*            
*************************************************************/

trigger GNE_SFA2_Interaction_Trigger on Call2_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) 
{
    if (!GNE_SFA2_Util.isAdminMode())   
    {
        if(Trigger.isInsert && Trigger.isBefore){  
            GNE_SFA2_Interaction_Validation_Rules.onBeforeInsert(null, Trigger.new); 
            GNE_SFA2_Interaction_Field_Updates.OnBeforeInsert(null, Trigger.new);
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            GNE_SFA2_Interaction_Child_Record_Update.OnAfterInsert(Trigger.oldMap, Trigger.newMap);//
            //GNE_SFA2_Interaction_Adv_Future.createUpdateTSFFuture(Trigger.newMap.keyset()); 
            GNE_SFA2_Interaction_Adv_Future.OnAfterInsert(null, Trigger.newMap);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){  
            GNE_SFA2_Interaction_Validation_Rules.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);  
            GNE_SFA2_Interaction_Field_Updates.OnBeforeUpdate(Trigger.oldMap, Trigger.new);
            GNE_SFA2_Interaction_Child_Record_Update.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
            GNE_SFA2_Interaction_Adv_Future.OnBeforeUpdate (Trigger.oldMap, Trigger.newMap);
            
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            GNE_SFA2_Interaction_Child_Record_Update.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);//
            //GNE_SFA2_Interaction_Adv_Future.createUpdateTSFFuture(Trigger.newMap.keyset()); 
            GNE_SFA2_Interaction_Adv_Future.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(Trigger.isDelete && Trigger.isBefore){  
            GNE_SFA2_Interaction_Validation_Rules.onBeforeDelete(Trigger.oldMap, Trigger.newMap); 
            GNE_SFA2_Interaction_Child_Record_Update.OnBeforeDelete(Trigger.oldMap, Trigger.newMap); //
            GNE_SFA2_Interaction_Adv_Future.OnBeforeDelete(Trigger.oldMap, null);//------
        }
        else if(Trigger.isDelete && Trigger.isAfter){
        	GNE_SFA2_Interaction_Child_Record_Update.OnAfterDelete(Trigger.oldMap);//
        	GNE_SFA2_Interaction_Adv_Future.OnAfterDelete(Trigger.oldMap);
        	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call2_vod__c.getSObjectType());
        }
        else if(Trigger.isUnDelete){
            
        }
    }

}