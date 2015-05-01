trigger CMT_FranchiseBeforeDelete_gne on CMT_Franchise_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Franchise_gne__c', Trigger.old);
    
    List<ID> ids = new List<Id>();
    
    for (CMT_Franchise_gne__c s : Trigger.OLD)
    {
        ids.add(s.Id);
    }
    
    List<CMT_FranchiseToSession_gne__c> fts = [SELECT Id FROM CMT_FranchiseToSession_gne__c WHERE Franchise_gne__c in :ids];
    
    if (fts != null && !fts.isEmpty())
    {
        delete fts;
    }
}