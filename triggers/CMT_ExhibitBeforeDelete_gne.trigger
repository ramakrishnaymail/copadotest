trigger CMT_ExhibitBeforeDelete_gne on CMT_Exhibit_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Exhibit_gne__c', Trigger.old);
}