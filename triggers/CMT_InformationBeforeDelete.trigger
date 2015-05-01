trigger CMT_InformationBeforeDelete on CMT_Information_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Information_gne__c', Trigger.old);
}