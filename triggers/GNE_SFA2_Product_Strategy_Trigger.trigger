/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-10-01
*  Description: This is a trigger for handling Product Strategy validations, field updates and child record updates
*  Test class: GNE_SFA2_Product_Strategy_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_Product_Strategy_Trigger on Product_Strategy_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() 
    	&& !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Product_Strategy_Trigger__c')) {
    		
        if(Trigger.isBefore && Trigger.isDelete){         
           GNE_SFA2_Prod_Strategy_Validation_Rules.onBeforeDelete(Trigger.old);
        }
        //GNE_SFA2_Prod_Strategy_Field_Updates
        //GNE_SFA2_Prod_Strategy_Child_Record_Updates
        //GNE_SFA2_Prod_Strategy_Email_Notification
    }
}