/** @date 2/5/2013
* @Author Pawel Sprysak
* @description Trigger for updating Total value
*/
trigger VDST_TotalValUpdates on VDST_EventTransactionSummary_gne__c (after insert, after update) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_TotalValUpdates => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
	// Create Set of Id's for Event Summary objects
	Set<Id> eventIds = new Set<Id>();
    for(VDST_EventTransactionSummary_gne__c ets : Trigger.new) {
    	if(!'TOTALEVENT'.equals(ets.EventTransactionTypeCode_gne__c)) {
    		eventIds.add(ets.VDST_Event_gne__c);
    	}
    }
    // Create Map for Event Id's and List of Summary Transactions fot them
    if(eventIds.size() > 0) {
	    Map<Id, List<VDST_EventTransactionSummary_gne__c>> etsMap = new Map<Id, List<VDST_EventTransactionSummary_gne__c>>();
	    Map<Id, VDST_EventTransactionSummary_gne__c> masterEtsMap = new Map<Id, VDST_EventTransactionSummary_gne__c>();
	    for(VDST_EventTransactionSummary_gne__c ets : [SELECT Id, EventTransactionTypeCode_gne__c, EventTransactionAmount_gne__c, VDST_Event_gne__c FROM VDST_EventTransactionSummary_gne__c WHERE VDST_Event_gne__c IN :eventIds]) {
	    	if('TOTALEVENT'.equals(ets.EventTransactionTypeCode_gne__c)) {
	    		masterEtsMap.put(ets.VDST_Event_gne__c, ets);
	    	} else {
		    	if(etsMap.containsKey(ets.VDST_Event_gne__c)) {
		    		etsMap.get(ets.VDST_Event_gne__c).add(ets);
		    	} else {
		    		etsMap.put(ets.VDST_Event_gne__c, new List<VDST_EventTransactionSummary_gne__c>{ets});
		    	}
	    	}
	    }
	    // Update or Create Summary Total objects
	    List<VDST_EventTransactionSummary_gne__c> etsList = new List<VDST_EventTransactionSummary_gne__c>();
	    for(Id eventId : eventIds) {
	    	VDST_EventTransactionSummary_gne__c masterEts = new VDST_EventTransactionSummary_gne__c(EventTransactionAmount_gne__c = 0, EventTransactionLevel_gne__c = 'EVNT', EventTransactionTypeCode_gne__c = 'TOTALEVENT', VDST_Event_gne__c = eventId);
	    	if(masterEtsMap.containsKey(eventId)) {
	    		masterEts = masterEtsMap.get(eventId);
	    		masterEts.EventTransactionAmount_gne__c = 0;
	    	}
	    	for(VDST_EventTransactionSummary_gne__c ets : etsMap.get(eventId)) {
	    		masterEts.EventTransactionAmount_gne__c += ets.EventTransactionAmount_gne__c;
	    	}
	    	etsList.add(masterEts);
	    }
	    if(etsList.size() > 0) {
	        upsert etsList;
	    }
    }
    System.debug(LoggingLevel.ERROR, 'XXXX VDST_TotalValUpdates => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}