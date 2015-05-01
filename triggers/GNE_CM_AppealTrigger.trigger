trigger GNE_CM_AppealTrigger on Appeal_gne__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Appeal_gne__c.SObjectType);
}