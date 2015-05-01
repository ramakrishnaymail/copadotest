trigger CMT_ParkingBeforeDelete_gne on CMT_Parking_gne__c (before delete) 
{    
    List<Id> transportationIds = new List<Id>();
    
    // for each parking, get the ID of the meeting from the parent transportation object
    for (CMT_Parking_gne__c p : Trigger.old)
    {
        transportationIds.add(p.Transportation_gne__c);
    }
    
    // find all parent transportation objects
    List<CMT_Transportation_gne__c> transportations = [SELECT Id, Meeting_gne__c
                                                                    FROM CMT_Transportation_gne__c
                                                                    WHERE Id in :transportationIds];
                                                                    
    Map<Id, CMT_Transportation_gne__c> transportationsById = new Map<Id, CMT_Transportation_gne__c>();
    
    for (CMT_Transportation_gne__c t : transportations)
    {
        transportationsById.put(t.Id, t);
    }
    
    Map<Id, Id> parentMeetingIds = new Map<Id, Id>();
                                                                    
    // for each parking, get the ID of the meeting from the parent transportation object
    for (CMT_Parking_gne__c p : Trigger.old)
    {
        parentMeetingIds.put(p.Id, transportationsById.get(p.Transportation_gne__c).Meeting_gne__c);
    }
    
    CMT_MiscUtils.onDeleteTrigger ('CMT_Parking_gne__c', Trigger.old, parentMeetingIds);
}