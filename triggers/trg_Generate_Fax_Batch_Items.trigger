trigger trg_Generate_Fax_Batch_Items on Fax_Batch_gne__c (after insert) {
    //Select  c.Case_Treating_Physician_gne__c, 
    //    c.Case_Treating_Physician_gne__r.Fax_Opt_Out_gne__c,
    //    c.Case_Treating_Physician_gne__r.Id,
    //    c.CreatedDate, 
    //    c.Medical_History_gne__c, 
    //    c.Medical_History_gne__r.Rx_Expiration_gne__c, 
    //    c.Medical_History_gne__r.SMN_Expiration_Date_gne__c, 
    //    c.Patient_gne__c, 
    //    c.Patient_gne__r.Id, 
    //    c.Patient_gne__r.Name, 
    //    c.Patient_gne__r.Patient_Name__c 
    //from Case c 
    //where   c.Foundation_Specialist_gne__c = UserInfo.Id and
    //    c.Product_gne__c = getValue(Product) and
    //    c.Case_Treating_Physician_gne__r.Fax_Opt_Out_gne__c = false and
    //    ( c.Medical_History_gne__r.Rx_Expiration_gne__c > today - 42 days or
    //      c.Medical_History_gne__r.SMN_Expiration_Date_gne__c > today - 42 days)
    //      
    //order by c.Case_Treating_Physician_gne__r.Id,
    //     c.Patient_gne__r.Id, 
    //     c.CreatedDate
    
    // Query above needs to get the Product value from the dropdown list
    // and the current user which should be a Foundation Specialist.
    //
    // Also, and this may not be possible in SOQL (in fact I don't think it is) 
    // The records need to be restricted to those that have either a prescription expiring
    // or an SMN expiring within six weeks and the records need to be restricted to the 
    // most recent case for this patient.
    
    List<Fax_Batch_Item_gne__c> FB_Item = new List<Fax_Batch_Item_gne__c>();
    map<ID,list<ID>> PhysciansAndPatient = new map<ID,list<ID>>();
    String     currentCase;
    String     currentPatient;
    DateTime   currentCreateDate;
    String     product;
    Set<String> setPhysicians  = new Set<String>();
    Fax_Batch_gne__c currentFaxBatch = new Fax_Batch_gne__c();
    
    String userid = UserInfo.getUserId();
    for (Fax_Batch_gne__c fb : Trigger.new) {
        product = fb.Product__c;
        System.debug('Product: ' + product);
        String batchid = fb.Id;
    
    // product = Fax_Batch_gne__c fb = Trigger.new;
    
    String strquery = 'Select  c.Case_Treating_Physician_gne__c,' +
                      'c.Case_Treating_Physician_gne__r.Fax_Opt_Out_gne__c,' +
                      'c.Case_Treating_Physician_gne__r.FirstName,' +
                      'c.Case_Treating_Physician_gne__r.LastName,' +
                      'c.Case_Treating_Physician_gne__r.Id,' +
                      'c.CreatedDate,' +
                      'c.Medical_History_gne__c,' +
                      'c.Medical_History_gne__r.Rx_Expiration_gne__c,'+
                      'c.Medical_History_gne__r.SMN_Expiration_Date_gne__c,' +
                      'c.Patient_gne__c,' +
                      'c.Patient_gne__r.Id,' +
                      'c.Patient_gne__r.Name,' +
                      'c.Patient_gne__r.Patient_Name__c ' +
                      'from Case c ' +
                      'where   c.Foundation_Specialist_gne__c = \'' + userid + '\' and ' +
                      'c.Product_gne__c = \'' + product + '\' and ' +
                      'c.Case_Treating_Physician_gne__r.Fax_Opt_Out_gne__c = false ' +
                      'order by c.Case_Treating_Physician_gne__r.Id,' +
                      'c.Patient_gne__r.Id,' +
                      'c.CreatedDate';
                      
    
    // DLH -- dont' forget to restore the opt out constraint and set the LAST_N_DAYS parameter for 
    //        six weeks.
    date SixWeeksFromNow = date.today().adddays(42);
    
    List<Case> batchcases = [Select Case_Treating_Physician_gne__c, 
                             c.Case_Treating_Physician_gne__r.id,
                             c.Case_Treating_Physician_gne__r.FirstName,
                             c.Case_Treating_Physician_gne__r.LastName,c.CaseNumber,
                             c.CreatedDate,c.Medical_History_gne__c,c.Id,
                             c.Medical_History_gne__r.Rx_Expiration_gne__c,c.Medical_History_gne__r.GATCF_SMN_Expiration_Date_gne__c,
                             c.Patient_gne__c,c.Patient_gne__r.Id,c.Patient_gne__r.pat_first_name_gne__c,c.Patient_gne__r.Name,
                             c.Patient_gne__r.pat_dob_gne__c,c.Product_gne__c,
                             c.Address_gne__c, c.Address_gne__r.Address_line_2_vod__c, 
                             c.Address_gne__r.City_vod__c, c.Address_gne__r.DEA_vod__c, c.Address_gne__r.Phone_vod__c,
                             c.Address_gne__r.Fax_vod__c, c.Address_gne__r.Mailing_vod__c, 
                             c.Address_gne__r.Name, c.Address_gne__r.Zip_vod__c,c.Address_gne__r.State_vod__c,
                             c.Case_Treating_Physician_gne__r.Address_gne__pr.Primary_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.Zip_4_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.State_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.Phone_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.Name, c.Case_Treating_Physician_gne__r.Address_gne__pr.Fax_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.DEA_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.City_vod__c, c.Case_Treating_Physician_gne__r.Address_gne__pr.Address_1_gne__c
                              from Case c
                             where c.Foundation_Specialist_gne__c = :userid and c.Status = 'Active' and
                             c.Product_gne__c = :product and c.Case_Treating_Physician_gne__r.Profile_Preferences_gne__c Excludes ('Opt Out of Bulk Faxing') and (
                               (c.Medical_History_gne__r.Rx_Expiration_gne__c != null and 
                                c.Medical_History_gne__r.Rx_Expiration_gne__c < :SixWeeksFromNow)
                               or
                               (c.Medical_History_gne__r.GATCF_SMN_Expiration_Date_gne__c != null and
                                c.Medical_History_gne__r.GATCF_SMN_Expiration_Date_gne__c < :SixWeeksFromNow)
                             )  
                             order by c.Case_Treating_Physician_gne__r.Id,
                             c.Patient_gne__r.Id,
                             c.CreatedDate];
                             // and c.Case_Treating_Physician_gne__r.Fax_Opt_Out_gne__c = false
    
        for (Case c : batchcases) {
        	if (c.Case_Treating_Physician_gne__c != null && c.Patient_gne__c != null){
        		if (IsNotList(c.Case_Treating_Physician_gne__c,c.Patient_gne__c)){
             // this should be the foreign key to Account with the physician information
             // we'll use this in another query if the record qualifies
             String physician = c.Case_Treating_Physician_gne__c;
             // String physicianName = c.Case_Treating_Physician_gne__r.FirstName + ' ' + c.Case_Treating_Physician_gne__r.LastName;
             String qproduct = c.Product_gne__c;
             DateTime qdate = c.CreatedDate;
             Date qrxdate = c.Medical_History_gne__r.Rx_Expiration_gne__c;
             Date qsmndate = c.Medical_History_gne__r.GATCF_SMN_Expiration_Date_gne__c;
             String qpatient = c.Patient_gne__r.Id;
             String qpatientName = c.Patient_gne__r.pat_first_name_gne__c + ' ' + c.Patient_gne__r.Name;
             String qcase = c.Id;
             
             System.debug('Case: ' + qcase);     
             System.debug('Patient: ' + qpatient);     
             if (qdate != null)
                 System.debug('Create date: ' + qdate.format());
        
             if (qrxdate != null)
                 System.debug('Rx Expiration: ' + qrxdate.format());
             if (qsmndate != null)
                 System.debug('SMN Expiration: ' + qsmndate.format());
                 
             if (testCase(c)) {
                 System.debug('Add this record to the Fax Batch Items...');
                 Fax_Batch_Item_gne__c local_FB_Item = new Fax_Batch_Item_gne__c();
                 
                 local_FB_Item.Fax_Batch__c = batchid;
                 populateNewItem(c, local_FB_Item);
                 FB_Item.add(local_FB_Item);

                 // Add the physician ID to our set so that we can determine the size at 
                 // the end of this trigger and update the Fax Batch record
                 setPhysicians.add(c.Case_Treating_Physician_gne__r.Id);
             }
        	}
        	}
        }
        
        if (FB_Item.size() > 0) {
            insert FB_Item;
        }
        
        System.Debug('Total Physicians: ' + setPhysicians.size());
        
        if (setPhysicians.size()>0) {
            // Update the Fax Batch record with the number of Physicians that will receive/
            // faxes as part of this batch
            currentFaxBatch = [select Total_Physicians_gne__c from Fax_Batch_gne__c where Id = :batchid];
            currentFaxBatch.Total_Physicians_gne__c = setPhysicians.size();
            update currentFaxBatch;
        }    
    }
   
    
    private boolean IsNotList(ID physicianid,ID patientid){
    	
	if (!PhysciansAndPatient.containsKey(physicianid)){
			
		list<ID> patient = new 	list<ID>();
		patient.add(patientid);
		PhysciansAndPatient.put(physicianid,patient);
		return true;
	}
	else {
		list<ID> patient = PhysciansAndPatient.get(physicianid);
		for(string pat:patient){
			if (pat == patientid){
				return false;
			}
		}
		patient.add(patientid);
		return true;
		
	}
		
    	
    }
    
    private void populateNewItem(Case c, Fax_Batch_Item_gne__c lfb) {
        lfb.Patient_DOB__c = c.Patient_gne__r.pat_dob_gne__c;
        lfb.Patient_First_Name__c = c.Patient_gne__r.pat_first_name_gne__c;
        lfb.Patient_Last_Name__c = c.Patient_gne__r.Name;
        lfb.Physician_First_Name__c = c.Case_Treating_Physician_gne__r.FirstName;
        lfb.Physician_Last_Name__c = c.Case_Treating_Physician_gne__r.LastName;
        lfb.Rx_Expiration_Date__c = c.Medical_History_gne__r.Rx_Expiration_gne__c;
        lfb.SMN_Expiration_Date__c = c.Medical_History_gne__r.GATCF_SMN_Expiration_Date_gne__c;
        lfb.User_Full_Name__c = UserInfo.getName();
        lfb.Case_Number_gne__c = c.CaseNumber;
lfb.Physician_Primary_Phone__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.Phone_vod__c;
        lfb.Physician_State__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.State_vod__c;
        lfb.Physician_Street_Line_1__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.Name;
        lfb.Physician_Street_Line_2__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.Address_1_gne__c;
        lfb.Physician_Zip__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.Zip_4_vod__c;
        lfb.Physician_City__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.City_vod__c;
        lfb.Physician_DEA_Number__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.DEA_vod__c;
        lfb.Physician_Fax_Number__c = c.Case_Treating_Physician_gne__r.Address_gne__pr.Fax_vod__c;
lfb.Physician__c =c.Case_Treating_Physician_gne__r.id;
system.debug('test' + c.Case_Treating_Physician_gne__r.Address_gne__pr.State_vod__c);
    //string accountid = c.Case_Treating_Physician_gne__r.id;
      //  list<Address_vod__c> con = [Select a.Zip_4_vod__c, a.State_vod__c, a.Phone_vod__c, a.Name, a.Fax_vod__c, a.DEA_vod__c, a.City_vod__c, a.Address_1_gne__c From Address_vod__c a where primary_vod__c = true and Account_vod__c = :accountid order by Name limit 1];
        //if (con.size() == 0) {
        //con = [Select a.Zip_4_vod__c, a.State_vod__c, a.Phone_gne__c, a.Name, a.Fax_vod__c, a.DEA_vod__c, a.City_vod__c, a.Address_1_gne__c From Address_vod__c a where Account_vod__c = :accountid order by Name limit 1];

  //      }
//        if (con.size() == 0) {
    //    return;
      //  }
        
        //Address_vod__c myphy = con[0];
        
    
    }
    private boolean testCase(Case c) {
        boolean rc = false;
        
        // determine if this is more recent than the current record for this case/patient
        // because of the ordering of the query -- case, patient, create date --
        // we have a candidate record if either the case or the patient value changes.
        // As the third sort key, createDate will always be the most recent when there
        // is a new patient, which will always happen when there is a new case.
        if (currentCase != c.Id) {
            setCurrentValues(c);
            rc = true;
        }
        else if (currentPatient != c.Patient_gne__r.Id) {
            setCurrentValues(c);
            rc = true;
        }            
        return(rc);
    }
    
    private void setCurrentValues(Case c) {
        currentCase = c.Id;
        currentPatient = c.Patient_gne__r.Id;
        currentCreateDate = c.CreatedDate;
    }
        
}