/************************************************************
*  @author: Sreedhar Karukonda
*  Date: 1/3/2013 
*  Description: This Trigger GNE_SFA2_Survey_Trigger Consolidates all triggers on Survey_gne__c object
*  
*  Modification History
*  Date        Name        Description
*            
*************************************************************/ 
trigger GNE_SFA2_Survey_Trigger on Survey_gne__c (after delete, after insert, after undelete, 
													after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode())   
    {
        if(Trigger.isInsert && Trigger.isBefore){  
        	GNE_SFA2_Survey_Field_Update.OnBeforeInsert(null, Trigger.new);
        }
        else if(Trigger.isInsert && Trigger.isAfter){
        }
        else if(Trigger.isUpdate && Trigger.isBefore){  
        	GNE_SFA2_Survey_Adv_Future.OnBeforeUpdate(Trigger.old, Trigger.new);
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
        }
        else if(Trigger.isDelete && Trigger.isBefore){  
        }
        else if(Trigger.isDelete && Trigger.isAfter){
        	GNE_SFA2_Survey_Adv_Future.OnAfterDelete(Trigger.old, null);
        }
        else if(Trigger.isUnDelete){
        }
    }

}