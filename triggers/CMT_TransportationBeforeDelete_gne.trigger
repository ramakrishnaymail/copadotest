trigger CMT_TransportationBeforeDelete_gne on CMT_Transportation_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Transportation_gne__c', Trigger.old);
}