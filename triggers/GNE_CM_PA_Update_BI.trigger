trigger GNE_CM_PA_Update_BI on Prior_Authorization_gne__c (after insert, after update) {
   	// SFA2 bypass. Please not remove!
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_PA_Update_BI')) {
        return;
    }	

	Map<String,Prior_Authorization_gne__c> mapPAByBI=new Map<String,Prior_Authorization_gne__c>();
	
	for (Prior_Authorization_gne__c pa : trigger.new)
	{
		if (pa.Benefit_Investigation_gne__c!=null)
		{
			mapPAByBI.put(pa.Benefit_Investigation_gne__c, pa);
		}
	}

	List<Benefit_Investigation_gne__c> lstBIs=[SELECT Id, Retroactive_gne__c FROM Benefit_Investigation_gne__c WHERE Id IN :mapPAByBI.keyset()];
	
	for (Benefit_Investigation_gne__c bi : lstBIs)
	{
		if (mapPAByBI.containsKey(bi.Id))
		{
			bi.Retroactive_gne__c=mapPAByBI.get(bi.Id).Retroactive_gne__c;
		}
	}
	
	update lstBIs;
}