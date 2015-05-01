trigger GNE_CM_ShipmentTrigger on Shipment_gne__c (after delete, after insert, after update, before delete, before insert, before update) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Shipment_gne__c.SObjectType);	
}