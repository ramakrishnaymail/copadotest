trigger GNE_CM_PracticeAgreementLocationTrigger on GNE_CM_MPS_Practice_Agreement_Location__c (before insert, after insert, before update, after update, before delete, after delete)
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(GNE_CM_MPS_Practice_Agreement_Location__c.SObjectType);
}