trigger CMT_AbstractBeforeDelete_gne on CMT_Abstract_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Abstract__c', Trigger.old);
}