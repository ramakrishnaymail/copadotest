/************************************************************
*  @author: Mateusz Michalczyk
*  Date: 2014-12-02
*  Description: This is a trigger for handling HIN_Number_fpm_gne__c
*  Test class: GNE_SFA2_HIN_Number_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_SFA2_HIN_Number_Trigger on HIN_Number_fpm_gne__c (before delete, after delete) {

	if(!GNE_SFA2_Util.isAdminMode()){
		if(Trigger.isAfter && Trigger.isDelete){			
	  		GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, HIN_Number_fpm_gne__c.getSObjectType());
		}
	}
}