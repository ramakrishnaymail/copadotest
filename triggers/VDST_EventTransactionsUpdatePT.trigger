/** @date 3/15/2013
* @Author Pawel Sprysak
* @description Trigger for updating Participant transactions on summary object
*/
trigger VDST_EventTransactionsUpdatePT on VDST_PrtcpntTransaction_gne__c (before update, after insert, after update, after delete) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_EventTransactionsUpdatePT => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
	if(Trigger.isAfter) {
		String eventType;
	    Set<String> eventIds = new Set<String>();
        // Add Events Id's from Participant Transaction when deleted
        if(Trigger.isDelete) {
        	eventType = Trigger.old.get(0).EventType_gne__c;
            //List<Id> eventParticipantIds = new List<Id>();
            for(VDST_PrtcpntTransaction_gne__c pt : Trigger.old) {        
                if( (!'ORG'.equals(pt.FeePayToPartyType_gne__c) || !VDST_Utils.isStdEventType(eventType)) && pt.TransactionAmount_gne__c != null && pt.TransactionAmount_gne__c != 0) {
                    //eventParticipantIds.add(pt.VDST_EventPrtcpntAccnt_gne__c);
                    eventIds.add(pt.VDST_Event_gne__c); //NEW
                }
            }
        }
	    // Add Events Id's from Participant Transaction when inserted/updated
	    if(Trigger.isUpdate || Trigger.isInsert) {
	    	eventType = Trigger.new.get(0).EventType_gne__c;   
            for(VDST_PrtcpntTransaction_gne__c pt : Trigger.new) {
                if((Trigger.isUpdate && (Trigger.oldMap.get(pt.Id).TransactionAmount_gne__c != Trigger.newMap.get(pt.Id).TransactionAmount_gne__c || !Trigger.oldMap.get(pt.Id).TransactionTypeCode_gne__c.equals(Trigger.newMap.get(pt.Id).TransactionTypeCode_gne__c)) )
                || (Trigger.isInsert && pt.TransactionAmount_gne__c != null && pt.TransactionAmount_gne__c != 0) ) {
                    //eventIds.add(pt.VDST_EventPrtcpntAccnt_gne__r.VDST_Event_gne__r.Id);
                    eventIds.add(pt.VDST_Event_gne__c); 
                }
            }
	    }
	    // Update transaction method
	    VDST_Utils.updateEventsTransactionsPT(eventIds, eventType);
	} else { // is Before
		String eventType = Trigger.new.get(0).EventType_gne__c;
		if(!String.isBlank(eventType) && VDST_Utils.isSSEventType(eventType)) {
			for(VDST_PrtcpntTransaction_gne__c prtpTrans : Trigger.new) {
	            Double itemAount = 0;
	            if('MEDWRTG'.equals(eventType)) {
	                itemAount = prtpTrans.ItemAmount_gne__c;
	            } else {
	            	Integer quantity = 0;
	            	if(prtpTrans.ItemQuantity_gne__c != null) {
	            		quantity = Integer.valueOf(prtpTrans.ItemQuantity_gne__c);
	            	}
	                itemAount = prtpTrans.ItemAmount_gne__c * quantity;
	            }
	            prtpTrans.TransactionAmount_gne__c = itemAount;
			}
		}
		
	}
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_EventTransactionsUpdatePT => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}