/**
 * Common trigger for all 'before insert' actions on an MPS user.
 * All operation that should be performed before insert should be added to this trigger as separate static method calls.
 * 
 * Test classes: 
 * - none yet
 *
 * @author Radek Krawiec
 * @created 07/25/2012
 */
trigger GNE_CM_MPS_User_Before_Insert on GNE_CM_MPS_User__c (before insert)
{
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_MPS_User_Before_Insert'))
    {
        System.debug('Skipping trigger GNE_CM_MPS_User_Before_Insert');
        return;
    }
	// Update field User_Status__c depending on the value of the field Workflow_State__c.
	GNE_CM_MPS_User_Trigger_Util.updateUserStatus((List<GNE_CM_MPS_User__c>)Trigger.New);
}