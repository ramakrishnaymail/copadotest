/************************************************************
*  @author: 
*  Date: 
*  Description: This is a trigger for handling Call2_Sample_vod__c
*  Test class: GNE_SFA2_Call_Sample_trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation. Also added this comment section.        
*************************************************************/
trigger GNE_SFA2_Call_Sample_trigger on Call2_Sample_vod__c (after delete, after insert, 
															 after undelete, after update, 
															 before delete, before insert, before update) 
{
	if (!GNE_SFA2_Util.isAdminMode())   
    {
    	if(Trigger.isInsert && Trigger.isBefore){  
            GNE_SFA2_Call_Sample_Validation_Rules.OnBeforeInsert(null, Trigger.new);
            GNE_SFA2_Call_Sample_Child_Record_Update.OnBeforeInsert(null, Trigger.new);
        }
        else if(Trigger.isInsert && Trigger.isAfter){
            GNE_SFA2_Call_Sample_Validation_Rules.OnBeforeInsert(null, Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isBefore){ 
        	GNE_SFA2_Call_Sample_Child_Record_Update.OnBeforeUpdate(null, Trigger.new); 
            
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
        }
        else if(Trigger.isDelete && Trigger.isBefore){ 
        	GNE_SFA2_Call_Sample_Child_Record_Update.OnBeforeDelete(Trigger.oldMap, null); 
        }
        else if(Trigger.isDelete && Trigger.isAfter){
        	GNE_SFA2_Call_Sample_Child_Record_Update.OnAfterDelete(Trigger.oldMap, null);
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call2_Sample_vod__c.getSObjectType());            
        }
        else if(Trigger.isUnDelete){
            
        }
    	
    }
}