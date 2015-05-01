trigger GNE_CM_PriorAuthorizationTrigger on Prior_Authorization_gne__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Prior_Authorization_gne__c.SObjectType);
}