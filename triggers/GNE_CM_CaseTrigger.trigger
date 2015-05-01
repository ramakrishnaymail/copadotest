trigger GNE_CM_CaseTrigger on Case (before insert, after insert, before update, after update, before delete, after delete)
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Case.SObjectType);
}