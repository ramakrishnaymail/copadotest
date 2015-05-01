trigger GNE_CM_DDSTrigger on GNE_CM_DDS_Service_Eligibility__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(GNE_CM_DDS_Service_Eligibility__c.SObjectType);
}