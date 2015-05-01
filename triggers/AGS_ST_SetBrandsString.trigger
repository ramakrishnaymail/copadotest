trigger AGS_ST_SetBrandsString on AGS_Expense_Products_Interaction__c (after insert, after delete) {
    
    Set<String> spendIds = new Set<String>();
    if(Trigger.isInsert) {
        for(AGS_Expense_Products_Interaction__c prodInter : Trigger.new) {
            spendIds.add(prodInter.AGS_Spend_Expense_Transaction__c);
        }
    } else if(Trigger.isDelete) {
        for(AGS_Expense_Products_Interaction__c prodInter : Trigger.old) {
            spendIds.add(prodInter.AGS_Spend_Expense_Transaction__c);
        }
    }
    
    List<AGS_Expense_Products_Interaction__c> prodInteractions = [Select Id, AGS_Spend_Expense_Transaction__c, AGS_Brand_gne__c, AGS_Brand_gne__r.Brand_Name__c from AGS_Expense_Products_Interaction__c where AGS_Spend_Expense_Transaction__c in: spendIds order by AGS_Spend_Expense_Transaction__c, AGS_Brand_gne__r.Brand_Name__c];
    Map<Id, AGS_Spend_Expense_Transaction_gne__c> transactions = new Map<Id, AGS_Spend_Expense_Transaction_gne__c>([Select Id, Brands_gne__c from AGS_Spend_Expense_Transaction_gne__c where Id in: spendIds]);
    for(Id idValue : transactions.keySet()) {
        transactions.get(idValue).Brands_gne__c = '';
    }

    Map<Id, String> brandStrings = new Map<Id, String>();
    
    for(AGS_Expense_Products_Interaction__c prodInter : prodInteractions) {
        if(!brandStrings.containsKey(prodInter.AGS_Spend_Expense_Transaction__c)) 
            brandStrings.put(prodInter.AGS_Spend_Expense_Transaction__c, prodInter.AGS_Brand_gne__r.Brand_Name__c);
        else 
            brandStrings.put(prodInter.AGS_Spend_Expense_Transaction__c, brandStrings.get(prodInter.AGS_Spend_Expense_Transaction__c) + ',' + prodInter.AGS_Brand_gne__r.Brand_Name__c);        
    }
    
    for(Id prodInterId: brandStrings.keySet()) {
        transactions.get(prodInterId).Brands_gne__c = brandStrings.get(prodInterId);
    }
    
    if(transactions != null && !transactions.values().isEmpty())
        update transactions.values();
}