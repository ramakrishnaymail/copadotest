trigger GNE_CM_MPS_User_Operations on GNE_CM_MPS_User__c (after insert)
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_User_Operations')) {
        System.debug('Skipping trigger GNE_CM_MPS_User_Operations');
        return;
    }
	GNE_CM_MPS_User_Operations_Handler.createMpsUserPreferencesOnMpsUserInsert(Trigger.new);
}