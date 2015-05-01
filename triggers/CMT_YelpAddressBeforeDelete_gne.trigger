trigger CMT_YelpAddressBeforeDelete_gne on CMT_Yelp_Address_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Yelp_Address_gne__c', Trigger.old);
}