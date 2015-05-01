/************************************************************
*  @author: Lukasz Kwiatkowski, Roche
*  Date: 2012-08-20
*  Description: This is a trigger for handling Affiliation validations, field updates and child record updates
*  Test class: GNE_SFA2_Affiliation_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*            
*************************************************************/
trigger GNE_SFA2_Affiliation_Trigger on Affiliation_vod__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    private boolean validationFailed = false;
    
    if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_Affiliation_Trigger__c')) {
        if(Trigger.isBefore && Trigger.isInsert){         
           validationFailed = GNE_SFA2_Affiliation_Validation_Rules.onBeforeInsert(Trigger.new);
           GNE_SFA2_Affiliation_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
           validationFailed = GNE_SFA2_Affiliation_Validation_Rules.onBeforeUpdate(Trigger.old, Trigger.new);
           GNE_SFA2_Affiliation_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        }  else if(Trigger.isAfter && Trigger.isInsert){
            if(!validationFailed) {
            	try {
            		GNE_SFA2_Affiliation_Child_Record_Update.onAfterInsert(Trigger.old, Trigger.new, true);
            	} catch (Exception ex){
            		GNE_SFA2_Affiliation_Child_Record_Update.onAfterInsert(Trigger.old, Trigger.new, false);
            	}            	
            }
        } else if(Trigger.isAfter && Trigger.isUpdate){
            if(!validationFailed) {
            	try {
                	GNE_SFA2_Affiliation_Child_Record_Update.onAfterUpdate(Trigger.old, Trigger.new, true);
            	} catch (Exception ex){
            		GNE_SFA2_Affiliation_Child_Record_Update.onAfterUpdate(Trigger.old, Trigger.new, false);
            	}                
            }
        } else if(Trigger.isAfter && Trigger.isDelete){
            if(! validationFailed) {
            	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Affiliation_vod__c.getSObjectType());
                GNE_SFA2_Affiliation_Child_Record_Update.onAfterDelete(Trigger.old);
            }
        }
        
        //GNE_SFA2_Affiliation_Email_Notifications
    }
}