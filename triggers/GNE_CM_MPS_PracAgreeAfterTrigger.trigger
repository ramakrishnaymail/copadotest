//Test Class: GNE_CM_MPS_PopulateMappedAccountTest

trigger GNE_CM_MPS_PracAgreeAfterTrigger on GNE_CM_MPS_Practice_Agreement__c (after insert, after update, after delete) {
    Set<Id> allMPSPresSet = new Set<Id>();
    Set<Id> mpsUsersWithAccountsToRemove = new Set<Id>();
    Set<Id> mpsPresWithAccountsToRemove = new Set<Id>();
    Map<Id, Id> mpsUsersWithAccountsToAdd = new Map<Id, Id>();
    Map<Id, Id> mpsPresWithAccountsToAdd = new Map<Id, Id>();
    
    if(Trigger.isDelete) 
    {
        for(GNE_CM_MPS_Practice_Agreement__c pracAgree: Trigger.old) {
            if(pracAgree.MPS_Prescriber__c != null) {
                allMPSPresSet.add(pracAgree.MPS_Prescriber__c);
            }
            
            if(pracAgree.MPS_User__c != null)
            {
            	mpsUsersWithAccountsToRemove.add(pracAgree.MPS_User__c);
            }
            
            if(pracAgree.MPS_Prescriber__c != null)
            {
            	mpsPresWithAccountsToRemove.add(pracAgree.MPS_Prescriber__c);
            }            
        }
        GNE_CM_MPS_PopulateMappedAccount.removeMappedAccounts(mpsUsersWithAccountsToRemove);
        GNE_CM_MPS_PopulateMappedAccount.removeMappedAccountsPrescribers(mpsPresWithAccountsToRemove);
    } 
    else 
    {
        for(Integer index=0;index < Trigger.new.size(); index++) {
            GNE_CM_MPS_Practice_Agreement__c newPracAgree = Trigger.new[index];
            
            if(newPracAgree.MPS_Prescriber__c != null) {
                allMPSPresSet.add(newPracAgree.MPS_Prescriber__c);
            }
            if(Trigger.isUpdate) {
                GNE_CM_MPS_Practice_Agreement__c oldPracAgree = Trigger.old[index];
                if(oldPracAgree.MPS_Prescriber__c != null) {
                    allMPSPresSet.add(oldPracAgree.MPS_Prescriber__c);
                }   
            }
            
            if(newPracAgree.MPS_User__c != null)
            {
            	mpsUsersWithAccountsToAdd.put(newPracAgree.MPS_User__c, newPracAgree.Account__c);
            }
            
            if(newPracAgree.MPS_Prescriber__c != null)
            {
            	mpsPresWithAccountsToAdd.put(newPracAgree.MPS_Prescriber__c, newPracAgree.Account__c);
            }
        }
        GNE_CM_MPS_PopulateMappedAccount.addMappedAccounts(mpsUsersWithAccountsToAdd);
        GNE_CM_MPS_PopulateMappedAccount.addMappedAccountsPrescribers(mpsPresWithAccountsToAdd);
    }
    
    if(allMPSPresSet.size() > 0) {
         List<GNE_CM_MPS_Practice_Agreement__c> pracAgreeList = [Select Id, MPS_Prescriber__c from GNE_CM_MPS_Practice_Agreement__c where MPS_Prescriber__c IN: allMPSPresSet]; 
         List<GNE_CM_MPS_Prescriber__c> mpsPresList = [Select Id, Mapped_to_PA__c from GNE_CM_MPS_Prescriber__c where Id IN: allMPSPresSet]; 
         Map<Id, Id> pracAgreeMPSPresMap = new Map<Id, Id>();
         //List<GNE_CM_MPS_Prescriber__c> finalMPSPracList = new List<GNE_CM_MPS_Prescriber__c>();
         //TODO Runtime Exception, pracAgreeList not null and size() > 0
         for(GNE_CM_MPS_Practice_Agreement__c pracAgree: pracAgreeList) {
             pracAgreeMPSPresMap.put(pracAgree.MPS_Prescriber__c, pracAgree.Id);
         }
         
         //TODO Runtime Exception, mpsPresList not null and size() > 0
         for(GNE_CM_MPS_Prescriber__c mpsPres: mpsPresList) {
             if(pracAgreeMPSPresMap.get(mpsPres.Id) != null) {
                 mpsPres.Mapped_to_PA__c = true;
             } else {
                 mpsPres.Mapped_to_PA__c = false;
             }
         }
         
         update mpsPresList;
    }
}