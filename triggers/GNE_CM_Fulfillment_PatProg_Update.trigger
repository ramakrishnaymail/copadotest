/**
 * GNE_CM_Fulfillment_PatProg_Update
 * Created by: Steve Waters, 2012-12-12
 *
 * When shipment date is set, this trigger looks for related Patient Program records for
 *	products which have post-shipment surveys and sets the reprocess flag for those records\
 *	which will force the generation of additional surveys 
 */
trigger GNE_CM_Fulfillment_PatProg_Update on Fulfillment_gne__c (after insert, after update) 
{
	//Set<String> caseTriggeredIds=new Set<String>();
	Map<String, Date> mapCaseShipDates=new Map<String, Date>();
	
	for (Fulfillment_gne__c ful : Trigger.new)
	{
		Date dteFirst=null, dteLast=null;
		
		if (Trigger.isUpdate)	
		{
			dteFirst=Trigger.oldMap.get(ful.Id).Date_of_First_Commercial_Shipment_gne__c;
			dteLast=Trigger.oldMap.get(ful.Id).Date_of_Last_Commercial_Shipment_gne__c;
		}

		// if we have a ship date - any ship date - then trigger the survey
		if ((ful.Date_of_First_Commercial_Shipment_gne__c!=null || ful.Date_of_Last_Commercial_Shipment_gne__c!=null) 
					&& (dteFirst==null && dteLast==null))
		{
			//caseTriggeredIds.add(ful.Case_Fulfillment_gne__c);
			mapCaseShipDates.put(ful.Case_Fulfillment_gne__c, (ful.Date_of_Last_Commercial_Shipment_gne__c!=null ? ful.Date_of_Last_Commercial_Shipment_gne__c : ful.Date_of_First_Commercial_Shipment_gne__c));
		}
	}
	
	GNE_PatPers_InsertUpdate_Trigger_Support.reprocessShippedPatientPrograms(mapCaseShipDates);
}