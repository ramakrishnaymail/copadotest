/************************************************************
*  @author: Mateusz Michalczyk
*  Date: 2014-12-02
*  Description: This is a trigger for handling SFA2_PFG_Product_Limit_gne__c
*  Test class: GNE_SFA2_PFG_Product_Limit_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
* 
*********************************************************/           
trigger GNE_SFA2_PFG_Product_Limit_Trigger on SFA2_PFG_Product_Limit_gne__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(!GNE_SFA2_Util.isAdminMode()){
		if(Trigger.isBefore && Trigger.isDelete){
			GNE_SFA2_Deleted_Records_Util.onBeforeDelete(Trigger.old, SFA2_PFG_Product_Limit_gne__c.getSObjectType());						
		} else if(Trigger.isAfter && Trigger.isDelete){
			GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, SFA2_PFG_Product_Limit_gne__c.getSObjectType());			
		}
	}
	
}