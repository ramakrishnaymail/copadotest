/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-09-12
*  Description: This is a trigger used for for handling Brand Affiliation validations, field updates and child record updates
*  Test class: GNE_SFA2_Brand_Affiliation_Trigger_Test
*  
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Brand_Affiliation_Trigger on Product_Metrics_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() 
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Brand_Affiliation_Trigger__c')) {
    		
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){         
           GNE_SFA2_Brand_Affil_Field_Updates.onBeforeInsertUpdate(Trigger.new);
        }
        //GNE_SFA2_Brand_Affiliation_Email_Notifications
    }
}