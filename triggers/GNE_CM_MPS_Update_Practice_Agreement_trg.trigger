trigger GNE_CM_MPS_Update_Practice_Agreement_trg on GNE_CM_MPS_Prescriber__c (after update) {
  
  Set<Id> regIdTrue   = new  Set<Id>();
  Set<Id> prescIdTrue = new  Set<Id>();
  Set<Id> regIdFalse   = new  Set<Id>();
  Set<Id> prescIdFalse = new  Set<Id>();
  Set<Id> PractAgreeIdTrue = new  Set<Id>();
  Set<Id> PractAgreeIdFalse = new  Set<Id>();
  List<GNE_CM_MPS_Practice_Agreement__c> lstPractAgrTrue = new List<GNE_CM_MPS_Practice_Agreement__c>();
  List<GNE_CM_MPS_Practice_Agreement__c> lstPractAgrFalse = new List<GNE_CM_MPS_Practice_Agreement__c>();
  
  List<GNE_CM_MPS_Practice_Agreement_Location__c> lstPractToUpdate = new  List<GNE_CM_MPS_Practice_Agreement_Location__c>();

  for(GNE_CM_MPS_Prescriber__c presc : trigger.new)
  {
    if(presc.Disabled__c != trigger.oldMap.get(presc.id).Disabled__c)
    {
       if(presc.Disabled__c == True)
       {
         if(presc.GNE_CM_MPS_Registration__c != null)
           regIdTrue.add(presc.GNE_CM_MPS_Registration__c);
         prescIdTrue.add(presc.id);  
       } 
       else if(presc.Disabled__c == null || presc.Disabled__c == False)
       {
         if(presc.GNE_CM_MPS_Registration__c != null)
           regIdFalse.add(presc.GNE_CM_MPS_Registration__c);
         prescIdFalse.add(presc.id);  
       }
    }
  }
  if(regIdTrue != null && regIdTrue.size() > 0 && prescIdTrue != null && prescIdTrue.size() > 0)
  {
    lstPractAgrTrue = [Select id,Name from GNE_CM_MPS_Practice_Agreement__c where MPS_Prescriber__c in :prescIdTrue and MPS_Registration__c in :regIdTrue];
    if(lstPractAgrTrue != null && lstPractAgrTrue.size() > 0)
    {
      for(GNE_CM_MPS_Practice_Agreement__c pract : lstPractAgrTrue)
      {
        PractAgreeIdTrue.add(pract.id);
      }
    }
  }
  if(regIdFalse != null && regIdFalse.size() > 0 && prescIdFalse != null && prescIdFalse.size() > 0)
  {
    lstPractAgrFalse = [Select id,Name from GNE_CM_MPS_Practice_Agreement__c where MPS_Prescriber__c in :prescIdFalse and MPS_Registration__c in :regIdFalse];
    if(lstPractAgrFalse != null && lstPractAgrFalse.size() > 0)
    {
      for(GNE_CM_MPS_Practice_Agreement__c pract : lstPractAgrFalse)
      {
        PractAgreeIdFalse.add(pract.id);
      }
    }
  }
  Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c> mapPractAgrrTrue = new Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c>([Select id,Prescriber_Location_Disabled_gne__c from GNE_CM_MPS_Practice_Agreement_Location__c where MPS_Practice_Agreement__c in : PractAgreeIdTrue]);
  Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c> mapPractAgrrFalse = new Map<Id,GNE_CM_MPS_Practice_Agreement_Location__c>([Select id,Prescriber_Location_Disabled_gne__c from GNE_CM_MPS_Practice_Agreement_Location__c where MPS_Practice_Agreement__c in : PractAgreeIdFalse]);
  
  if(mapPractAgrrTrue != null && mapPractAgrrTrue.size() > 0)
  {
    for(Id practId : mapPractAgrrTrue.keySet())
    {
      GNE_CM_MPS_Practice_Agreement_Location__c objPract = mapPractAgrrTrue.get(practId);
      objPract.Prescriber_Location_Disabled_gne__c = true;
      lstPractToUpdate.add(objPract);
    }
  }
  if(mapPractAgrrFalse != null && mapPractAgrrFalse.size() > 0)
  {
    for(Id practId : mapPractAgrrFalse.keySet())
    {
      GNE_CM_MPS_Practice_Agreement_Location__c objPract = mapPractAgrrFalse.get(practId);
      objPract.Prescriber_Location_Disabled_gne__c = false;
      lstPractToUpdate.add(objPract);
    }
  }
  
  if(lstPractToUpdate != null && lstPractToUpdate.size() > 0)
  {
    update lstPractToUpdate;
  }
}