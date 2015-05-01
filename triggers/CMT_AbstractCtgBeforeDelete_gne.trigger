trigger CMT_AbstractCtgBeforeDelete_gne on CMT_Abstract_Category_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Abstract_Category_gne__c', Trigger.old);
}