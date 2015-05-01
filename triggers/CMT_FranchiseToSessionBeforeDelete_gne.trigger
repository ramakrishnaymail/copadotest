trigger CMT_FranchiseToSessionBeforeDelete_gne on CMT_FranchiseToSession_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteFranchiseToSessionTrigger (Trigger.old);
}