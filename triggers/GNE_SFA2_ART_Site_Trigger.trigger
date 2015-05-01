/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-09-17
*  Description: This is a trigger for handling ART Site validations, field updates and child record updates
*  Test class: GNE_SFA2_ART_Site_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_ART_Site_Trigger on ART_Site_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() 
    		&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_ART_Site_Trigger__c')) {
        
        if(Trigger.isAfter && Trigger.isUpdate){
            GNE_SFA2_ART_Site_Child_Record_Updates.onAfterUpdate(Trigger.old, Trigger.new);
        }
        //GNE_SFA2_ART_Site_Validation_Rules
        //GNE_SFA2_ART_Site_Child_Record_Updates
        //GNE_SFA2_ART_Site_Email_Notifications
    }
}