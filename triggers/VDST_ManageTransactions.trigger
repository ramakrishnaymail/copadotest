/** @date 3/5/2013
* @Author Pawel Sprysak
* @description Trigger for Deleting Date Transaction befor Dates AND for create new Attendance objects
*/
trigger VDST_ManageTransactions on VDST_EventDate_gne__c (before delete, after insert) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_ManageTransactions => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());

	// Delete Event Date Transactions before Event Dates are deleted (because relation to Event is needed)
    if(Trigger.isDelete) {
        delete VDST_Utils.getEvDateTransIdsByEvDateIds(Trigger.oldMap.keySet());
    }

    if(Trigger.isInsert) {
        insert VDST_Utils.prepareTriggerNewAttendanceList(Trigger.New);
    }

    System.debug(LoggingLevel.ERROR, 'XXXX VDST_ManageTransactions => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}