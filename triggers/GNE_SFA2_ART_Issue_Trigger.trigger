/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-09-17
*  Description: This is a trigger for handling ART Issue validations, field updates and child record updates
*  Test class: GNE_SFA2_ART_Issue_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_ART_Issue_Trigger on ART_Issue_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    private boolean validationFailed = false;
    if (!GNE_SFA2_Util.isAdminMode() 
    		&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_ART_Issue_Trigger__c')) {
    			
        if(Trigger.isBefore && Trigger.isInsert){
            validationFailed = GNE_SFA2_ART_Issue_Validation_Rules.onBeforeInsert(Trigger.new);
            if(!validationFailed) {
                GNE_SFA2_ART_Issue_Field_Updates.onBeforeInsert(Trigger.new);
            }
        } else if (Trigger.isBefore && Trigger.isUpdate) {
        	validationFailed = GNE_SFA2_ART_Issue_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
            if(!validationFailed) {
            	GNE_SFA2_ART_Issue_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
            }
        }
        //GNE_SFA2_ART_Issue_Child_Record_Updates
        //GNE_SFA2_ART_Issue_Email_Notifications
    }
}