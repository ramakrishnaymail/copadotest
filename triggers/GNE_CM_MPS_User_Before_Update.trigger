/**
 * Common trigger for all 'before update' actions on an MPS user.
 * All operation that should be performed before update should be added to this trigger as separate static method calls.
 * 
 * Test classes: 
 * - GNE_CM_MPS_User_Flow_Test
 *
 * @author Radek Krawiec
 * @created 07/20/2012
 */
trigger GNE_CM_MPS_User_Before_Update on GNE_CM_MPS_User__c (before update)
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_User_Before_Update'))
    {
        System.debug('Skipping trigger GNE_CM_MPS_User_Before_Update');
        return;
    }
	// Update field User_Status__c depending on the value of the field Workflow_State__c.
	GNE_CM_MPS_User_Trigger_Util.updateUserStatus((List<GNE_CM_MPS_User__c>)Trigger.New);
	GNE_CM_MPS_User_Trigger_Util.updateLockoutCounter(Trigger.newMap, Trigger.oldMap);
}