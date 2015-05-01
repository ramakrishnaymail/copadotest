trigger CMT_AnnouncementsBeforeDelete_gne on CMT_Announcement_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Announcement_gne__c', Trigger.old);
}