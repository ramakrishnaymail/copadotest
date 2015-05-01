trigger GNE_CM_BITrigger on Benefit_Investigation_gne__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Benefit_Investigation_gne__c.SObjectType);
}