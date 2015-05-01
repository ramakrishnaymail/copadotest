trigger CMT_AddressBeforeDelete_gne on CMT_Address_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Address_gne__c', Trigger.old);
}