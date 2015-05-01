/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-05
*  Description: This is a trigger for handling Product Tactic validations, field updates and child record updates
*  Test class: GNE_SFA2_Product_Tactic_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Product_Tactic_Trigger on Product_Tactic_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() 
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Product_Tactic_Trigger__c')) {
    		
        if(Trigger.isBefore && Trigger.isDelete){    
           GNE_SFA2_Prod_Tactic_Validation_Rules.onBeforeDelete(Trigger.old);
        }
        //GNE_SFA2_Prod_Tactic_Field_Updates
        //GNE_SFA2_Prod_Tactic_Child_Record_Updates
        //GNE_SFA2_Prod_Tactic_Email_Notification
    }
}