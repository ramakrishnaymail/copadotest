trigger CMT_HotelsBeforeDelete_gne on CMT_Hotel_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Hotel_gne__c', Trigger.old);
}