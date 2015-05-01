/*
*@Author: Konrad Russa
*@Created: 30-10-2013
*/

//FIXME: should be under button not as triggered logic
trigger CFAR_Budget_Contract_TrackingTrigger on CFAR_Budget_Contract_Tracking_gne__c (before insert, before update, after insert, after update) {
	if(!CFAR_Budget_Utils.hasAlreadyProcessedTracking()) {
		CFAR_Utils.increaseHowManyProcessedCTTrigger();
		System.debug('Slawek DBG how many trigger processing: ' + CFAR_Utils.howManyProcessedCTTrigger);
		
		Map<Id, String> typeMap = CFAR_Utils.getContractTypeMap();
		
		set<String> types = new set<String>();
		types.addAll(CFAR_Budget_Utils.getOrginalAndAmendmentTypeNames());
		types.add(CFAR_Budget_Controller.CONTRACT_TRACKING_ADJUSTMENT_TYPE);
		types.add(CFAR_Budget_Controller.CONTRACT_TRACKING_PLANNED_TYPE);
		
		if(trigger.isBefore) {
			set<String> trials = CFAR_Utils.fetchSet(trigger.new, 'CFAR_Trial_ref_gne__c');
			
			
			
			Map<Id, CFAR_Budget_Contract_Tracking_gne__c> lastContractForTrial = new Map<Id, CFAR_Budget_Contract_Tracking_gne__c>();
			List<CFAR_Budget_Contract_Tracking_gne__c> listOfContracts = [select Id, Amount_gne__c, CreatedDate, CFAR_Trial_ref_gne__c 
																		from CFAR_Budget_Contract_Tracking_gne__c 
																		where frm_Type_gne__c in :types and CFAR_Trial_ref_gne__c in :trials 
																		order by CreatedDate desc];
																		
			for(CFAR_Budget_Contract_Tracking_gne__c c : listOfContracts) {
				if(!lastContractForTrial.containsKey(c.CFAR_Trial_ref_gne__c)) {
					lastContractForTrial.put(c.CFAR_Trial_ref_gne__c, c);
				}
			}
			
			for(CFAR_Budget_Contract_Tracking_gne__c c : trigger.new) {
				Boolean isRight = //typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_INCREASE_TYPE 
					//|| typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_DECREASE_TYPE
					CFAR_Budget_Utils.getOrginalAndAmendmentTypeNames().contains(typeMap.get(c.Type_ref_gne__c))
					|| typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_ADJUSTMENT_TYPE
					|| typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_PLANNED_TYPE;
				
				if(isRight) {
					//Decimal lastAmendment = 0;
					Decimal lastAmendment = null;
					if(trigger.isInsert) {
						if (lastContractForTrial.containsKey(c.CFAR_Trial_ref_gne__c)) {
							lastAmendment = ((CFAR_Budget_Contract_Tracking_gne__c)lastContractForTrial.get(c.CFAR_Trial_ref_gne__c)).Amount_gne__c;
						}
					} else {
						for(CFAR_Budget_Contract_Tracking_gne__c t : listOfContracts) {
							if(c.CFAR_Trial_ref_gne__c == t.CFAR_Trial_ref_gne__c && t.CreatedDate < c.CreatedDate) {
								lastAmendment = t.Amount_gne__c;
								break;
							}
						}
					}
					if (lastAmendment != null) {
						c.Variance_gne__c = c.Amount_gne__c - lastAmendment;
					}
				}
			}
		}

		if(trigger.isAfter) {
			set<String> allTrialIds = CFAR_Utils.fetchSet(trigger.new, 'CFAR_Trial_ref_gne__c');
			
			/**
			Map<Id, AggregateResult> lastContractTracking = new Map<Id, AggregateResult>([select CFAR_Trial_ref_gne__c Id, 
				max(CreatedDate) created from CFAR_Budget_Contract_Tracking_gne__c where CFAR_Trial_ref_gne__c in :allTrialIds 
					group by CFAR_Trial_ref_gne__c]);
			*/
			
			Set<String> expTypes = new Set<String> {CFAR_Budget_Controller.CONTRACT_TRACKING_ORGINAL_TYPE, CFAR_Budget_Controller.CONTRACT_TRACKING_ADJUSTMENT_TYPE};
			expTypes.addAll(CFAR_Budget_Utils.getAmendmentTypeNames());
			
			//Map<Id, AggregateResult> lastExpContractTracking = new Map<Id, AggregateResult>([select CFAR_Trial_ref_gne__c Id, 
			//	max(Contract_Expiry_Date_gne__c) exp from CFAR_Budget_Contract_Tracking_gne__c where CFAR_Trial_ref_gne__c in :allTrialIds and Contract_Expiry_Date_gne__c != null and Type_ref_gne__r.Name in :expTypes
			//		group by CFAR_Trial_ref_gne__c]);
			
			/**
			Map<Id, AggregateResult> lastExpContractTracking = new Map<Id, AggregateResult>([select CFAR_Trial_ref_gne__c Id, Contract_Expiry_Date_gne__c from CFAR_Budget_Contract_Tracking_gne__c 
			where CFAR_Trial_ref_gne__c in :allTrialIds and Contract_Expiry_Date_gne__c != null and Type_ref_gne__r.Name in :expTypes group by CFAR_Trial_ref_gne__c,Contract_Expiry_Date_gne__c order by CFAR_Trial_ref_gne__c, min(LastModifiedDate) DESC Limit 1]);
			*/
			List<AggregateResult> lastExpContractTrackingList = [select CFAR_Trial_ref_gne__c, Contract_Expiry_Date_gne__c from CFAR_Budget_Contract_Tracking_gne__c 
																 where CFAR_Trial_ref_gne__c in :allTrialIds and Contract_Expiry_Date_gne__c != null and Type_ref_gne__r.Name in :expTypes group by CFAR_Trial_ref_gne__c,Contract_Expiry_Date_gne__c order by CFAR_Trial_ref_gne__c, max(LastModifiedDate) DESC];
			Map<Id, AggregateResult> lastExpContractTracking = new Map<Id, AggregateResult>();
			for (AggregateResult ar : lastExpContractTrackingList) {
				if (lastExpContractTracking.containsKey(Id.valueOf(String.valueOf(ar.get('CFAR_Trial_ref_gne__c'))))) {
					continue;
				}
				lastExpContractTracking.put(Id.valueOf(String.valueOf(ar.get('CFAR_Trial_ref_gne__c'))), ar);
			}
			
			map<Id, Date> trialWithEndDate = new map<Id, Date>();
			//map<Id, Date> trialWithExpDate = new map<Id, Date>();
			map<Id, Date> trialWithExecutionDate = new map<Id, Date>();
			map<Id, Decimal> trialWithLastAmendment = new map<Id, Decimal>();
			
			list<CFAR_Budget_CPS_Projection_gne__c> trialProjectionsForInsert = new list<CFAR_Budget_CPS_Projection_gne__c>();
			
			list<CFAR_Budget_Contract_Tracking_gne__c> orginalTrackingToProjections = new list<CFAR_Budget_Contract_Tracking_gne__c>();
			
			//list<CFAR_Budget_Contract_Tracking_gne__c> trackingAffectedProjections = new list<CFAR_Budget_Contract_Tracking_gne__c>();
			set<Id> trackingAffectedProjectionsTrialIdx = new set<Id>();
			set<Id> trialsIdx = new set<Id>();
			Set<Id> trialIdxForPlanned = new Set<Id>();
			
			for(CFAR_Budget_Contract_Tracking_gne__c c : trigger.new) {
				
				Boolean isOrginal = typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_ORGINAL_TYPE;
				Boolean isAmendmentOrAdjustment = CFAR_Budget_Utils.getAmendmentTypeNames().contains(typeMap.get(c.Type_ref_gne__c))
					|| typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_ADJUSTMENT_TYPE;
				Boolean isPlanned = typeMap.get(c.Type_ref_gne__c) == CFAR_Budget_Controller.CONTRACT_TRACKING_PLANNED_TYPE;
					
				if(isOrginal || isAmendmentOrAdjustment)
					trialsIdx.add(c.CFAR_Trial_ref_gne__c);
					
				if (isPlanned) {
					trialIdxForPlanned.add(c.CFAR_Trial_ref_gne__c);
				}
				
				Boolean afterUpdate = c.Amount_gne__c != null
							&& c.Contract_Expiry_Date_gne__c != null 
							&& c.Fully_Executed_Date_gne__c != null && trigger.isUpdate && (Trigger.oldMap.get(c.Id).Amount_gne__c != Trigger.newMap.get(c.Id).Amount_gne__c
												 || Trigger.oldMap.get(c.Id).Contract_Expiry_Date_gne__c != Trigger.newMap.get(c.Id).Contract_Expiry_Date_gne__c
												 || Trigger.oldMap.get(c.Id).Fully_Executed_Date_gne__c != Trigger.newMap.get(c.Id).Fully_Executed_Date_gne__c
												 || typeMap.get(Trigger.oldMap.get(c.Id).Type_ref_gne__c) != typeMap.get(Trigger.newMap.get(c.Id).Type_ref_gne__c));
				
				Boolean baseCondition = c.Amount_gne__c != null
							&& c.Contract_Expiry_Date_gne__c != null 
							&& c.Fully_Executed_Date_gne__c != null
							&& (trigger.isInsert || Trigger.oldMap.get(c.Id).Amount_gne__c == null
												 || Trigger.oldMap.get(c.Id).Contract_Expiry_Date_gne__c == null
												 || Trigger.oldMap.get(c.Id).Fully_Executed_Date_gne__c == null
												 || afterUpdate);
				
				if(isOrginal && c.Fully_Executed_Date_gne__c != null 
					&& (trigger.isInsert || Trigger.oldMap.get(c.Id).Fully_Executed_Date_gne__c == null 
						|| Trigger.oldMap.get(c.Id).Fully_Executed_Date_gne__c != Trigger.newMap.get(c.Id).Fully_Executed_Date_gne__c  
						|| Trigger.oldMap.get(c.Id).Type_ref_gne__c != Trigger.newMap.get(c.Id).Type_ref_gne__c)) {
					trialWithExecutionDate.put(c.CFAR_Trial_ref_gne__c, c.Fully_Executed_Date_gne__c);
				}
				// CFAR-463
				if(lastExpContractTracking.containsKey(c.CFAR_Trial_ref_gne__c) && (isOrginal || isAmendmentOrAdjustment) && c.Contract_Expiry_Date_gne__c != null) {
					trialWithEndDate.put(c.CFAR_Trial_ref_gne__c, (Date)lastExpContractTracking.get(c.CFAR_Trial_ref_gne__c).get('Contract_Expiry_Date_gne__c'));
				}
				
				System.debug('-------- lastExpContractTracking ' + lastExpContractTracking);			
				System.debug('-------- trialWithEndDate ' + trialWithEndDate);
				/*if((isOrginal || isAmendmentOrAdjustment) && c.Contract_Expiry_Date_gne__c != null 
					&& (trigger.isInsert 
						|| (((DateTime)lastContractTracking.get(c.CFAR_Trial_ref_gne__c).get('created')) == c.CreatedDate 
							&& (Trigger.oldMap.get(c.Id).Contract_Expiry_Date_gne__c == null 
								|| Trigger.oldMap.get(c.Id).Contract_Expiry_Date_gne__c != Trigger.newMap.get(c.Id).Contract_Expiry_Date_gne__c))
						)
				) {
					trialWithEndDate.put(c.CFAR_Trial_ref_gne__c, c.Contract_Expiry_Date_gne__c);
				}*/
				
				
				//if(isOrginal && baseCondition
				//			/* FIXME check: && c.Contract_ID_gne__c != null*/) {
				if ((isOrginal || (isPlanned && !CFAR_Budget_Utils.hasProjections(c.CFAR_Trial_ref_gne__c))) && baseCondition) {
					orginalTrackingToProjections.add(c);
				}

				//if(isAmendmentOrAdjustment && baseCondition) {
				if ((isAmendmentOrAdjustment || (isPlanned && CFAR_Budget_Utils.hasProjections(c.CFAR_Trial_ref_gne__c))) && baseCondition) {
					//trackingAffectedProjections.add(c);
					trackingAffectedProjectionsTrialIdx.add(c.CFAR_Trial_ref_gne__c);
				}
			}
			
			if(!orginalTrackingToProjections.isEmpty()) {
				trialProjectionsForInsert.addAll(CFAR_Budget_Utils.generateProjections(orginalTrackingToProjections, typeMap));
				if(!trialProjectionsForInsert.isEmpty()) {
					upsert trialProjectionsForInsert;
				}
			}
			
			if(!trackingAffectedProjectionsTrialIdx.isEmpty()) {
				List<CFAR_Budget_Contract_Tracking_gne__c> l = [select Id, Name, Amendment_Number_gne__c, Amount_gne__c, CFAR_Trial_ref_gne__c, 
            		Comments_gne__c, Contract_Expiry_Date_gne__c, Contract_ID_gne__c, CreatedDate, 
            		frm_sfdc_Completed_gne__c, frm_Type_gne__c, Fully_Executed_Date_gne__c, LastModifiedDate, 
            		txt_Type_gne__c, Type_ref_gne__c, Variance_gne__c from CFAR_Budget_Contract_Tracking_gne__c 
            			where frm_Type_gne__c in :types and CFAR_Trial_ref_gne__c in :trackingAffectedProjectionsTrialIdx and Fully_Executed_Date_gne__c != null and Contract_Expiry_Date_gne__c != null order by CreatedDate asc];
				CFAR_Budget_Utils.actualizeProjections(l, typeMap);
			}
			
			List<CFAR_Budget_Contract_Tracking_gne__c> trackings = [select CFAR_Trial_ref_gne__c, Amount_gne__c from CFAR_Budget_Contract_Tracking_gne__c where CFAR_Trial_ref_gne__c in :trialsIdx and frm_Type_gne__c != :CFAR_Budget_Controller.CONTRACT_TRACKING_PLANNED_TYPE order by CreatedDate desc];
			for(CFAR_Budget_Contract_Tracking_gne__c t : trackings) {
				if(!trialWithLastAmendment.containsKey(t.CFAR_Trial_ref_gne__c)) {
					trialWithLastAmendment.put(t.CFAR_Trial_ref_gne__c, t.Amount_gne__c);
				}
			}
			
			if(!trialWithEndDate.isEmpty() || !trialWithExecutionDate.isEmpty() || !trialWithLastAmendment.isEmpty()) {
				set<Id> trialsIds = new set<Id>();
				trialsIds.addAll(trialWithEndDate.keySet());
				trialsIds.addAll(trialWithExecutionDate.keySet());
				trialsIds.addAll(trialWithLastAmendment.keySet());
				List<CFAR_Trial_gne__c> trials = [select Id, Original_Contract_Execution_Date_gne__c, Contract_End_Date_gne__c, Last_Amendment_Amount_gne__c from CFAR_Trial_gne__c where Id in :trialsIds];
				for(CFAR_Trial_gne__c c : trials) {
					if(trialWithEndDate.containsKey(c.Id))
						c.Contract_End_Date_gne__c = trialWithEndDate.get(c.Id);
					if(trialWithExecutionDate.containsKey(c.Id))
						c.Original_Contract_Execution_Date_gne__c = trialWithExecutionDate.get(c.Id);
					if(trialWithLastAmendment.containsKey(c.Id))
						c.Last_Amendment_Amount_gne__c = trialWithLastAmendment.get(c.Id);			
				}
				CFAR_Utils.setAlreadyProcessed();
				update trials;
				
			}

			
			
			set<String> contractTypes = new set<String>();
			contractTypes.addAll(CFAR_Budget_Utils.getAmendmentTypeNames());
			contractTypes.add(CFAR_Budget_Controller.CONTRACT_TRACKING_ADJUSTMENT_TYPE);
			contractTypes.add(CFAR_Budget_Controller.CONTRACT_TRACKING_PLANNED_TYPE);
			
			List<CFAR_Budget_Contract_Tracking_gne__c> contractList = [select Id, Name, Amendment_Number_gne__c, Amount_gne__c, CFAR_Trial_ref_gne__c, 
            		Comments_gne__c, Contract_Expiry_Date_gne__c, Contract_ID_gne__c, CreatedDate, 
            		frm_sfdc_Completed_gne__c, frm_Type_gne__c, Fully_Executed_Date_gne__c, LastModifiedDate, 
            		txt_Type_gne__c, Type_ref_gne__c,Type_ref_gne__r.Name, Variance_gne__c from CFAR_Budget_Contract_Tracking_gne__c 
            			where (CFAR_Trial_ref_gne__c in :trialsIdx or CFAR_Trial_ref_gne__c in :trialIdxForPlanned) 
            				and Type_ref_gne__r.Name in :contractTypes 
            				and Id not in :trigger.newMap.keySet() order by CreatedDate asc];
         
         	List<CFAR_Budget_Contract_Tracking_gne__c> contractListToUpdate = new List<CFAR_Budget_Contract_Tracking_gne__c>();
	        Map<Id, Double> lastAmount = new Map<Id, Double>();  			
	        for(CFAR_Budget_Contract_Tracking_gne__c t : contractList) {
	        	for(CFAR_Budget_Contract_Tracking_gne__c c : trigger.new) {
	        		if(!lastAmount.containsKey(c.CFAR_Trial_ref_gne__c)) {
	        			lastAmount.put(c.CFAR_Trial_ref_gne__c, c.Amount_gne__c);
	        		}
	        		if(c.CFAR_Trial_ref_gne__c == t.CFAR_Trial_ref_gne__c && t.CreatedDate > c.CreatedDate) {
	        			t.Variance_gne__c = t.Amount_gne__c - lastAmount.get(t.CFAR_Trial_ref_gne__c);
	        			lastAmount.put(t.CFAR_Trial_ref_gne__c, t.Amount_gne__c);
	        			contractListToUpdate.add(t);
	        			break;
	        		}
	        	}
	        }
	        CFAR_Budget_Utils.setAlreadyProcessedTracking();
			update contractListToUpdate;
			for(CFAR_Trial_gne__c trial : [SELECT Id,Contract_End_Date_gne__c FROM CFAR_Trial_gne__c WHERE id in :trialsIdx or id in :trialIdxForPlanned]){
				CFAR_Budget_Utils.deleteZeroAmountProjectionsWithWrongYear(trial);
			}
			//FIXME
			CFAR_Budget_CPS_Payments_gne__c[] payments = [select Id from CFAR_Budget_CPS_Payments_gne__c where CFAR_Trial_ref_gne__c in :trialsIdx or CFAR_Trial_ref_gne__c in :trialIdxForPlanned];
			//fake update to trigger logic
			update payments;
		}
	}	
}