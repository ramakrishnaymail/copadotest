/************************************************************
*  @author: 
*  Date: 
*  Description: This is a trigger for handling Call_PFG_Detail_gne__c
*  Test class: ?
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation. Also added this comment section.        
*************************************************************/
trigger GNE_SFA2_PFG_CallPfgDetail_Trigger on Call_PFG_Detail_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if(!GNE_SFA2_PFG_CPD_Trigger_Helper.inCPDTrig() && 
       !GNE_SFA2_Util.isAdminMode() && 
       !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PFG_CallPfgDetail_Trigger') &&
       !GNE_SFA2_Util.isMergeMode()) {
       
      GNE_SFA2_PFG_CPD_Trigger_Helper.setCPDTrig(true);
      
      if(Trigger.isBefore && Trigger.isInsert){
        GNE_SFA2_PFG_CPD_Field_Update.onBeforeInsert(Trigger.new);
      } else if(Trigger.isBefore && Trigger.isUpdate) {
        GNE_SFA2_PFG_CPD_Field_Update.onBeforeUpdate(Trigger.old, Trigger.new);
      } else if(Trigger.isBefore && Trigger.isDelete){
        
      } else if(Trigger.isAfter && Trigger.isInsert){
        GNE_SFA2_PFG_CPD_Child_Record_Updates.onAfterInsert(Trigger.new);
      } else if(Trigger.isAfter && Trigger.isUpdate){
        GNE_SFA2_PFG_CPD_Child_Record_Updates.onAfterUpdate(Trigger.old, Trigger.new);
      } else if(Trigger.isAfter && Trigger.isDelete){
      	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Call_PFG_Detail_gne__c.getSObjectType());        
        GNE_SFA2_PFG_CPD_Child_Record_Updates.onAfterDelete(Trigger.old);
      }
      
      GNE_SFA2_PFG_CPD_Trigger_Helper.setCPDTrig(false);
    }
}