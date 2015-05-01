trigger GNE_CM_AdditionalSupportTrigger on Alternative_Funding_gne__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Alternative_Funding_gne__c.SObjectType);
}