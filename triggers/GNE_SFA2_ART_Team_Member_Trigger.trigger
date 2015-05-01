/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-09-17
*  Description: This is a helper  for handling ART Team validations, field updates and child record updates
*  Test class: GNE_SFA2_ART_Team_Member_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_ART_Team_Member_Trigger on ART_Team_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
     if (!GNE_SFA2_Util.isAdminMode() 
     		&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_ART_Team_Member_Trigger__c')) {
     			
        if(Trigger.isAfter && Trigger.isInsert){
            GNE_SFA2_ART_Team_Child_Record_Updates.onAfterInsert(Trigger.new);
        } else if(Trigger.isAfter && Trigger.isDelete){
            GNE_SFA2_ART_Team_Child_Record_Updates.onAfterDelete(Trigger.old);
        }
        //GNE_SFA2_ART_Team_Validation_Rules
        //GNE_SFA2_ART_Team_Field_Updates
        //GNE_SFA2_ART_Team_Email_Notifications
    }
}