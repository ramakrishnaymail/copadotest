/** @date 3/5/2013
* @Author Pawel Sprysak
* @description Trigger for updating Event Transaction Summary objects when Event Date Transaction has been changed
*/
trigger VDST_EventTransactionsUpdateDT on VDST_EventDateTransaction_gne__c (after insert, after update, after delete) {
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_EventTransactionsUpdateDT => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
    String eventType;
    if(Trigger.isDelete) {
        eventType = Trigger.Old.get(0).EventType_gne__c;
    } else {
        eventType = Trigger.New.get(0).EventType_gne__c;
    }
    if(!String.isBlank(eventType) && VDST_Utils.isStdEventType(eventType)) { // Trigger needed only for Standard event types
		if(Trigger.isInsert) {
	        // Get Event Id's of changed transacion Amounts
	        Set<String> eventIds = new Set<String>();
	        for(VDST_EventDateTransaction_gne__c dt : Trigger.new) {
	            eventIds.add(dt.VDST_Event_gne__c);
	        }
	        VDST_Utils.updateEventsTransactionsDT(eventIds);
		} else {
		    Set<String> eventIds = new Set<String>();
		    Set<Id> dateTransactionsId = new Set<Id>();
		    Set<String> eventDatesIds = new Set<String>();
		
		    // Get Id's of transaction where Amount was changed
		    for(VDST_EventDateTransaction_gne__c edt : Trigger.old) {
		    	eventDatesIds.add(edt.VDST_EventDate_gne__c);
		        if(Trigger.isUpdate && Trigger.oldMap.get(edt.Id).EventDateTransactionAmount_gne__c != Trigger.newMap.get(edt.Id).EventDateTransactionAmount_gne__c) {
		            dateTransactionsId.add(edt.Id);
		        } else if(Trigger.isDelete && edt.EventDateTransactionAmount_gne__c != null && edt.EventDateTransactionAmount_gne__c != 0) {
		            dateTransactionsId.add(edt.Id);
		        }
		    }
		
		    // Get Event Id's of changed transacion Amounts
		    for(VDST_EventDateTransaction_gne__c dt : VDST_Utils.getAllRowsEvDateTransByIdList(dateTransactionsId)) {
		        eventIds.add(dt.VDST_EventDate_gne__r.VDST_Event_gne__c);
		    }
		
		    // Update transactions
		    VDST_Utils.updateEventsTransactionsDT(eventIds);
		
		    // Update Prtcpnt transactions
		    Set<String> accntIds = new Set<String>();
		    List<VDST_EventPrtcpntAttendance_gne__c> epaList = [SELECT Id, MealAmount_gne__c, AttendanceStatus_gne__c, ParticipantMealConsumptionStatus_gne__c, VDST_EventDate_gne__r.VDST_Event_gne__c FROM VDST_EventPrtcpntAttendance_gne__c WHERE VDST_EventDate_gne__c IN :eventDatesIds];
		    if(epaList.size() > 0) {
		        Integer attCount = Integer.valueOf([SELECT TotBiggerPlanAttCnt_gne__c FROM VDST_Event_gne__c WHERE Id = :epaList.get(0).VDST_EventDate_gne__r.VDST_Event_gne__c].TotBiggerPlanAttCnt_gne__c);
			    for(VDST_EventPrtcpntAttendance_gne__c apa : epaList) {
		            for(VDST_EventDateTransaction_gne__c edt : Trigger.old) {
		                if(edt.VDST_EventDate_gne__c == apa.VDST_EventDate_gne__c) {
		                	if('ATND'.equals(apa.AttendanceStatus_gne__c) && 'CONSUMED'.equals(apa.ParticipantMealConsumptionStatus_gne__c) && !Trigger.isDelete) {
		                		if(attCount > 0) {
		                            apa.MealAmount_gne__c = Trigger.newMap.get(edt.Id).EventDateTransactionAmount_gne__c / attCount;
		                		} else {
		                			apa.MealAmount_gne__c = Trigger.newMap.get(edt.Id).EventDateTransactionAmount_gne__c;
		                		}
		                	} else {
		                		apa.MealAmount_gne__c = 0;
		                	}
		                    break;
		                }
		            }
			    }
			    upsert epaList;
		    }
		}
    }
	System.debug(LoggingLevel.ERROR, 'XXXX VDST_EventTransactionsUpdateDT => ' + Limits.getDMLRows() + ' AND ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
}