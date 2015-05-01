// trigger updates batch event fields: ValidParticipants_gne__c, InvalidParticipants_gne__c
// when child participants are inserted, updated

trigger VDST_BatchEventSetParticipantsNumber on VDST_BatchRecord_gne__c (after insert, after update) {
    if(Trigger.isInsert) {
        List<VDST_BatchRecord_gne__c> participants = new List<VDST_BatchRecord_gne__c>();
        for(VDST_BatchRecord_gne__c prtcp : Trigger.new) {
            if(prtcp.VDST_ParentEvent_gne__c != null && prtcp.IsAfterBatchProcessing_gne__c) {
                participants.add(prtcp);
            }
        }
        if(participants.size() == 0) {
            return;
        }

        Map<String, Integer> eventIdToValidPrtcp = new Map<String, Integer>();
        Map<String, Integer> eventIdToInvalidPrtcp = new Map<String, Integer>();
        for(VDST_BatchRecord_gne__c prtcp : participants) {
            if(prtcp.isValid__c) {
                if(eventIdToValidPrtcp.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToValidPrtcp.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToValidPrtcp.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToValidPrtcp.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            } else {
                if(eventIdToInvalidPrtcp.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToInvalidPrtcp.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToInvalidPrtcp.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToInvalidPrtcp.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            }
        }
        Set<String> eventIds = new Set<String>();
        eventIds.addAll( eventIdToValidPrtcp.keySet() );
        eventIds.addAll( eventIdToInvalidPrtcp.keySet() );
        List<VDST_BatchRecord_gne__c> events = [
            SELECT  Id, ValidParticipants_gne__c, InvalidParticipants_gne__c
            FROM    VDST_BatchRecord_gne__c
            WHERE   Id IN :eventIds
        ];
        for(VDST_BatchRecord_gne__c ev : events) {
            ev.ValidParticipants_gne__c += (eventIdToValidPrtcp.containsKey(ev.Id) ? eventIdToValidPrtcp.get(ev.Id) : 0);
            ev.InvalidParticipants_gne__c += (eventIdToInvalidPrtcp.containsKey(ev.Id) ? eventIdToInvalidPrtcp.get(ev.Id) : 0);
        }
        update events;
    } else if(Trigger.isUpdate) {
        List<VDST_BatchRecord_gne__c> participantsNew = new List<VDST_BatchRecord_gne__c>();
        Set<String> participantsNewIds = new Set<String>();
        for(VDST_BatchRecord_gne__c prtcp : Trigger.new) {
            if(prtcp.VDST_ParentEvent_gne__c != null && prtcp.IsAfterBatchProcessing_gne__c) {
                participantsNew.add(prtcp);
                participantsNewIds.add(prtcp.Id);
            }
        }
        if(participantsNew.size() == 0) {
            return;
        }
        List<VDST_BatchRecord_gne__c> participantsOld = new List<VDST_BatchRecord_gne__c>();
        Map<String, VDST_BatchRecord_gne__c> participantsOldMap = new Map<String, VDST_BatchRecord_gne__c>();
        for(VDST_BatchRecord_gne__c prtcp : Trigger.old) {
            if(participantsNewIds.contains(prtcp.Id)) {
                participantsOld.add(prtcp);
                participantsOldMap.put(prtcp.Id, prtcp);
            }
        }
        Boolean isParentAssignment = (participantsOld[0].VDST_ParentEvent_gne__c == null);

        Map<String, Integer> eventIdToValidPrtcpOld = new Map<String, Integer>();
        Map<String, Integer> eventIdToValidPrtcpNew = new Map<String, Integer>();
        Map<String, Integer> eventIdToInvalidPrtcpOld = new Map<String, Integer>();
        Map<String, Integer> eventIdToInvalidPrtcpNew = new Map<String, Integer>();
        for(VDST_BatchRecord_gne__c prtcp : participantsOld) {
            if(prtcp.isValid__c) {
                if(eventIdToValidPrtcpOld.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToValidPrtcpOld.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToValidPrtcpOld.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToValidPrtcpOld.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            } else {
                if(eventIdToInvalidPrtcpOld.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToInvalidPrtcpOld.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToInvalidPrtcpOld.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToInvalidPrtcpOld.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            }
        }
        for(VDST_BatchRecord_gne__c prtcp : participantsNew) {
            if(prtcp.isValid__c) {
                if(eventIdToValidPrtcpNew.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToValidPrtcpNew.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToValidPrtcpNew.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToValidPrtcpNew.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            } else {
                if(eventIdToInvalidPrtcpNew.containsKey(prtcp.VDST_ParentEvent_gne__c)) {
                    Integer num = eventIdToInvalidPrtcpNew.get(prtcp.VDST_ParentEvent_gne__c);
                    eventIdToInvalidPrtcpNew.put(prtcp.VDST_ParentEvent_gne__c, ++num);
                } else {
                    eventIdToInvalidPrtcpNew.put(prtcp.VDST_ParentEvent_gne__c, 1);
                }
            }
        }
        Set<String> eventIds = new Set<String>();
        eventIds.addAll( eventIdToValidPrtcpNew.keySet() );
        eventIds.addAll( eventIdToInvalidPrtcpNew.keySet() );
        List<VDST_BatchRecord_gne__c> events = [
            SELECT  Id, ValidParticipants_gne__c, InvalidParticipants_gne__c
            FROM    VDST_BatchRecord_gne__c
            WHERE   Id IN :eventIds
        ];
        for(VDST_BatchRecord_gne__c ev : events) {
            if(isParentAssignment) {
                ev.ValidParticipants_gne__c += (eventIdToValidPrtcpNew.containsKey(ev.Id) ? eventIdToValidPrtcpNew.get(ev.Id) : 0);
                ev.InvalidParticipants_gne__c += (eventIdToInvalidPrtcpNew.containsKey(ev.Id) ? eventIdToInvalidPrtcpNew.get(ev.Id) : 0);

            } else {
                Integer oldMinusNew = (eventIdToValidPrtcpOld.containsKey(ev.Id) ? eventIdToValidPrtcpOld.get(ev.Id) : 0)
                   - (eventIdToValidPrtcpNew.containsKey(ev.Id) ? eventIdToValidPrtcpNew.get(ev.Id) : 0);
                if(oldMinusNew != 0) {
                    ev.ValidParticipants_gne__c -= oldMinusNew;
                    ev.InvalidParticipants_gne__c += oldMinusNew;
                }
            }
        }
        update events;
    }
}