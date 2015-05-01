/*
*@Author: Konrad Russa
*@Created: 30-10-2013
*/

trigger CFAR_Budget_CPS_PaymentsTrigger on CFAR_Budget_CPS_Payments_gne__c (after insert, after update, after delete) {
    
    Set<String> trials = new Set<String>();
    Set<String> paymentExp = new Set<String>();         
    
    if(!CFAR_Budget_Utils.hasAlreadyProcessedPayment()) {
        if(!trigger.isdelete) {
            
            trials = CFAR_Utils.fetchSet(trigger.new, 'CFAR_Trial_ref_gne__c');                     
            map<Id, map<Integer, Decimal>> trialPaidIds = new map<Id, map<Integer, Decimal>>();
            map<Id, map<integer, map<integer, decimal>>> trialRefundedIds = new map<Id, map<integer, map<integer, decimal>>>();
            map<Id, Decimal> trialPaymentsIds = new map<Id, Decimal>();            
            
            for(CFAR_Budget_CPS_Payments_gne__c cpsPayment : trigger.new) {
                    if(Trigger.isInsert || (Trigger.isUpdate && (cpsPayment.Invoice_Amount_gne__c != trigger.oldMap.get(cpsPayment.Id).Invoice_Amount_gne__c ||
                        cpsPayment.Payment_Status_ref_gne__c != trigger.oldMap.get(cpsPayment.Id).Payment_Status_ref_gne__c))) 
                    {
                        paymentExp.add(cpsPayment.Payment_Explanation_Text_gne__c);
                    } else if(Trigger.isUpdate && (cpsPayment.Payment_Explanation_Text_gne__c != trigger.oldMap.get(cpsPayment.Id).Payment_Explanation_Text_gne__c)) {
                        paymentExp.add(trigger.oldMap.get(cpsPayment.Id).Payment_Explanation_Text_gne__c);
                        paymentExp.add(cpsPayment.Payment_Explanation_Text_gne__c);                 
                    }
            }
            List<CFAR_Budget_CPS_Payments_gne__c> completedList = [select Id, frm_sfdc_Completed_gne__c,
                                                Invoice_Amount_gne__c, Paid_On_gne__c, Payment_Status_ref_gne__c, Payment_Status_ref_gne__r.Name, 
                                                CFAR_Trial_ref_gne__c, Invoice_Submitted_Date_gne__c, Planned_Amount_gne__c
                            from CFAR_Budget_CPS_Payments_gne__c where CFAR_Trial_ref_gne__c in :trials 
                                and Payment_Status_ref_gne__r.Name != :CFAR_Budget_Controller.PAYMENT_SCHEDULE_CANCELLED_STATUS];
            
            for(CFAR_Budget_CPS_Payments_gne__c c : completedList) {
                //Payment has been made section
                Boolean notInStatus = c.Payment_Status_ref_gne__r.Name != CFAR_Budget_Controller.PAYMENT_SCHEDULE_REFUND_STATUS
                        && c.Payment_Status_ref_gne__r.Name != CFAR_Budget_Controller.PAYMENT_SCHEDULE_PLANNED_STATUS
                            && c.Payment_Status_ref_gne__r.Name != CFAR_Budget_Controller.PAYMENT_SCHEDULE_UNPAID_STATUS;
                    
                if((trigger.isInsert && notInStatus && c.Invoice_Submitted_Date_gne__c != null && c.Invoice_Amount_gne__c != null) 
                    || (trigger.isUpdate && notInStatus && c.Invoice_Submitted_Date_gne__c != null && c.Invoice_Amount_gne__c != null)) {
                    if(trialPaidIds.containsKey(c.CFAR_Trial_ref_gne__c)) {
                        if(trialPaidIds.get(c.CFAR_Trial_ref_gne__c).containsKey(c.Invoice_Submitted_Date_gne__c.year())) {
                            Decimal currentAmount = trialPaidIds.get(c.CFAR_Trial_ref_gne__c).get(c.Invoice_Submitted_Date_gne__c.year());
                            trialPaidIds.get(c.CFAR_Trial_ref_gne__c).put(c.Invoice_Submitted_Date_gne__c.year(),
                                        currentAmount + c.Invoice_Amount_gne__c);
                        } else {
                            trialPaidIds.get(c.CFAR_Trial_ref_gne__c).put(c.Invoice_Submitted_Date_gne__c.year(), c.Invoice_Amount_gne__c);
                        }
                        
                    } else {
                        trialPaidIds.put(c.CFAR_Trial_ref_gne__c, 
                            new map<Integer, Decimal>{c.Invoice_Submitted_Date_gne__c.year() => c.Invoice_Amount_gne__c});
                    }
                }
                
                //Refund section
                Boolean afterUpdate = trigger.isUpdate && c.Invoice_Amount_gne__c != null
                    && c.Invoice_Submitted_Date_gne__c != null && c.Payment_Status_ref_gne__c != null 
                        && c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_REFUND_STATUS;
                
                if((Trigger.isInsert && c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_REFUND_STATUS 
                        && c.Invoice_Amount_gne__c != null && c.Invoice_Submitted_Date_gne__c != null)
                    || afterUpdate) {
                    
                    Integer month = c.Invoice_Submitted_Date_gne__c.month();
                    Integer year = c.Invoice_Submitted_Date_gne__c.year();
                    if(trialRefundedIds.containsKey(c.CFAR_Trial_ref_gne__c)) {
                        if(trialRefundedIds.get(c.CFAR_Trial_ref_gne__c).containsKey(year)) {
                            map<integer, Decimal> currentAmount = trialRefundedIds.get(c.CFAR_Trial_ref_gne__c).get(year);
                            if(currentAmount.containsKey(month)) {
                                Decimal amount = currentAmount.get(month);
                                trialRefundedIds.get(c.CFAR_Trial_ref_gne__c).get(year).put(month, amount + c.Invoice_Amount_gne__c);
                            } else {
                                trialRefundedIds.get(c.CFAR_Trial_ref_gne__c).get(year).put(month, c.Invoice_Amount_gne__c);
                            }
                        } else {
                            trialRefundedIds.get(c.CFAR_Trial_ref_gne__c).put(year, new map<Integer, decimal> {month => c.Invoice_Amount_gne__c});
                        }
                        
                    } else {
                        trialRefundedIds.put(c.CFAR_Trial_ref_gne__c, 
                            new map<integer, map<integer, decimal>> {year 
                                        => new map<integer, decimal>{ month => c.Invoice_Amount_gne__c}});
                    }
                }
                
                if(trialPaymentsIds.containsKey(c.CFAR_Trial_ref_gne__c)) {
                    Decimal currentAmount = trialPaymentsIds.get(c.CFAR_Trial_ref_gne__c);
                    if((c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_PLANNED_STATUS 
                        ||  c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_UNPAID_STATUS) && c.Planned_Amount_gne__c != null) {
                        trialPaymentsIds.put(c.CFAR_Trial_ref_gne__c, currentAmount + c.Planned_Amount_gne__c);
                    } else if(c.Invoice_Amount_gne__c != null){
                        trialPaymentsIds.put(c.CFAR_Trial_ref_gne__c, currentAmount + c.Invoice_Amount_gne__c);
                    }
                    
                } else {
                    if((c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_PLANNED_STATUS 
                        ||  c.Payment_Status_ref_gne__r.Name == CFAR_Budget_Controller.PAYMENT_SCHEDULE_UNPAID_STATUS) && c.Planned_Amount_gne__c != null) {
                        trialPaymentsIds.put(c.CFAR_Trial_ref_gne__c, c.Planned_Amount_gne__c);
                    } else if(c.Invoice_Amount_gne__c != null){
                        trialPaymentsIds.put(c.CFAR_Trial_ref_gne__c, c.Invoice_Amount_gne__c);                 
                    }
                }
            }
            
            set<Id> trialIdsSet = new set<Id>();
            trialIdsSet.addAll(trialPaidIds.keySet());
            trialIdsSet.addAll(trialRefundedIds.keySet());
            
            /*
            if(!trialRefundedIds.isEmpty()) {
                List<CFAR_Budget_Contract_Tracking_gne__c> l = [select Id, Name, Amendment_Number_gne__c, Amount_gne__c, CFAR_Trial_ref_gne__c, 
                            Comments_gne__c, Contract_Expiry_Date_gne__c, Contract_ID_gne__c, CreatedDate, 
                            frm_sfdc_Completed_gne__c, frm_Type_gne__c, Fully_Executed_Date_gne__c, LastModifiedDate, 
                            txt_Type_gne__c, Type_ref_gne__c, Variance_gne__c from CFAR_Budget_Contract_Tracking_gne__c 
                                where frm_Type_gne__c in :CFAR_Budget_Utils.getOrginalAndAmendmentTypeNames() and CFAR_Trial_ref_gne__c = :trialRefundedIds.keySet() order by CreatedDate asc];
                CFAR_Utils.actualizeProjections(l, CFAR_Utils.getContractTypeMap()); //trackingAffectedProjections
            }*/
            
            List<CFAR_Budget_CPS_Projection_gne__c> projections = new List<CFAR_Budget_CPS_Projection_gne__c>([select Id, Quarter_1_gne__c,Quarter_2_gne__c,Quarter_3_gne__c,Quarter_4_gne__c,
                January_gne__c, February_gne__c, March_gne__c, April_gne__c, May_gne__c, June_gne__c, July_gne__c, 
                August_gne__c, September_gne__c, October_gne__c, November_gne__c, December_gne__c, 
                CFAR_Trial_ref_gne__c, Year_gne__c, Total_Paid_gne__c, frm_Total_Amount_gne__c
                                     from CFAR_Budget_CPS_Projection_gne__c 
                                        where CFAR_Trial_ref_gne__c in :trials order by Year_gne__c]);
                                                                        
            Map<Id, AggregateResult> trialsWithPayments = CFAR_Budget_Utils.hasPaymentsSubmitted(CFAR_Utils.setToIdSet(trials));
            
            for(CFAR_Budget_CPS_Projection_gne__c arg : projections) {
                Integer year = Integer.valueOf(arg.Year_gne__c);
                arg.Total_Paid_gne__c = 0;
                if(trialPaidIds.containsKey(arg.CFAR_Trial_ref_gne__c)) {
                    if(trialPaidIds.get(arg.CFAR_Trial_ref_gne__c).containsKey(year)) {
                        Decimal totalPaidToAdd = (Decimal)trialPaidIds.get(arg.CFAR_Trial_ref_gne__c).get(year);
                        arg.Total_Paid_gne__c = totalPaidToAdd;
                        trialPaidIds.get(arg.CFAR_Trial_ref_gne__c).put(year, arg.Total_Paid_gne__c);
                    }
                }
                
                if(trialsWithPayments.containsKey(arg.CFAR_Trial_ref_gne__c) && trialRefundedIds.containsKey(arg.CFAR_Trial_ref_gne__c)) {
                    if(trialRefundedIds.get(arg.CFAR_Trial_ref_gne__c).containsKey(year)) {
                        map<integer, decimal> monthAmount = trialRefundedIds.get(arg.CFAR_Trial_ref_gne__c).get(year);
                        
                        if(monthAmount.containsKey(1)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(1);
                            //arg.January_gne__c = arg.January_gne__c + monthAmount.get(1);
                        }
                        if(monthAmount.containsKey(2)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(2);
                            //arg.February_gne__c = arg.February_gne__c + monthAmount.get(2);
                        }
                        if(monthAmount.containsKey(3)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(3);
                            //arg.March_gne__c = arg.February_gne__c + monthAmount.get(3);
                        } 
                        if(monthAmount.containsKey(4)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(4);
                            //arg.April_gne__c = arg.April_gne__c + monthAmount.get(4);
                        }
                        if(monthAmount.containsKey(5)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(5);
                            //arg.May_gne__c = arg.May_gne__c + monthAmount.get(5);
                        }
                        if(monthAmount.containsKey(6)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(6);
                            //arg.June_gne__c = arg.June_gne__c + monthAmount.get(6);
                        } 
                        if(monthAmount.containsKey(7)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(7);
                            //arg.July_gne__c = arg.July_gne__c + monthAmount.get(7);
                        }
                        if(monthAmount.containsKey(8)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(8);
                            //arg.August_gne__c = arg.August_gne__c + monthAmount.get(8);
                        }
                        if(monthAmount.containsKey(9)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(9);
                            //arg.September_gne__c = arg.September_gne__c + monthAmount.get(9);
                        }
                        if(monthAmount.containsKey(10)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(10);
                            //arg.October_gne__c = arg.October_gne__c + monthAmount.get(10);
                        }
                        if(monthAmount.containsKey(11)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(11);
                            //arg.November_gne__c = arg.November_gne__c + monthAmount.get(11);
                        }
                        if(monthAmount.containsKey(12)) {
                            arg.Total_Paid_gne__c = arg.Total_Paid_gne__c + monthAmount.get(12);
                            //arg.December_gne__c = arg.December_gne__c + monthAmount.get(12);
                        }
                    } 
                }
                /*
                arg.Quarter_1_gne__c = CFAR_Utils.returnZeroNotNull(arg.January_gne__c) 
                            + CFAR_Utils.returnZeroNotNull(arg.February_gne__c) + CFAR_Utils.returnZeroNotNull(arg.March_gne__c);
                arg.Quarter_2_gne__c = CFAR_Utils.returnZeroNotNull(arg.April_gne__c) 
                            + CFAR_Utils.returnZeroNotNull(arg.May_gne__c) + CFAR_Utils.returnZeroNotNull(arg.June_gne__c);
                arg.Quarter_3_gne__c = CFAR_Utils.returnZeroNotNull(arg.July_gne__c) 
                            + CFAR_Utils.returnZeroNotNull(arg.August_gne__c) + CFAR_Utils.returnZeroNotNull(arg.September_gne__c);
                arg.Quarter_4_gne__c = CFAR_Utils.returnZeroNotNull(arg.October_gne__c) 
                            + CFAR_Utils.returnZeroNotNull(arg.November_gne__c) + CFAR_Utils.returnZeroNotNull(arg.December_gne__c);
                */
            }
            
            if(!projections.isEmpty()) {
                update projections;
            }
            
            //if(!trialPaidIds.isEmpty() || !trialRefundedIds.isEmpty()) {
                List<CFAR_Trial_gne__c> trialsToChangeBudgetSection = [select Id, Year_to_Date_Paid_gne__c, Prior_Years_Paid_gne__c, Next_Payment_Due_gne__c, Total_Payments_gne__c, 
                        frm_Current_Amount_gne__c, Amount_Left_to_Project_gne__c from CFAR_Trial_gne__c where Id in :trials];
                        
                Map<Id, AggregateResult> trialNextPayments = new Map<Id, AggregateResult>([select CFAR_Trial_ref_gne__c Id, min(Planned_Date_gne__c) nextPayment
                        from CFAR_Budget_CPS_Payments_gne__c where frm_sfdc_Completed_gne__c = false 
                             and Payment_Status_ref_gne__r.Name != :CFAR_Budget_Controller.PAYMENT_SCHEDULE_SUBMITTED_STATUS
                             and Payment_Status_ref_gne__r.Name != :CFAR_Budget_Controller.PAYMENT_SCHEDULE_PAID_STATUS
                             and Payment_Status_ref_gne__r.Name != :CFAR_Budget_Controller.PAYMENT_SCHEDULE_REFUND_STATUS
                             and Payment_Status_ref_gne__r.Name != :CFAR_Budget_Controller.PAYMENT_SCHEDULE_CANCELLED_STATUS
                             and CFAR_Trial_ref_gne__c in :trialPaidIds.keySet() group by CFAR_Trial_ref_gne__c]);
                
                Integer currentYear = System.now().year(); 
                for(CFAR_Trial_gne__c trial : trialsToChangeBudgetSection) {
                    if(trialPaidIds.containsKey(trial.Id)) {
                        map<Integer, Decimal> m = trialPaidIds.get(trial.Id);
                        if(m.containsKey(currentYear)) {
                            trial.Year_to_Date_Paid_gne__c = m.get(currentYear);
                        } else trial.Year_to_Date_Paid_gne__c = 0;
                        for(Integer year : m.keySet()) {
                            if(year < currentYear) {
                                trial.Prior_Years_Paid_gne__c = null;
                                break;
                            }
                        }
                        for(Integer year : m.keySet()) {
                            if(year < currentYear) {
                                trial.Prior_Years_Paid_gne__c = trial.Prior_Years_Paid_gne__c != null 
                                    ? trial.Prior_Years_Paid_gne__c + m.get(year) 
                                    : m.get(year);
                            }
                        }   
    
                        if(trialNextPayments.containsKey(trial.Id)) {
                            trial.Next_Payment_Due_gne__c = (Date) trialNextPayments.get(trial.Id).get('nextPayment');
                        } else {
                            trial.Next_Payment_Due_gne__c = null;
                        }
                    } else {
                        trial.Year_to_Date_Paid_gne__c = 0;
                        trial.Prior_Years_Paid_gne__c = 0;
                    }
                    if(trialRefundedIds.containsKey(trial.Id)) {
                        map<integer, map<integer,decimal>> m = trialRefundedIds.get(trial.Id);
                        Decimal curentYearAmount = 0;
                        if(m.containsKey(currentYear)) {
                            map<integer,decimal> quarterAmountCurrentYear = m.get(currentYear);
                            for(integer i : quarterAmountCurrentYear.keySet()) {
                                curentYearAmount += quarterAmountCurrentYear.get(i);
                            }
                            trial.Year_to_Date_Paid_gne__c = trial.Year_to_Date_Paid_gne__c + curentYearAmount; 
                        }
                    }
                    if(trialPaymentsIds.containsKey(trial.Id)) {

                        trial.Total_Payments_gne__c = trialPaymentsIds.get(trial.Id);
                    }
                }
                CFAR_Utils.setAlreadyProcessed();
                update trialsToChangeBudgetSection;
            } else {
                trials = CFAR_Utils.fetchSet(trigger.old, 'CFAR_Trial_ref_gne__c');                     
            
                for(CFAR_Budget_CPS_Payments_gne__c cpsPayment : trigger.old) {
                    paymentExp.add(cpsPayment.Payment_Explanation_Text_gne__c);
                }
            }       
            // recount rate table
            if(!trials.isEmpty() && !paymentExp.isEmpty()) {
                List<CFAR_Rate_Table_gne__c> rateTables = [Select Id, Total_Amount_gne__c, Contract_Term_gne__c, CFAR_Trial_ref_gne__c FROM CFAR_Rate_Table_gne__c 
                                                            WHERE CFAR_Trial_ref_gne__c in :trials AND Contract_Term_gne__c in :paymentExp];
                update rateTables;
            }           
        
        CFAR_Budget_Utils.setAlreadyProcessedPayment();
    }
}