trigger GNE_ETL_Delete_Task_Replica_Record on Task (after delete) {

	// SFA2 bypass
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_ETL_Delete_Task_Replica_Record')) {
		return;
	}

    GNE_ETL_EventTaskReplicator_Utility.deleteTaskReplicaAfterTaskDelete(trigger.oldMap.keySet());
}