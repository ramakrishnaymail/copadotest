trigger VDST_UpdateAttendanceObj on VDST_EventPrtcpntAttendance_gne__c (before update, after update, after insert, after delete) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_UpdateAttendanceObj => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());

	// Get event Type
    String eventType = Trigger.new.get(0).EventType_gne__c;
    // Make modifications
    if(!String.isBlank(eventType) && VDST_Utils.isStdEventType(eventType)) { // Trigger needed only for Standard event types
		if(Trigger.isAfter) {
			// Managing Participant Transactions
		    Set<String> accntToUpdate = new Set<String>();
		    for(VDST_EventPrtcpntAttendance_gne__c epa : Trigger.new) {
		        accntToUpdate.add(epa.Event_PrtcpntAccnt_gne__c);
		    }
		    VDST_Utils.updatePrtcpntTransactionsDM(accntToUpdate);
		} else if(Trigger.isBefore) {
			// Modify Meal Amount for Participant before update
			VDST_Utils.changeMealAmountForPrtcpntBeforeModification(Trigger.new, Trigger.oldMap, Trigger.newMap);
		}
    }

	System.debug(LoggingLevel.ERROR, 'XXXX VDST_UpdateAttendanceObj => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}