/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-08-07
*  Description: This is a trigger for handling Address validations, field updates and child record updates
*  Test class: GNE_SFA2_Address_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*            
*************************************************************/
trigger GNE_SFA2_Address_Trigger on Address_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode() 
        && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Address_Trigger__c') && !GNE_SFA2_Address_Trigger_Helper.inAddressTrig()) {
        	               
        GNE_SFA2_Address_Trigger_Helper.setAddressTrig(true);
        if(Trigger.isBefore && Trigger.isInsert){   
        	GNE_SFA2_Address_Trigger_Helper.clearFailedValidations();  
           	GNE_SFA2_Address_Validation_Rules.onBeforeInsert(Trigger.new);
           	GNE_SFA2_Address_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
			GNE_SFA2_Address_Trigger_Helper.clearFailedValidations();
			GNE_CM_Address_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
           	GNE_SFA2_Address_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
           	GNE_SFA2_Address_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isBefore && Trigger.isDelete){
        	GNE_SFA2_Address_Trigger_Helper.clearFailedValidations();
           	GNE_SFA2_Address_Validation_Rules.onBeforeDelete(Trigger.old);
           	GNE_SFA2_Address_Field_Updates.onBeforeDelete(Trigger.old);
        } else if(Trigger.isAfter && Trigger.isInsert){
            GNE_SFA2_Address_Child_Record_Updates.onAfterInsert(Trigger.new);
        } else if(Trigger.isAfter && Trigger.isUpdate){
            GNE_SFA2_Address_Child_Record_Updates.onAfterUpdate(Trigger.old, Trigger.new);
        } else if(Trigger.isAfter && Trigger.isDelete){
        	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Address_vod__c.getSObjectType());            
        }
        GNE_SFA2_Address_Trigger_Helper.setAddressTrig(false);
        //GNE_SFA2_Address_Email_Notifications
    }	

}