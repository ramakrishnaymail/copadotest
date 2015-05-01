trigger CMT_SessionBeforeDelete_gne on CMT_Session_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Session_gne__c', Trigger.old, 'Commercial_Meeting_gne__c');
    
    List<ID> ids = new List<Id>();
    
    for (CMT_Session_gne__c s : Trigger.OLD)
    {
        ids.add(s.Id);
    }
    
    List<CMT_FranchiseToSession_gne__c> fts = [SELECT Id FROM CMT_FranchiseToSession_gne__c WHERE Session_gne__c in :ids];
    
    if (fts != null && !fts.isEmpty())
    {
        delete fts;
    }
}