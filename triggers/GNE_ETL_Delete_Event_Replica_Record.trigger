trigger GNE_ETL_Delete_Event_Replica_Record on Event (after delete) {    

	// SFA2 bypass
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_ETL_Delete_Event_Replica_Record')) {
		return;
	}

    GNE_ETL_EventTaskReplicator_Utility.deletEventReplicaAfterEventDelete(trigger.oldMap.keySet());
}