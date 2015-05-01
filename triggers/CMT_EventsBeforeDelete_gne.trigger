trigger CMT_EventsBeforeDelete_gne on CMT_Event_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Event_gne__c', Trigger.old);
}