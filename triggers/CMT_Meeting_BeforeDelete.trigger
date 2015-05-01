trigger CMT_Meeting_BeforeDelete on CMT_Meeting_gne__c (before delete)
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Meeting_gne__c', Trigger.old);
}