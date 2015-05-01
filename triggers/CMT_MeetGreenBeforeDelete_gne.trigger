trigger CMT_MeetGreenBeforeDelete_gne on CMT_Meet_Green_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Meet_Green_gne__c', Trigger.old);
}