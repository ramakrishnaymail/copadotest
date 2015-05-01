/************************************************************
*  @author: Rakesh Boinepalli 
*  Date: 2012-12-16
*  Description: This is a trigger for handling Data Change Request validations, field updates and child record updates
*  Test class: GNE_SFA2_Data_Change_Request_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/

trigger GNE_SFA2_Data_Change_Request_Trigger on Change_Request_gne__c (after delete, after insert, after undelete, 
																		after update, before delete, before insert, before update) {
	if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_DCR_Trigger_Helper.inDcrTrig()){
		GNE_SFA2_DCR_Trigger_Helper.setDcrTrig(true);
		
		if(Trigger.IsBefore && Trigger.IsInsert){
			GNE_SFA2_DCR_Validation_Rules.onBeforeInsert(trigger.New);
			GNE_SFA2_DCR_Field_Updates.onBeforeInsert(trigger.New);
		}else if(Trigger.IsBefore && Trigger.IsUpdate){
			GNE_SFA2_DCR_Validation_Rules.onBeforeUpdate(trigger.New);
			GNE_SFA2_DCR_Field_Updates.onBeforeUpdate(trigger.Old,trigger.New,trigger.oldMap,trigger.NewMap);
		}else if (Trigger.IsBefore && Trigger.IsDelete){

		}else if(Trigger.IsAfter && Trigger.isInsert){
			GNE_SFA2_DCR_Child_Record_Updates.onAfterInsert(trigger.New);
			GNE_SFA2_DCR_Parent_Record_Updates.onAfterInsert(trigger.New);
		}else if(Trigger.isAfter && Trigger.isUpdate){
			GNE_SFA2_DCR_Child_Record_Updates.onAfterUpdate(trigger.Old,trigger.New);
			GNE_SFA2_DCR_Parent_Record_Updates.onAfterUpdate(trigger.Old,trigger.New);
		}else if(Trigger.isAfter && Trigger.isDelete){
			GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Change_Request_gne__c.getSObjectType());
			GNE_SFA2_DCR_Child_Record_Updates.onAfterDelete(trigger.Old);
			GNE_SFA2_DCR_Parent_Record_Updates.onAfterDelete(trigger.Old);
		}
		
		GNE_SFA2_DCR_Trigger_Helper.setDcrTrig(false);
	}
}