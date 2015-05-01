trigger GNE_CM_MPS_Location_Operations on GNE_CM_MPS_Location__c (after update)
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_Location_Operations')) {
        system.debug('Skipping trigger GNE_CM_MPS_Location_Operations');
        return;
    }
	if (trigger.isUpdate && trigger.isAfter) {
		GNE_CM_MPS_Location_Trigger_Handler.updateMpsUserPreferencesOnLocationUpdate(trigger.oldMap, trigger.newMap);
	}
}