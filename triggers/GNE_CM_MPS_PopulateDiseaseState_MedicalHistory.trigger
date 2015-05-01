trigger GNE_CM_MPS_PopulateDiseaseState_MedicalHistory on Medical_History_gne__c (before insert, before update) {
	
	set<ID> setICD9Id = new set<ID>();
	Map<ID ,String>	mapIcd9IdIdIcd9DiseaseState = new Map<ID ,String>();
	
	for(Medical_History_gne__c Med : trigger.new)
	{		
		if(Med.ICD9_Code_1_gne__c != null)
	      setICD9Id.add(Med.ICD9_Code_1_gne__c);
	}
	
	if(setICD9Id != null)
	{
	  List<ICD9_Code_gne__c> lstICD9 = [select id ,Disease_State_gne__c from ICD9_Code_gne__c where id in :setICD9Id];
	  if(lstICD9.size() > 0 && lstICD9 != null)
	   {
		  for(ICD9_Code_gne__c ICD : lstICD9)
		   {		   	
		     if(ICD.Disease_State_gne__c != null && ICD.Disease_State_gne__c != '')
		     	mapIcd9IdIdIcd9DiseaseState.put(ICD.Id , ICD.Disease_State_gne__c);
		   	}
		}	
	 }
		
	 for(Medical_History_gne__c Med : trigger.new)
	  {
	    if(mapIcd9IdIdIcd9DiseaseState.get(Med.ICD9_Code_1_gne__c) != null)
			if(Med.Disease_state_gne__c == null || Med.Disease_state_gne__c == '')
				Med.Disease_state_gne__c = mapIcd9IdIdIcd9DiseaseState.get(Med.ICD9_Code_1_gne__c);
	    
	  }	
}