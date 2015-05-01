/**
 * GNE_CM_Shipment_PatProg_Update
 * Created by: Steve Waters, 2012-12-12
 *
 * When shipment date is set, this trigger looks for related Patient Program records for
 *	products which have post-shipment surveys and sets the reprocess flag for those records
 *	which will force the generation of additional surveys 
 */
 trigger GNE_CM_Shipment_PatProg_Update on Shipment_gne__c (after insert, after update) 
 {
 	
    // skip this trigger during merge process
	if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
		return;
	} 	
 	
	//Set<String> caseTriggeredIds=new Set<String>();
	Map<String, Date> mapCaseShipDates=new Map<String, Date>();
	
	for (Shipment_gne__c shp : Trigger.new)
	{
		Datetime dteShip=null;
		
		if (Trigger.isUpdate)	
		{
			dteShip=Trigger.oldMap.get(shp.Id).Shipped_Date_gne__c;
		}

		// if we have a ship date - any ship date - then trigger the survey
		if (shp.Shipped_Date_gne__c!=null && dteShip==null)
		{
			//caseTriggeredIds.add(shp.Case_Shipment_gne__c);
			mapCaseShipDates.put(shp.Case_Shipment_gne__c, date.newinstance(shp.Shipped_Date_gne__c.year(), shp.Shipped_Date_gne__c.month(), shp.Shipped_Date_gne__c.day()));
		}
	}
	
	GNE_PatPers_InsertUpdate_Trigger_Support.reprocessShippedPatientPrograms(mapCaseShipDates);
}