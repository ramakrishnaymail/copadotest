trigger CMT_ExpoBeforeDelete_gne on CMT_Expo_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Expo_gne__c', Trigger.old);
}