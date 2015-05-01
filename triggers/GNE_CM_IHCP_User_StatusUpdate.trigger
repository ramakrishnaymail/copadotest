trigger GNE_CM_IHCP_User_StatusUpdate on GNE_CM_IHCP_User__c (after insert, after update) 
{
    Map<Id, String> newUserStatus=new Map<Id, String>();
    Map<Id, Id> newUserSFDCUsers=new Map<Id, Id>();
    Map<Id, String> oldUserStatus=null;

    for (GNE_CM_IHCP_User__c so : Trigger.new) 
    {
        newUserStatus.put(so.Id, so.MPS_Status__c);
        newUserSFDCUsers.put(so.Id, so.SFDC_User__c);
    }

    if (Trigger.old!=null) 
    {
        oldUserStatus=new Map<Id, String>();
        for (GNE_CM_IHCP_User__c so : Trigger.old) 
        {
            oldUserStatus.put(so.Id, so.MPS_Status__c);
        }
    }

    // unit tests will call this method directly
    // and we'll fail if called from a future method
    if (!Test.isRunningTest() && !System.isFuture()) 
    {
        GNE_CM_IHCP_User_Util.updateUserSCMFields(newUserStatus, newUserSFDCUsers, oldUserStatus);          
    }
}