/************************************************************
*  @author: Sreedhar Karukonda
*  Date: 1/6/2013 
*  Description: This Trigger GNE_SFA2_Key_Message_Trigger Consolidates all triggers on Key_Message_vod__c object
*  
*  Modification History
*  Date        Name        Description
*            
*************************************************************/ 


trigger GNE_SFA2_Key_Message_Trigger on Key_Message_vod__c (after delete, after insert, after undelete, 
															after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode())   
    {
        if(Trigger.isInsert && Trigger.isBefore){  
        }
        else if(Trigger.isInsert && Trigger.isAfter){
        }
        else if(Trigger.isUpdate && Trigger.isBefore){  
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
        }
        else if(Trigger.isDelete && Trigger.isBefore){
        	GNE_SFA2_Key_Message_Field_Update.OnBeforeDelete(Trigger.oldMap, null);
        }
        else if(Trigger.isDelete && Trigger.isAfter){
        }
        else if(Trigger.isUnDelete){
            
        }
    }
}