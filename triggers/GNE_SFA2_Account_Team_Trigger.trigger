/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-08
*  Description: This is a trigger for handling Account Team validations, field updates and child record updates
*  Test class: GNE_SFA2_Account_Team_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Account_Team_Trigger on Account_Team_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() 
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Account_Team_Trigger__c')) {
    		
        if(Trigger.isAfter && Trigger.isInsert){         
        	GNE_SFA2_Acct_Team_Child_Record_Updates.onAfterInsert(Trigger.new);
        }else if(Trigger.isAfter && Trigger.isUpdate){
        	GNE_SFA2_Acct_Team_Child_Record_Updates.onAfterUpdate(Trigger.old, Trigger.newMap);
        }else if(Trigger.isAfter && Trigger.isDelete){
        	GNE_SFA2_Acct_Team_Child_Record_Updates.onAfterDelete(Trigger.old);
        }
        //GNE_SFA2_Acct_Team_Field_Updates
        //GNE_SFA2_Acct_Team_Validation_Rules
        //GNE_SFA2_Acct_Team_Email_Notification
    }
}