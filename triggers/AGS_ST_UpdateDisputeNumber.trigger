trigger AGS_ST_UpdateDisputeNumber on AGS_ST_DisputeManagement_gne__c (before insert, before update, after insert, after update, after delete) {
    // updates Dispute Number on Spend Expense Transaction, this field is user for history tracking.
    // When dispute is corrected Dispute Number is being updated, which will display spend in external list for Newly Updated filter
    if(Trigger.isUpdate && Trigger.isAfter) { // After Update
        Set<String> transactions = new Set<String>();
        for(AGS_ST_DisputeManagement_gne__c dm: Trigger.New) {
            if(dm.Internal_Status_gne__c != Trigger.oldMap.get(dm.id).Internal_Status_gne__c && ('Corrected Pending SSR'.equals(dm.Internal_Status_gne__c) || 'Resolved With Correction'.equals(dm.Internal_Status_gne__c))) {
                if(!String.isBlank(dm.AGS_Spend_Expense_Transaction_gne__c))
                    transactions.add(dm.AGS_Spend_Expense_Transaction_gne__c);
            }
        }
        if(transactions.isEmpty())
            return;

        List<AGS_Spend_Expense_Transaction_gne__c> transList = [Select id, Dispute_Number_gne__c from AGS_Spend_Expense_Transaction_gne__c where id in: transactions];
        for(AGS_Spend_Expense_Transaction_gne__c tr : transList) {
            if(tr.Dispute_Number_gne__c == null)
                tr.Dispute_Number_gne__c = 0;
            else
                tr.Dispute_Number_gne__c = tr.Dispute_Number_gne__c + 1;
        }
        update transList;
    }

    // fetch CMS_Payment_ID_gne__c and Home_Payment_ID_gne__c from spend during insert and update
    List<Id> spendIds = new List<Id>();
    if( (Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore ) { // Before Insert, Before Update
        List<AGS_ST_DisputeManagement_gne__c> objsForChange = new List<AGS_ST_DisputeManagement_gne__c>();
        if(Trigger.isInsert) {
            for(AGS_ST_DisputeManagement_gne__c obj : Trigger.New) {
                if(obj.AGS_Spend_Expense_Transaction_gne__c != null) {
                    objsForChange.add(obj);
                    spendIds.add(obj.AGS_Spend_Expense_Transaction_gne__c);
                }
            }
        }
        if(Trigger.isUpdate) {
            for(AGS_ST_DisputeManagement_gne__c obj : Trigger.Old) {
                Id newSpendId = Trigger.newMap.get(obj.Id).AGS_Spend_Expense_Transaction_gne__c;
                if(newSpendId != null && obj.AGS_Spend_Expense_Transaction_gne__c != newSpendId) {
                    objsForChange.add(obj);
                    spendIds.add(newSpendId);
                }
            }
        }
        if( objsForChange.isEmpty() ) {
            return;
        }
        Map<Id, AGS_Spend_Expense_Transaction_gne__c> spendsMap = new Map<Id, AGS_Spend_Expense_Transaction_gne__c>(
            [SELECT Id, CMS_Payment_ID_gne__c, Home_Payment_ID_gne__c
            FROM AGS_Spend_Expense_Transaction_gne__c WHERE Id IN :spendIds]);
        for(AGS_ST_DisputeManagement_gne__c obj : objsForChange) {
            AGS_ST_DisputeManagement_gne__c objTemp = ( Trigger.isUpdate ? Trigger.newMap.get(obj.Id) : obj );
            AGS_Spend_Expense_Transaction_gne__c spend = spendsMap.get(objTemp.AGS_Spend_Expense_Transaction_gne__c);
            objTemp.CMS_Payment_ID_gne__c   = spend.CMS_Payment_ID_gne__c;
            objTemp.Home_Payment_ID_gne__c  = spend.Home_Payment_ID_gne__c;
        }
    }

    // Update Dispute Id NAME
    if(Trigger.isInsert && Trigger.isAfter) { // After Insert
    	spendIds.clear();
    	for(AGS_ST_DisputeManagement_gne__c obj : Trigger.New) {
    		spendIds.add(obj.AGS_Spend_Expense_Transaction_gne__c);
    	}
		Map<Id, AGS_Spend_Expense_Transaction_gne__c> spendsMapToUpdate = new Map<Id, AGS_Spend_Expense_Transaction_gne__c>(
		            [SELECT Id, DisputeID_gne__c FROM AGS_Spend_Expense_Transaction_gne__c WHERE Id IN :spendIds]);
		for(AGS_ST_DisputeManagement_gne__c obj : Trigger.New) {
			if(spendsMapToUpdate.get(obj.AGS_Spend_Expense_Transaction_gne__c) != null) {
			    spendsMapToUpdate.get(obj.AGS_Spend_Expense_Transaction_gne__c).DisputeID_gne__c = obj.Name;
			}
		}
		if(spendsMapToUpdate.values().size() > 0) {
		    update spendsMapToUpdate.values();
		}
    }

    // delete Dispute List
    if(Trigger.isDelete) {
        List<Id> disputeListIds = new List<Id>();
        for(AGS_ST_DisputeManagement_gne__c d : Trigger.Old) {
            if(d.Dispute_List_gne__c != null) {
                disputeListIds.add(d.Dispute_List_gne__c);
            }
        }
        if( !disputeListIds.isEmpty() ) {
            delete [ SELECT Id FROM AGS_ST_Dispute_List_gne__c WHERE Id IN :disputeListIds ];
        }
    }
}