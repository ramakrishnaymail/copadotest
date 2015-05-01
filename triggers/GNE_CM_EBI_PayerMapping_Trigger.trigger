trigger GNE_CM_EBI_PayerMapping_Trigger on GNE_CM_EBI_Payer_Mapping__c (before delete, after delete, before insert, after insert, before update, after update) 
{
    if (GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_EBI_PayerMapping_Trigger')) {
        System.debug('Skipping trigger GNE_CM_EBI_PayerMapping_Trigger');
        return;
    }
        
    List<Account> accounts = new List<Account>();
        
    if (Trigger.isInsert)
    {
        Set<Id> accIds = new Set<Id>();
        for (GNE_CM_EBI_Payer_Mapping__c pm : Trigger.new) 
        {
            if (accIds.contains(pm.Account_gne__c))
            {
                throw new GNE_CM_Exception('Mappings cannot be inserted because there are duplicate mappings for account ID ' + pm.Account_gne__c);
            }
            accIds.add(pm.Account_gne__c);
        }       

        if (Trigger.isBefore)
        {
            // We want to prevent creation of two mappings for the same account. Since Account field is a lookup, is cannot
            // be made unique and we need to handle this in the trigger.        
            List<GNE_CM_EBI_Payer_Mapping__c> existingMappings = [SELECT Account_gne__c FROM GNE_CM_EBI_Payer_Mapping__c WHERE Account_gne__c IN :accIds];
            
            if (!existingMappings.isEmpty())
            {
                throw new GNE_CM_Exception('Mapping(s) cannot be inserted because some of the accounts are already mapped. Mapped accounts are: ' + existingMappings);
            }
        }
    
        if (Trigger.isAfter)
        {
            accounts = [select Id, ebiPayer_gne__c from Account where Id IN :accIds];
            
            for (Account a : accounts)
            {
                a.ebiPayer_gne__c = true;
            }
        }
    }
    
    if (Trigger.isUpdate && Trigger.isAfter)
    {
        Map<Id,GNE_CM_EBI_Payer_Mapping__c> pMapOld = Trigger.oldMap;
        Map<Id,GNE_CM_EBI_Payer_Mapping__c> pMapNew = Trigger.newMap;
        Set<Id> accOldId = new Set<Id>();
        Set<Id> accNewId = new Set<Id>();
        List<Id> accToRemove = new List<Id>();
        List<Id> accToAdd = new List<Id>();
        
        for (Id i: pMapOld.keySet()) 
        {
            accOldId.add(pMapOld.get(i).Account_gne__c);
            accNewId.add(pMapNew.get(i).Account_gne__c);
        }
        
        for (Id i: accOldId)
        {
            if (!accNewId.contains(i))
            {
                accToRemove.add(i);
            }
        }
        for (Id i: accNewId)
        {
            if (!accOldId.contains(i))
            {
                accToAdd.add(i);
            }
        }
        
        List<Account> accConnected = [select ebiPayer_gne__c from Account where Id IN :accToAdd];
        List<Account> accDisconnected = [select ebiPayer_gne__c from Account where Id IN :accToRemove];
        
        for (Account a : accConnected)
        {
            a.ebiPayer_gne__c = true;
            accounts.add(a);
        }
        for (Account a : accDisconnected)
        {
            a.ebiPayer_gne__c = false;
            accounts.add(a);
        }
    }
    
    if (Trigger.isDelete && Trigger.isAfter)
    {
        List<Id> accIds = new List<Id>();
        for (GNE_CM_EBI_Payer_Mapping__c pm : Trigger.old) 
        {
            accIds.add(pm.Account_gne__c);
        }       
        
        accounts = [select Id, ebiPayer_gne__c from Account where Id IN :accIds];
        
        for (Account a : accounts)
        {
            a.ebiPayer_gne__c = false;
        }
    }
    
    update accounts;
}