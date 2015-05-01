trigger GNE_CM_TaskTrigger on Task (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Task.SObjectType);
}