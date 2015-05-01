/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-08
*  Description: This is a trigger for handling Questionnaire validations, field updates and child record updates
*  Test class: GNE_SFA2_Questionnaire_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Questionnaire_Trigger on Questionnaire_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() 
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Questionnaire_Trigger__c')) {
    		
        if(Trigger.isAfter && Trigger.isUpdate){         
        	GNE_SFA2_Questionnaire_Child_Record_Updt.onAfterUpdate(Trigger.old, Trigger.new);
        }
        //GNE_SFA2_Questionnaire_Field_Updates
        //GNE_SFA2_Questionnaire_Validation_Rules
        //GNE_SFA2_Questionnaire_Email_Notif
    }
}