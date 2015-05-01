//*************************************************//
//* This script has been modified by GDC 18/2  *//
//* Changes for Raptiva PAN - FORM and Raptiva GSK. *//
//*************************************************//

// update: 03032009 - JW - Added support for Rituxan RA
// update: 032409 -- jw - added integrity code, added enhanced error handling
// update: 042809 -- removed error out on code when a brand not processed by vendors is selected in p. program
// update: 07/30/2009 == Hardy: updated logic to not create transaction record for rituxan ra - offshore request - 269
//// update: 12/08/2009 == SKM: updated the medical history criteria selection based on campaign product brand name
// update: 12/22/2009 == SKM: Fix for update validation MH/Cases to enroll Patient Program on campaign product brand name
// update: 12/23/2009 == SKM: Fix for update validation address if email doesnot exists/vice versa
// update: 1/5/2010 == SKM: Fix for removing sql and dml for same PP to fix 21 soql/dml
// update: 1/11/2010 == SKM: Fix for soql and rolled back to 12/8 version and added valication for address and email
// update: 8/11/2010 == SKM: Fix for ICD9 codes and  added new Segments for Avastin, Teceva, Rituxan
// update: 8/31/2010 == SKM: Fix for Survey Xolair

trigger GNE_PatPers_IU_Save on Patient_Program_gne__c (after insert, after update)
{
    Boolean isPatientProgramProcessingRequired;
    String SegmentID;
    String transactionID = '';
    String patientID = '';
    Date productShipDate=null;
    Set<Id> GSK_Date_Update_IDList = new Set<Id>();
    Set<Id> Patient_program_update = new Set<Id>();
    GNE_PatPers_InsertUpdate_Trigger_Support ppSupport = new GNE_PatPers_InsertUpdate_Trigger_Support();
    GNE_PatPers_IU_Support_Helpers pHelpers = new GNE_PatPers_IU_Support_Helpers();
    GNE_PatPers_IU_PatientAndAddressInfo patient;
    List<Medical_history_gne__c> mHistoryList = new List<Medical_history_gne__c>();    
    Medical_history_gne__c mHist; 
    // Map<String, Patient_Program_gne__c> Patient_program_update = new Map<String, Patient_Program_gne__c>();
    List<Case> mCaseList = new List<Case>();
    Case caseME;
    
    // Map mapping campaign ID to a list of associated program IDs
    Map<Id, Set<Id>> campaignPrograms = new Map<Id, Set<Id>>();
    // Mapping program IDs to brands retrieved from their associated campaigns
    Map<Id, List<String>> programBrandMap = new Map<Id, List<String>>(); 

    List<Patient_Program_gne__c> program = trigger.new;
    
    System.debug('[RK] Entered trigger');
    
    // get campaign list to match with Medical hist product 
    for (Patient_Program_gne__c p : program)
    {
        if (campaignPrograms.keySet().contains(p.Program_Name_gne__c))
        {
            campaignPrograms.get(p.Program_Name_gne__c).add(p.Id);
        }
        else
        {
            campaignPrograms.put(p.Program_Name_gne__c, new Set<Id>{p.Id});
        }   
    }
    
    // for each campaign, select a brand, and then iterate through these campaigns
    for (Campaign camp : [Select Brand_gne__c, Patient_Program_Processing_Required_gne__c from Campaign where Id IN : campaignPrograms.keySet()])
    {
        for (Id programID : campaignPrograms.get(camp.Id))
        {
            // for each program, associate it with a brand
            programBrandMap.put(programID, new List<String>{camp.Brand_gne__c, String.valueOf(camp.Patient_Program_Processing_Required_gne__c)});
        }
    }
    
    System.debug('[RK] Iterating through ' + program.size() + ' programs');
    
    // iterate through patient programs
    for (Integer counter = 0; counter < program.size(); counter++)
    {
        System.debug('[RK] Program ' + counter);
        
        // programs are processed only upon insert or if their "Reprocess" flag is set to true
        if (trigger.isInsert || trigger.new[counter].Reprocess_Flag_gne__c == true)
        {
       		// If transaction file for this Patient Program is already staged
    		// do not create duplicates
        	if (0<[SELECT COUNT() FROM Transaction_File_Staging_gne__c WHERE Patient_Program_gne__c=:program[counter].Id])
        	{
            System.debug('[SW] Duplicate Transaction_File_Staging_gne__c found for: ' + program[counter].Id);
        		continue;
        	}
        	
            System.debug('[RK] Insert trigger');
            
            patientID = program[counter].Patient_gne__c;
            System.debug('Patient ID value...........'+patientID);
            transactionID = program[counter].transaction_ID__c;

			// [SAW] added to support post shipment surveys            
            productShipDate = program[counter].Product_Ship_Date_gne__c;

            System.debug('transaction ID value...........'+transactionID);
            Patient_program_update.add(program[counter].Id);
                  
            try
            {
                // initialize patient info
                patient = pHelpers.GetPatientAndAddressInfo(patientId);
                System.debug('patient value...........'+patient);
            }
            catch (GNE_PatPers_Exception e)
            {
                trigger.new[counter].addError(e.getMessage());
                return;
            }       
            
            
            isPatientProgramProcessingRequired = Boolean.valueOf(programBrandMap.get(program[counter].Id)[1]);
            System.debug('isPatientProgramProcessingRequired value...........'+isPatientProgramProcessingRequired);
            String brandName = programBrandMap.get(program[counter].Id)[0];
            System.debug('brandName value...........'+brandName);
            
            System.debug('[RK] PP processing required = ' + isPatientProgramProcessingRequired);
            
            if (isPatientProgramProcessingRequired == true)
            {               
                /// get medical history
                /// moved local 04/19/2009 due to shared ???? memory corruption / static members ????
                try 
                {                   
                    mHistoryList = [select ID, Date_of_Diagnosis_gne__c,
                                        Tumor_Staging_gne__c,Previous_Therapy_Regimens_gne__c,
                                        Concurrent_Therapy_Regimens_gne__c,Therapy_Sequence_gne__c,
                                        Metastatic_Sites_gne__c,
                                        Her2_Test_gne__c,Adjuvant_gne__c,ICD9_Code_1_gne__r.icd9_code_gne__c,
                                        ICD9_Code_2_gne__r.icd9_code_gne__c,ICD9_Code_1_gne__r.Name,ICD9_Code_3_gne__r.icd9_code_gne__c,
                                        ICD9_Code_2_gne__r.Name,Eye_Affected_gne__c,
                                        Current_Rtx_Tx_Course_gne__c, ICD9_Code_1_gne__c, 
                                        Eye_Being_Treated_gne__c,VA_eye_being_treated_gne__c,
                                        Ancillary_Supplies_gne__c,Freqcy_of_Admin_gne__c,
                                        therapy_type_gne__c,FEV1_gne__c,ICD9_Code_3_gne__c,ICD9_Code_2_gne__c,Drug_gne__c,
                                        Needle_Size_gne__c,Dilute_with_ml_gne__c,Dosage_mg_gne__c,
                                        Dose_per_Inj_ml_gne__c,Dose_mg_kg_wk_gne__c, Treatment_Date_gne__c,
                                        Date_of_first_treatment_gne__c, Date_Therapy_Initiated_gne__c,
                                        Other_Asthma_Therapies_gne__c,History_of_Positive_or_RAST_Test_gne__c,
                                        IgE_Test_Results_IU_ml_gne__c,IgE_Test_Date_gne__c,Patient_Weight_kg_gne__c,
                                        Patient_Weight_Date_gne__c,Dispense_Month_supply_gne__c,Refill_times_gne__c,
                                        Ship_To_gne__c,Concomitant_Therapies_gne__c,Dose_Frequency_in_weeks_gne__c,
                                        TNM_Staging_gne__c,Patient_has_CIU_more_than_6_weeks_gne__c,Other_CIU_therapies_gne__c,
                                        H1_antihistamines_gne__c
                                    FROM Medical_history_gne__c
                                    WHERE Patient_Med_Hist_gne__r.ID =:patientID
                                    AND Product_gne__c = :brandName
                                    ORDER BY SystemModstamp DESC LIMIT 1];
                }
                catch (GNE_PatPers_Exception e)
                {
                    trigger.new[counter].addError('Urgent: Error retrieving patient medical history record. Verify record exists!!');
                    return;
                }
                
                if (mHistoryList == null)
                {
                    trigger.new[counter].addError('Urgent: Could not retrieve patient medical history record. Verify record exists!!');
                    return;
                }
                
                if (mHistoryList.size() > 0)
                {                   
                    mHist = mHistoryList[0];
                    System.debug('mHist value...........'+mHist);
                }
                else
                {
                    trigger.new[counter].addError('Urgent: Could not locate patient medical history record. Verify record exists!!');
                    return;        
                }    
                System.Debug('Medical history: ' + mHist);
                
                try 
                {
                    // Retrieve a case associated with the current patient and their medical history record.
                    // There should be only one such case.
                    mCaseList = [Select c.ID,c.Case_Treating_Physician_gne__r.fax,
                                    c.Case_Treating_Physician_gne__r.Name, c.Case_Treating_Physician_gne__c, c.Case_Treating_Physician_gne__r.City__pc, 
                                    c.Case_Treating_Physician_gne__r.FirstName, c.Case_Treating_Physician_gne__r.Id, c.Case_Treating_Physician_gne__r.LastName,
                                    c.Case_Treating_Physician_gne__r.ME__c, c.Case_Treating_Physician_gne__r.STARS_ID_gne__c,c.OK_to_Contact_Patient_gne__c  from Case c
                                    WHERE Medical_History_gne__c = :mHist.ID AND Patient_gne__r.ID = :patientID
                                    ORDER BY SystemModstamp DESC LIMIT 1]; 
                    
                    if (mCaseList == null) 
                    {
                        trigger.new[counter].addError('Urgent: Could not find case record.  Please validate case record exists for medical history and it contains valid data !!');
                        return;
                    }
                    else if (mCaseList.size() < 1)
                    {
                        trigger.new[counter].addError('Urgent: Could not locate case record.  Please validate case record exists for medical history and it contains valid data !!');
                        return;
                    }  
                }
                catch (Exception ex)
                {
                    trigger.new[counter].addError('Urgent:  System Error.  Could not get case record.  Patientid: ' + patientID + ' / Medical History id: ' + mHist.ID);  
                    return;
                }
                
                // Take the only case (there should be only one) associated with the patient
                caseME = mCaseList[0];
                String caseID = caseME.Id;
                
                // get address of the physician/practise associated with the case - there should be only one
                Address_vod__c[] addyPracticeList = [Select a.Address_1_gne__c,a.City_vod__c, a.Id, a.Name, a.State_vod__c, a.Zip_vod__c 
                                                        FROM Address_vod__c a
                                                        WHERE Account_vod__c = :caseME.Case_Treating_Physician_gne__r.ID
                                                        ORDER BY SystemModstamp DESC LIMIT 1];
                
                // address of the practise associated with the case
                Address_vod__c addyPractice = null;
                
                if ((addyPracticeList != null) && (addyPracticeList.Size() > 0))
                {
                    addyPractice = addyPracticeList[0];
                    System.debug('addyPractice value...........'+addyPractice);
                }
                
                insurance_gne__c insPrimary = null;
                Address_vod__c addyPrimary = null;
                insurance_gne__c insSecondary = null;
                Address_vod__c addySecondary = null;
                
                // profile query
                ProfileID_License_gne__c[] profileList = [Select p.Account_Name_gne__c, 
                                                            p.ID_License_gne__c, p.ID_License_Type_gne__c from ProfileID_License_gne__c p
                                                            WHERE p.Account_Name_gne__c = :caseME.Case_Treating_Physician_gne__c];   
                
                System.debug('[RK] Found ' + profileList.size() + ' profiles');       
                
                // get primary insurance for this case   
                insurance_gne__c[] insPrimaryList = [select Id, Name, Plan_Product_Type_gne__c, Rank_gne__c,Payer_gne__c, Payer_gne__r.Name 
                                                    FROM Insurance_gne__c
                                                    WHERE (Rank_gne__c = 'Primary') AND ((Patient_Insurance_gne__c = :patientID) AND 
                                                        (Case_Insurance_gne__c = :caseID))
                                                    ORDER BY lastmodifieddate DESC];
                                                    
                System.debug('[RK] Found ' + insPrimaryList.size() + ' primary insurances');
                
                if ((insPrimaryList != null) && (insPrimaryList.Size() > 0))
                { 
                    insPrimary = insPrimaryList[0];
                    
                    Address_vod__c[] addyPrim = [Select a.Phone_vod__c from Address_vod__c a
                    WHERE a.Account_vod__c = :insPrimaryList[0].Payer_gne__c
                    ORDER BY SystemModstamp DESC LIMIT 1];
                    if ((addyPrim != null) && (addyPrim.Size() > 0))
                    {
                        addyPrimary = addyPrim[0];
                    }                   
                }
                
                // get secondary insurance for this case
                insurance_gne__c[] insSecondaryList = [select Id, Name, Plan_Product_Type_gne__c, 
                                                        Rank_gne__c,Payer_gne__c, Payer_gne__r.Name 
                                                        FROM Insurance_gne__c
                                                        WHERE (Rank_gne__c = 'Secondary') AND ((Patient_Insurance_gne__c = :patientID) AND 
                                                        (Case_Insurance_gne__c = :caseID))
                                                        ORDER BY lastmodifieddate DESC];
            
                System.debug('[RK] Found ' + insSecondaryList.size() + ' secondary insurances');                                
                
                if ((insSecondaryList != null) && (insSecondaryList.Size() > 0))
                { 
                    insSecondary = insSecondaryList[0];
                    
                    Address_vod__c[] addySec = [Select a.Phone_vod__c from Address_vod__c a
                    WHERE a.Account_vod__c = :insSecondaryList[0].Payer_gne__c
                    ORDER BY SystemModstamp DESC LIMIT 1];
                    if ((addySec != null) && (addySec.Size() > 0))
                    {
                        addySecondary = addySec[0];
                    }
                } 

                if (patient != null)
                {
                    System.debug('[RK] Initializing new transaction file staging');
                    
                    // create a new staging file
                    Transaction_File_Staging_gne__c t = new Transaction_File_Staging_gne__c();
                    t.Address_Line_1_gne__c = patient.pat_address_line_1 ;
                    
                    if ( ((patient.pat_address_line_1 == null) || (patient.pat_address_line_1.equals(''))) && patient.pat_email_gne == null)
                    {
                        trigger.new[counter].addError('Urgent: Invalid patient street address.  Value cannot be blank. If patient is a minor, please validate the patient contact address information.  Otherwise, validate street address in patient address record !!!'); 
                        return;
                    }
                    
                    t.fax_gne__c = caseME.Case_treating_physician_gne__r.Fax;
                    t.ME_Number_gne__c = caseME.Case_Treating_Physician_gne__r.ME__c;
                    t.Practice_Name_gne__c =  caseME.Case_Treating_Physician_gne__r.Name;
                    t.Address_Line_2_gne__c = patient.pat_address_line_2 ;
                    if (patient.pat_city != null)
                    {
                        t.City_gne__c = patient.pat_city ;
                    }
                    else if(patient.pat_email_gne==null)
                    {
                        trigger.new[counter].addError('Urgent: Patient city is not specified properly.  Value cannot be blank !!!.');
                        return;
                    }
                    
                    if (patient.pat_country != null)
                    {
                        t.Country_gne__c = patient.pat_country ;
                    }
                    else if(patient.pat_email_gne==null)
                    {
                        trigger.new[counter].addError('Urgent: Patient country is not specified propererly.  Value cannot be blank !!!.');
                        return;
                    }
                    
                    if (patient.pat_dob == null)
                    {
                        trigger.new[counter].addError('Urgent: Patient date of birth is invalid.  Value cannot be blank !!!');
                        return;
                    }
                    else
                    {
                        t.dob_gne__c = Date.ValueOf(patient.pat_dob);
                    }
                    
                    if (patient.pat_first_name != null)
                    {
                        t.First_Name_gne__c = patient.pat_first_name;
                    }
                    else
                    {
                        trigger.new[counter].addError('Urgent: Invalid patient first name.  Value cannot be blank!!!');
                        return;
                    }   

                    if (patient.pat_last_name != null)
                    {
                        t.Last_Name_gne__c = patient.pat_last_name ;
                    }
                    else
                    {
                        trigger.new[counter].addError('Urgent: Invalid patient last name. Value cannot be blank !!');
                        return;
                    }    
                    
                    t.Middle_Initial_gne__c = patient.pat_mid_initial ;
                    t.Minor_First_Name_gne__c = patient.pat_minor_first_name ;
                    t.Minor_Last_Name_gne__c = patient.pat_minor_last_name ;
                    t.Minor_Middle_Name_gne__c = patient.pat_mid_initial ;
                    t.pat_email_gne__c = patient.pat_email_gne ;
                    
                    if (patient.pat_gender != null)
                    {
                        t.Pat_gender_gne__c = patient.pat_gender.substring(0,1);
                    }
                    else
                    {
                        trigger.new[counter].adderror('Urgent: Invalid patient gender.  Value cannot be blank !!!');
                        return;
                    }
                    
                    System.debug('[RK] Rewriting patient address data');
                    
                    t.Pat_Home_Phone_gne__c = patient.pat_home_phone ;
                    t.Pat_Work_Phone_gne__c = patient.pat_work_phone ;
                    t.Patient_Program_gne__c = program[counter].ID;
                    t.Prefix_gne__c = patient.pat_prefix;
                    t.State_gne__c = patient.pat_state ;
                    t.Suffix_gne__c = patient.pat_suffix ;
                    if (mHist.Date_of_first_treatment_gne__c != null)
                    {
                        t.Treatment_Date_gne__c = mHist.Date_of_first_treatment_gne__c;
                    }
                    else
                    {
                        t.Treatment_date_gne__c = system.today();
                    }
                    
                    if (patient.pat_state != null)
                    {
                        t.State_gne__c = patient.pat_state ;
                    }
                    else if (patient.pat_email_gne==null)
                    {
                        trigger.new[counter].addError('Urgent: Patient state is not specified propererly.  Value cannot be blank !!!.');
                        return;
                    }
                       
                    if (patient.pat_zip != null)
                    {
                        t.Zip_gne__c  = patient.pat_zip;
                    }
                    else if(patient.pat_email_gne==null)
                    {
                        trigger.new[counter].addError('Urgent: Patient zip is not specified propererly.  Value cannot be blank !!!.');
                        return;
                    }
                            
                    t.transaction_id_gne__c = transactionId;
                                                            
                    if (brandName == null)
                    {
                        trigger.new[counter].addError('Urgent: Invalid brand selection in drug campaign. Value cannot be blank !!!');
                        return;
                    }
                    
                    // This is the transformation for the SEGMENT ID. 
                    // 1. Raptiva-GSK says HH Segment ID = 803, This is the value when all returned Patient Program have null date. 
                    // In this case, we stamp the gsk date on the new record. 
                    // 2. Raptiva - PAN Form has HH Segment ID = 1570, This is the value when any returned Patient Program has not null date. 
                    segmentID = ppSupport.getSegmentIDByProduct(brandName,patient,mHist);
                    
                    System.debug('[RK] Segment ID = ' + segmentId);
/*                    
                    if (segmentID.equals('8075'))
                    {
                        if ((trigger.new[0].Patient_Declined_Referral_gne__c ==null ||!trigger.new[0].Patient_Declined_Referral_gne__c.equals('Yes')) 
                                && trigger.new[0].Method_of_Referral_gne__c==null)
                        {
                            //process
                        }
                        else
                        {
                            segmentID = '0';
                        }
                    }
*/                    
                    if (segmentID.equals('1570'))
                    {
                        t.RAPTIVA_GSK_INDICATOR_gne__c = 'Y';
                        System.Debug('GSK INDICATOR TEST: IS RAPTIVA - GSK EXISTS IN PATIENT PROGRAM');
                    }
                    else if (segmentID.equals('803'))
                    {
                        t.RAPTIVA_GSK_INDICATOR_gne__c = 'N';
                        GSK_Date_Update_IDList.add(trigger.new[counter].Id);
                    }

                    if ((segmentID != null) && (! segmentID.Equals('0')) )
                    { 
                        t.segment_ID_gne__c = integer.ValueOf(segmentID);
                        
                        try 
                        {  
                            // insert the transaction file staging object
                            insert t;
                        }
                        catch (Exception e)
                        {
                            trigger.new[counter].addError('Urgent: Failed to save transaction record.  System exception report: ' + e.getMessage());   
                            return; 
                        }
                            
                        if (!segmentID.equals('5955'))
                        {
                            try 
                            {  
                                String transID = t.ID; 
                                // code in this block was existing.  changed only wrapper
                                system.debug('mhist-'+mHist);
                                integer recCount = ppSupport.surveyStart(transactionID, String.valueOf(t.ID), segmentID, patientID, mHist, caseME, addyPractice,
                                insPrimary, addyPrimary, insSecondary, addySecondary, profileList, program[counter].Preferred_Method_of_Contact_gne__c, productShipDate);

                                if ((recCount == 0) || (recCount == -1)) 
                                {
                                    transaction_file_staging_gne__c transDel = ([SELECT ID from transaction_file_staging_gne__c
                                                                                WHERE ID = :transID]);

                                    /// trash the trasnaction record
                                    delete transDel;
                                    
                                    // set Sent_To_Patient_Marketing_gne in pp to 'Y'
                                    Patient_Program_gne__c pp = ([SELECT ID, Sent_to_Patient_Marketing_gne__c from Patient_Program_gne__c
                                                                    WHERE ID = :trigger.new[counter].ID]);
                                                                    
                                    pp.Sent_to_patient_marketing_gne__c = 'Yes';
                                    update pp;                                                                                
                                    return;
                                }
                            }
                            catch (GNE_PatPers_Exception ex)
                            {
                                trigger.new[counter].addError(ex.getMessage());
                                return;
                            }
                        }    
                    } // segment id is not null
                    //            else
                    //            {
                    
                    //                 trigger.new[counter].addError('URGENT: INVALID BRAND SELECTION IN DRUG CAMPAIGN.  VALUE IS EITHER BLANK, OR IS SET TO A DRUG WHICH CANNOT BE USED IN CONJUNCTION WITH PATIENT PROGRAM FUNCTION !!!');
                    //                 return;
                    //            }

                }
            }
        } // end of if insert  
    }
    
    System.debug('##########################test3');
    
    //************************************************************************
    // This is added to update GSK_Sent_Date_gne__c based on conditions above.
    // Update GSK_Sent_Date_gne__c
    //************************************************************************


    if (Patient_program_update.size() > 0)
    {   
        system.debug ('Reprocess flag to be updated on ' + Patient_program_update.size() + ' records.');
        List<Patient_Program_gne__c> GSK_Date_Update_List = new List<Patient_Program_gne__c>([Select Id, GSK_Sent_Date_gne__c from Patient_Program_gne__c 
                                                                                            where Id in:Patient_program_update]);
        for (integer v = 0;v < GSK_Date_Update_List.size(); v++)
        {
            if (GSK_Date_Update_IDList.size()>0 && GSK_Date_Update_IDList.contains(GSK_Date_Update_List[v].Id))
            {
                GSK_Date_Update_List[v].GSK_Sent_Date_gne__c = system.now();
            }
            
            GSK_Date_Update_List[v].Reprocess_Flag_gne__c = false;
        }
        
        update GSK_Date_Update_List; 
    }
}