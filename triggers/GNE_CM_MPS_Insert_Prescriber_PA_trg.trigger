trigger GNE_CM_MPS_Insert_Prescriber_PA_trg on GNE_CM_MPS_Prescriber__c (after insert) {

    List<GNE_CM_MPS_Practice_Agreement__c> tobeInsertedPA =new List<GNE_CM_MPS_Practice_Agreement__c>();
    List<GNE_CM_MPS_Practice_Agreement__c> tobeUpdatedPA =new List<GNE_CM_MPS_Practice_Agreement__c>();

              
        //trigger.New size has to be 1
        if(trigger.New != null && trigger.New.size() != 1) {
        	return;
        }
        
        //We do have SOQL in forloop so we have to make sure in data loader -> settings the Batch size is 1 or less than 100 
        for(GNE_CM_MPS_Prescriber__c prescriber :trigger.New)
        {
        
            if(prescriber.Is_Migrated__c == false || prescriber.Mapped_Account__c == null) {
                continue;
            }      

			GNE_CM_MPS_Practice_Agreement__c pa = null;
			
			try {
				pa = [SELECT Id, Name, Account__c, MPS_User__c, MPS_Prescriber__c, MPS_Registration__c FROM GNE_CM_MPS_Practice_Agreement__c 
				  where MPS_Registration__c = :prescriber.GNE_CM_MPS_Registration__c and Account__c = :prescriber.Mapped_Account__c limit 1];
			} catch(QueryException ex) {
				//We can ignore this actually. No need to even log to errorlog as it is expected
			}
			  
			if(pa == null) {
	            GNE_CM_MPS_Practice_Agreement__c agreement =new GNE_CM_MPS_Practice_Agreement__c();
	            agreement.Account__c = prescriber.Mapped_Account__c;
	            agreement.Is_Prescriber__c =true;
	            agreement.MPS_Registration__c = prescriber.GNE_CM_MPS_Registration__c;
	            agreement.MPS_Prescriber__c =prescriber.Id;
	            tobeInsertedPA.add(agreement);
			} else {
				pa.Is_Prescriber__c =true;		
				pa.MPS_Prescriber__c =prescriber.Id;	
				tobeUpdatedPA.add(pa);
			}
        }
        
        
        if(tobeInsertedPA !=null && tobeInsertedPA.size() > 0)
        {
            insert tobeInsertedPA;
        }

        if(tobeUpdatedPA !=null && tobeUpdatedPA.size() > 0)
        {
            update tobeUpdatedPA;
        }

}