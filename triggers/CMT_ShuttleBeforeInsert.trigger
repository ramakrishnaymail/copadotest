trigger CMT_ShuttleBeforeInsert on CMT_Shuttle_gne__c (before insert)
{
    Id meetingId = Trigger.NEW.get(0).Meeting_gne__c;
    
    if (meetingId == null)
    {
        throw new CMT_Exception('Meeting ID is null');
    }
    
    CMT_Transportation_gne__c t = CMT_MiscUtils.fetchOrCreateTransportation(meetingId);
       
    for (CMT_Shuttle_gne__c o : Trigger.NEW)
    {
        o.Transportation_gne__c = t.Id;
    }
}