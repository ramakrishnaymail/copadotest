trigger CMT_InformationAddressBeforeDelete_gne on CMT_Information_Address_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Information_Address_gne__c', Trigger.old);
}