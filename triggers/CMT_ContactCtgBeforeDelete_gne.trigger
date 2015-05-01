trigger CMT_ContactCtgBeforeDelete_gne on CMT_Contact_Category_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Contact_Category_gne__c', Trigger.old);
}