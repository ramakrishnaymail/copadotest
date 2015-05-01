trigger CMT_ContactBeforeDelete_gne on CMT_Contact_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Contact_gne__c', Trigger.old);
}