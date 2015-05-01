/*------------      Name of trigger : GNE_CM_Insurance_trigger      --------------*/
/*------------      Created by : Ravinder Singh(GDC)               --------------*/
/*------------      Last Modified on :05/15/2008                   --------------*/
/*------------      Last Modified on :10/10/2008 (Vineet Kaul)     --------------*/
/*------------      Last Modified on :10/17/2008 (Shweta Bhardwaj)  --------------*/
/*------------      Lock down Insurance when case is closed for 48 hrs -----------*/

trigger GNE_CM_insurance_trigger on Insurance_gne__c (before insert, before update, after insert, after update)
{
   
    //skip this trigger if it is triggered from transfer wizard
	if (GNE_CM_MPS_TransferWizard.isDisabledTrigger || GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_insurance_trigger')) {
		return;
	}
	
	if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
		processBeforeInsertUpdate();
	}
		
	if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
		updateBenefitInvestigations();
	}
	
	private static void processBeforeInsertUpdate()
	{
		Set<Id> caseIds = new Set<Id>();
		Map<Id,Case> caseMap = new Map<Id,Case>();
		
		Set<String> caseProfiles = new Set<String>();
		String profileName = null;
		
		List<Environment_Variables__c> envVars = GNE_CM_Environment_variable.get_env_variable(new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'});
	    
	    try {
	    	//JH 10/21/2013 - SOQL Optimization
	        profileName = GNE_SFA2_Util.getCurrentUserProfileName();
	        Integer envVarsCount = envVars.size();
	        for (Integer i = 0; i < envVarsCount; i++) {
	        	if (envVars[i].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles') {
	        		caseProfiles.add(envVars[i].Value__c);
	        	}
	        }
	    }
	    catch (Exception e) {
	    	for (Insurance_gne__c ie : Trigger.new) {
	    		ie.adderror('Error encountered while getting Profile Name: ' + GlobalUtils.getExceptionDescription(e));
	    	}
	    }	    
	    
	    for (Insurance_gne__c ins : Trigger.new) {
	    	if (ins.Case_Insurance_gne__c != null) {
	    		caseIds.add(ins.Case_Insurance_gne__c);
	    	}
	    }
	    
	    try {
	        caseMap = new Map<Id,Case>([
	        	SELECT Id, Product_gne__c, Status, ClosedDate, Patient_gne__c,
	        		Patient_gne__r.Name, Patient_gne__r.pat_first_name_gne__c, Patient_gne__r.pat_dob_gne__c, Patient_gne__r.ssn_gne__c 
	        	FROM Case
	        	WHERE Id IN :caseIds
	        ]);
	    }
	    catch (Exception e) {
	        for (Insurance_gne__c ie : Trigger.new) {
	        	ie.adderror('Error encountered in SOQL' + GlobalUtils.getExceptionDescription(e));
	        }
	    }
	    
	    //KS 9/28/2011 : Populating the value of SSN & DOBon insurance from related Patient rec.
	    for (Insurance_gne__c ins : Trigger.new) {
	        try {
	            if (ins.Case_Insurance_gne__c != null && caseMap.containsKey(ins.Case_Insurance_gne__c)) {
	                ins.Product_Insurance_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Product_gne__c;
	                ins.Patient_Insurance_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Patient_gne__c;
	                if (ins.Patient_Relationship_to_Subscriber_gne__c == 'Self' /*&& caseMap.get(ins.Case_Insurance_gne__c).Status == 'Active'*/) {
	                	if ((Trigger.isInsert && (ins.Subscriber_Name_gne__c == null || ins.Subscriber_Name_gne__c.trim() == ''))
	                		|| (Trigger.isUpdate && Trigger.oldMap.get(ins.Id).Patient_Relationship_to_Subscriber_gne__c != 'Self')
	                	) {
	                		ins.Subscriber_Name_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Patient_gne__r.Name;	
	                	}
	                	if ((Trigger.isInsert && (ins.Subscriber_First_Name_gne__c == null || ins.Subscriber_First_Name_gne__c.trim() == ''))
	                		|| (Trigger.isUpdate && Trigger.oldMap.get(ins.Id).Patient_Relationship_to_Subscriber_gne__c != 'Self')
	                	) {
	                		ins.Subscriber_First_Name_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Patient_gne__r.pat_first_name_gne__c;
	                	}
	                	if ((Trigger.isInsert && ins.Subscriber_DOB_gne__c == null)
	                		|| (Trigger.isUpdate && Trigger.oldMap.get(ins.Id).Patient_Relationship_to_Subscriber_gne__c != 'Self')
	                	) {
	                		ins.Subscriber_DOB_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Patient_gne__r.pat_dob_gne__c;
	                	}
	                	if ((Trigger.isInsert && (ins.ssn_gne__c == null || ins.ssn_gne__c.trim() == ''))
	                		|| (Trigger.isUpdate && Trigger.oldMap.get(ins.Id).Patient_Relationship_to_Subscriber_gne__c != 'Self')) {
	                		ins.ssn_gne__c = caseMap.get(ins.Case_Insurance_gne__c).Patient_gne__r.ssn_gne__c;
	                	}
	                }
	                //Do not allow user to create or edit Insurance when associated case has been closed for 48 hours
	                if (!caseProfiles.contains(profileName) && caseMap.get(ins.Case_Insurance_gne__c).Status.startsWith('Closed') && system.now() >= (caseMap.get(ins.Case_Insurance_gne__c).ClosedDate.addDays(2))) {
	                    ins.adderror('Insurance cannot be created/edited once the associated case has been Closed for 48 hours or more.');
	                }
	            }
	        }
	        catch (Exception e) {
	            ins.adderror('Error encountered while filling patient and product information in Insurance');
	        }
	    }
	    
	    // GDC - 8/4/2011 Code added to populate As (Rank) field on BI from Insurance.
	    /*
	    //wilczekk: code commented out per EBI-25
	    if (Trigger.isUpdate) {
	        List<Benefit_Investigation_gne__c> bi = [SELECT Id, As_Rank_gne__c FROM Benefit_Investigation_gne__c WHERE BI_Insurance_gne__c = :Trigger.old[0].Id];
	        List<Benefit_Investigation_gne__c> updatebilist = new List<Benefit_Investigation_gne__c>();
	        try {
	            for (Insurance_gne__c ins : Trigger.new) {
	                for (Integer i = 0; i < bi.size(); i++) {
	                    if (ins.Rank_gne__c != null || ins.Rank_gne__c != '' ) {
	                        bi[i].As_Rank_gne__c = ins.Rank_gne__c;
	                        updatebilist.add(bi[i]);
	                    }
	                }
	            }
	            update updatebilist;
	        }
	        catch (Exception e) {
	            system.debug('Error: ' + GlobalUtils.getExceptionDescription(e));
	            GNE_CM_MPS_Utils.insertError('GNE_CM_insurance_trigger', 'Medium', 'GNE_CM_insurance_trigger', 'Trigger', 'Error updating benefit investigations: ' + GlobalUtils.getExceptionDescription(e));
	        }
	    }
	    */
   	} 
   	
   	private static void updateBenefitInvestigations()
   	{
   		Map<Id,Insurance_gne__c> changedInsurancesMap = new Map<Id, Insurance_gne__c>();
   		if (trigger.old == null || trigger.old.size() == 0) {
   			changedInsurancesMap = trigger.newMap;
   		} else {
   			for (integer i = 0; i < trigger.new.size(); i++) {
   				if ((trigger.new[i].Payer_gne__c != trigger.old[i].Payer_gne__c) ||
   					(trigger.new[i].Plan_gne__c != trigger.old[i].Plan_gne__c)) {
   					changedInsurancesMap.put(trigger.new[i].id, trigger.new[i]);
   				}
   			}
   		}
   		system.debug('twardoww: changedInsurancesMap: ' + changedInsurancesMap);
   		List<Benefit_Investigation_gne__c> bis = [
   			SELECT Id, Name, Payer_BI_gne__c, Plan_Plan_Product_lookup_gne__c, BI_Insurance_gne__c
	   		FROM Benefit_Investigation_gne__c
	   		WHERE BI_Insurance_gne__c in :changedInsurancesMap.values() 
	   	];
	   	system.debug('twardoww: BIS for changedInsurancesMap: ' + changedInsurancesMap);
	   	Set<Benefit_Investigation_gne__c> changedBis = new Set<Benefit_Investigation_gne__c>();
	   	for (Benefit_Investigation_gne__c theBi : bis ) {
	   		Insurance_gne__c theChangedInsurance = changedInsurancesMap.get(theBi.BI_Insurance_gne__c);
	   		if ((theBi.Payer_BI_gne__c != theChangedInsurance.Payer_gne__c) ||
	   			theBi.Plan_Plan_Product_lookup_gne__c != theChangedInsurance.Plan_gne__c) {
	   			system.debug('twardoww: updating Payer_BI_gne__c for BI Id: ' + theBi.Id + ' from: ' + theBi.Payer_BI_gne__c + ' to: ' + theChangedInsurance.Payer_gne__c);
	   			theBi.Payer_BI_gne__c = theChangedInsurance.Payer_gne__c;
	   			theBi.Plan_Plan_Product_lookup_gne__c = theChangedInsurance.Plan_gne__c;
	   			changedBis.add(theBi);
	   		}
	   	}
	   	List<Benefit_Investigation_gne__c> changedBisList = new List<Benefit_Investigation_gne__c>(changedBis);
	   	
	   	//workaround for too many soql queries 
	   	GNE_SFA2_Util.setSkipTriggersOnlyInTests( false );
		GNE_SFA2_Util.skipTrigger( 'GNE_CM_caseID_prepopulate' );
				
			update changedBisList;
		
		GNE_SFA2_Util.setSkipTriggersOnlyInTests ( true );
		GNE_SFA2_Util.stopSkipingTrigger( 'GNE_CM_caseID_prepopulate' );		
	}
}