/** @date 3/15/2013
* @Author Pawel Sprysak
* @description Trigger for updating AV value on summary object and creating/deleting Event Dates and Creating Event Date Transactions after changing Event Start/End Date
*/
trigger VDST_UpdateAVSummary_gne on VDST_Event_gne__c (after insert, after update, before update) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_UpdateAVSummary_gne => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());

	if(Trigger.isAfter) {
	    try {
	    	// Prepare list containers
	        List<VDST_EventDate_gne__c> eventDateToDelList = new List<VDST_EventDate_gne__c>();
	        List<VDST_EventDate_gne__c> eventDateToInsList = new List<VDST_EventDate_gne__c>();
	        Map<String, Double> eventIdToAmount = new Map<String, Double>();

	        // Prepare list of Event Date objects to Insert or Remove after changing Event Start/End Dates
	        Boolean errorMessage = VDST_Utils.prepareEventDateData(eventDateToDelList, eventDateToInsList, eventIdToAmount, Trigger.new, Trigger.newMap, Trigger.oldMap, Trigger.isInsert);
	
			// Check and update data
	        if(!errorMessage) {
		        // DB methods
		        delete eventDateToDelList;
		        insert eventDateToInsList;
	        } else {
	        	return;
	        }
	
	        // Create Event Date Transactions
	        VDST_Utils.createEventDateTransaction(eventDateToInsList, eventIdToAmount);
	    } catch(QueryException e) {
	        Trigger.new.get(0).addError('Error while creating Event Dates');
	    }
	    
	    if( Trigger.isUpdate ) {
	    	// Update related values after changing Event data
		    VDST_Utils.updateValuesAfterChangingEventData(Trigger.New, Trigger.old, Trigger.newMap, Trigger.oldMap);
	    }

	    // Update AV transaction value after changing AV on Event
	    VDST_Utils.updateAvTransaction(Trigger.New, Trigger.newMap);
	} else if(Trigger.isUpdate) { // Before Update
		// Add postfix to VendorEventID_gne__c and GNE_EventID_gne__c fields after changing status to DROPPED
		VDST_Utils.updateDroppedEventUniqueIds(Trigger.New, Trigger.Old);
	}

    System.debug(LoggingLevel.ERROR, 'XXXX VDST_UpdateAVSummary_gne => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}