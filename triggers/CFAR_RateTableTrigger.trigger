trigger CFAR_RateTableTrigger on CFAR_Rate_Table_gne__c (after delete, after insert, after update, before insert, before update) {
	 
	Set<String> trialIds = new Set<String>();
	List<CFAR_Rate_Table_gne__c> rateTables = trigger.isUpdate || trigger.isInsert ? trigger.new : trigger.old;
	
	for(CFAR_Rate_Table_gne__c rt : rateTables) {
		if(!'Total'.equals(rt.Payment_Type_gne__c))
			trialIds.add(rt.CFAR_Trial_ref_gne__c);
	}
	
	if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert))
		CFAR_Budget_Utils.updateTotalPaidAmountOnRateTable(trialIds,rateTables);
		//for(CFAR_Rate_Table_gne__c rt : trigger.new) {
		//	if(String.isBlank(rt.WithHold_Type_gne__c))
		//		rt.Withhold_Value_gne__c = null;
		//}
	
	if(trigger.isAfter)
		CFAR_Budget_Utils.updateRateTableTotals(trialIds);	
}