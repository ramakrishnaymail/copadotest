trigger GNE_CM_MPS_Update_PracticeAgreementLoc_trg on GNE_CM_MPS_Location__c (after update) {
  Set<Id> locationIdTrue   = new  Set<Id>();
  Set<Id> locationIdFalse   = new  Set<Id>();
  List<GNE_CM_MPS_Practice_Agreement_Location__c> lstPractToUpdate = new  List<GNE_CM_MPS_Practice_Agreement_Location__c>();
  for(GNE_CM_MPS_Location__c loc : trigger.new)
  {
    if(loc.Disabled__c != trigger.oldMap.get(loc.id).Disabled__c)
    {
      if(loc.Disabled__c == True)
        locationIdTrue.add(loc.id);
      else if(loc.Disabled__c == null || loc.Disabled__c == False)
        locationIdFalse.add(loc.id);
    }
  }
  
  if(locationIdTrue != null && locationIdTrue.size() > 0)
  {
    Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c> mapPractAgrrTrue = new Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c>([Select id,Prescriber_Location_Disabled_gne__c from GNE_CM_MPS_Practice_Agreement_Location__c where MPS_Location__c in : locationIdTrue]);
    if(mapPractAgrrTrue != null && mapPractAgrrTrue.size() > 0)
    {
      for(Id practId : mapPractAgrrTrue.keySet())
      {
        GNE_CM_MPS_Practice_Agreement_Location__c objPract = mapPractAgrrTrue.get(practId);
        objPract.Prescriber_Location_Disabled_gne__c = true;
        lstPractToUpdate.add(objPract);
      }
    }
  }
  if(locationIdFalse != null && locationIdFalse.size() > 0)
  {
    Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c> mapPractAgrrFalse = new Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c>([Select id,Prescriber_Location_Disabled_gne__c from GNE_CM_MPS_Practice_Agreement_Location__c where MPS_Location__c in : locationIdFalse]);
    if(mapPractAgrrFalse != null && mapPractAgrrFalse.size() > 0)
    {
      for(Id practId : mapPractAgrrFalse.keySet())
      {
        GNE_CM_MPS_Practice_Agreement_Location__c objPract = mapPractAgrrFalse.get(practId);
        objPract.Prescriber_Location_Disabled_gne__c = false;
        lstPractToUpdate.add(objPract);
      }
    }
  }
  if(lstPractToUpdate != null && lstPractToUpdate.size() > 0)
  {
    update lstPractToUpdate;
  }
}