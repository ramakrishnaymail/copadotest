/**
 * GNE_CM_MPS_Practice_Agreement_HCO_Mapping
 * Created by: Steve Waters, 2012-12-07
 *
 * Inserts/Removes GNE_CM_MPS_Registration_HCO_Mapping__c objects based
 * on contents of GNE_CM_MPS_Practice_Agreement__c
 */
trigger GNE_CM_MPS_Practice_Agreement_HCO_Mapping on GNE_CM_MPS_Practice_Agreement__c (after delete, 
																						after insert, 
																						after undelete, 
																						after update) 
{
	Map<String, GNE_CM_MPS_Registration_HCO_Mapping__c> mapUps=new Map<String, GNE_CM_MPS_Registration_HCO_Mapping__c>();
	Map<String, GNE_CM_MPS_Registration_HCO_Mapping__c> mapDel=new Map<String, GNE_CM_MPS_Registration_HCO_Mapping__c>();
	Set<String> setDelIds=new Set<String>();

	// process the old
	if (Trigger.isUpdate || Trigger.isDelete)
	{
		mapDel=GNE_CM_MPS_Utils.generateRegHCOMappingMapOld(Trigger.old);
	}
//System.debug('>>>>> mapDel=' + mapDel);

	// process the new the same way
	if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUnDelete)
	{
		mapUps=GNE_CM_MPS_Utils.generateRegHCOMappingMapNew(Trigger.new);
	}
//System.debug('>>>>> mapUps=' + mapUps);

	// delete any from the old set that are now longer in the new
	for (String key : mapDel.keyset())
	{
		if (!mapUps.containsKey(key))
		{
			setDelIds.add(key);
		}
	}
//System.debug('>>>>> setDelIds=' + setDelIds);
	
	if (!setDelIds.IsEmpty())
	{
		delete [select Id from GNE_CM_MPS_Registration_HCO_Mapping__c where External_ID__c IN :setDelIds];
	}
	
	if (!mapUps.IsEmpty())
	{
		upsert mapUps.values() External_ID__c;
	}
}