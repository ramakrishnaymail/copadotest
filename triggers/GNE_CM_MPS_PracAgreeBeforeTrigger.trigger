trigger GNE_CM_MPS_PracAgreeBeforeTrigger on GNE_CM_MPS_Practice_Agreement__c (before insert, before update) {
    Set<Id> userIdSet = new Set<Id>();
    Set<Id> registIdSet = new Set<Id>();
    Set<Id> prescIdSet = new Set<Id>();
      
    for(GNE_CM_MPS_Practice_Agreement__c mpsPracAgree: Trigger.new) {
        if(mpsPracAgree.MPS_Registration__c != null)
            registIdSet.add(mpsPracAgree.MPS_Registration__c);
        if(mpsPracAgree.MPS_User__c != null)
            userIdSet.add(mpsPracAgree.MPS_User__c);
        if(mpsPracAgree.MPS_Prescriber__c != null)
            prescIdSet.add(mpsPracAgree.MPS_Prescriber__c);
    }
    
    List<GNE_CM_MPS_Practice_Agreement__c> existMPSPracAgreeList = [Select Id, Name, Account__c, MPS_User__c, MPS_Registration__c, MPS_Prescriber__c from GNE_CM_MPS_Practice_Agreement__c where MPS_User__c IN:userIdSet or MPS_Registration__c IN: registIdSet or MPS_Prescriber__c IN: prescIdSet];
    
    for(GNE_CM_MPS_Practice_Agreement__c mpsPracAgree: Trigger.new) {
        //TODO Runtime Exception, existMPSPracAgreeList can be null or existMPSPracAgreeList.size() > 0
        for(GNE_CM_MPS_Practice_Agreement__c existMPSPracAgree:existMPSPracAgreeList) {
            //if(mpsPracAgree.Account__c == existMPSPracAgree.Account__c && (Trigger.isInsert || mpsPracAgree.Id != existMPSPracAgree.Id)) {
            if(Trigger.isInsert || mpsPracAgree.Id != existMPSPracAgree.Id) {
                if(mpsPracAgree.MPS_Registration__c == existMPSPracAgree.MPS_Registration__c && mpsPracAgree.MPS_User__c != null && mpsPracAgree.MPS_User__c == existMPSPracAgree.MPS_User__c) {
                    mpsPracAgree.addError('Account already mapped to the practice.');
                    break;
                }
            if(mpsPracAgree.Account__c == existMPSPracAgree.Account__c && (Trigger.isInsert || mpsPracAgree.Id != existMPSPracAgree.Id))    
                if(mpsPracAgree.MPS_Registration__c == existMPSPracAgree.MPS_Registration__c && mpsPracAgree.MPS_Prescriber__c != null && mpsPracAgree.MPS_Prescriber__c == existMPSPracAgree.MPS_Prescriber__c) {
                    mpsPracAgree.addError('Account already mapped to the practice.');
                    break;
                }
            }
        }
    }
}