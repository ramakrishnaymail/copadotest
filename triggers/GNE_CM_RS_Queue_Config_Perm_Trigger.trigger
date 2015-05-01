trigger GNE_CM_RS_Queue_Config_Perm_Trigger on GNE_CM_RS_Queue_Config__c (before update, before delete) {
	GNE_CM_RS_Queue_Config_Helper.testProfilePermissions(Trigger.new, Trigger.old);
}