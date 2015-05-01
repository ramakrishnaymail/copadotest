trigger deleteToTDayRecordsOnEventsDelete on Event (after delete) {

	// SFA2 bypass
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('deleteToTDayRecordsOnEventsDelete')) {
		return;
	}

    TimeOffTerritory_WS.deleteToTDayRecordsOnEventsDelete(Trigger.old);
}