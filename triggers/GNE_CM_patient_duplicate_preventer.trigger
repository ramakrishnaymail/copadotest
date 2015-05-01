// BR-Patient-01
// Developed By: GDC
// Last Updated Date: 15th October 2008
//SKM Modified PAN_Form_Expiration_Flag

trigger GNE_CM_patient_duplicate_preventer on Patient_gne__c (before insert, before update) 
{

    Map<String, Patient_gne__c> lname = new Map<String, Patient_gne__c>();
    Map<String, Patient_gne__c> fname = new Map<String, Patient_gne__c>();
    Map<Date, Patient_gne__c> dob = new Map<Date, Patient_gne__c>();
    Map<String, Patient_gne__c> ssn = new Map<String, Patient_gne__c>();
    Map<String, Patient_gne__c> phone = new Map<String, Patient_gne__c>();
    Map<String, Patient_gne__c> other_phone = new Map<String, Patient_gne__c>();

    Patient_gne__c[] accs = Trigger.new;
    
    Map<String, Patient_gne__c> result = new Map<String, Patient_gne__c>();

    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1()) // Global check for static variable to make sure trigger executes only once
    {
        //This trigger will only execute if static variable is not set
        GNE_CM_case_trigger_monitor.setTriggerInProcessTrig1(); // Setting the static variable so that this trigger does not get executed after workflow update
        //***********************************************************//
        //**************** PORTAL SECTION BEGINS HERE ***************//
        //***********************************************************//
        //***********************************************************//
        for (Patient_gne__c Patient_Rec : trigger.new)
        {
            //Logic from Patient SSN display format gne
            if(Patient_Rec.ssn_gne__c != null && Patient_Rec.ssn_gne__c.length() == 9 && (system.trigger.isInsert || Patient_Rec.ssn_gne__c != trigger.OldMap.get(Patient_Rec.Id).ssn_gne__c))
            {
                Patient_Rec.ssn_gne__c = Patient_Rec.ssn_gne__c.substring(0, 3) + '-' + Patient_Rec.ssn_gne__c.substring(3, 5) + '-' + Patient_Rec.ssn_gne__c.substring(5);
            }

            If (Patient_Rec.PAN1_Expiration_Flag_gne__c == False ) 
            {
                If (system.trigger.isupdate && Patient_Rec.PAN_Form_1_Expiration_Date_gne__c != trigger.OldMap.get(Patient_Rec.Id).PAN_Form_1_Expiration_Date_gne__c)
                {
                    Patient_Rec.PAN1_Expiration_Flag_gne__c = True;
                }
                else if (system.trigger.isinsert)
                {
                    Patient_Rec.PAN1_Expiration_Flag_gne__c = True;
                }
            }else{
                //PAN1_Expiration_Flag_gne__c is true
                if(Patient_Rec.PAN_Form_1_Expiration_Date_gne__c!=null)
                {
                    Patient_Rec.PAN1_Expiration_Flag_gne__c = false;
                }
            }
            If (Patient_Rec.PAN2_Expiration_Flag_gne__c == False) 
            {
                If (system.trigger.isupdate && Patient_Rec.PAN_Form_2_Exipration_Date_gne__c != trigger.OldMap.get(Patient_Rec.Id).PAN_Form_2_Exipration_Date_gne__c)
                {
                    Patient_Rec.PAN2_Expiration_Flag_gne__c = True;
                }
                else if (system.trigger.isinsert)
                {
                    Patient_Rec.PAN2_Expiration_Flag_gne__c = True;
                }
             }else{
                //PAN2_Expiration_Flag_gne__c is true
                if(Patient_Rec.PAN_Form_2_Exipration_Date_gne__c!=null)
                {
                    Patient_Rec.PAN2_Expiration_Flag_gne__c = false;
                }
            }
        }
        
        //**********************  D E B U G **********************//
        if (!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1() && system.trigger.isupdate)
        {
            for (Patient_gne__c Patient_Rec : trigger.new)
            {
                system.debug ('****************************** UPDATED BY USER *************************');
                system.debug ('OLD: ' + trigger.OldMap.get(Patient_Rec.Id).PAN_Form_1_Expiration_Date_gne__c);
                system.debug ('NEW: ' + trigger.NewMap.get(Patient_Rec.Id).PAN_Form_1_Expiration_Date_gne__c);
                system.debug ('*************************************************************************'); 
            }
        }
        else if (GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1() && system.trigger.isupdate)
        {
            for (Patient_gne__c Patient_Rec : trigger.new)
            {
                system.debug ('****************************** UPDATED BY WORKFLOW *************************');
                system.debug ('OLD: ' + trigger.OldMap.get(Patient_Rec.Id).PAN_Form_1_Expiration_Date_gne__c);
                system.debug ('NEW: ' + trigger.NewMap.get(Patient_Rec.Id).PAN_Form_1_Expiration_Date_gne__c);
                system.debug ('*************************************************************************'); 
            }
        }
        //**********************  D E B U G **********************//
        
        //***********************************************************//
        //**************** PORTAL SECTION ENDS HERE   ***************//
        //***********************************************************//
        //***********************************************************//
        
        if (System.Trigger.isInsert)
            {
            for (Patient_gne__c acc: Trigger.new) 
                {
                    try
                        {
                            //acc.DOB_Indexed_gne__c = acc.DOB_Searchable_gne__c; //PS: 02/08/2013 for CMGTT-29 Commented   
                            //PS: 02/08/2013 for CMGTT-29  Start
                            if(acc.DOB_Searchable_gne__c != null)
                            acc.DOB_Indexed_gne__c = String.Valueof(Date.Valueof(acc.DOB_Searchable_gne__c).format()); 
                            //PS: 02/08/2013 for CMGTT-29  End
                            if (!lname.containsKey(acc.Name)) 
                                {
                                    lname.put(acc.Name, acc);
                                }
                            if (!fname.containsKey(acc.pat_first_name_gne__c))
                                {
                                    fname.put(acc.pat_first_name_gne__c, acc);
                                }
                            if (!ssn.containsKey(acc.ssn_gne__c))
                                {
                                    ssn.put(acc.ssn_gne__c, acc);
                                }
                            if (!phone.containsKey(acc.pat_home_phone_gne__c)) 
                                {
                                    phone.put(acc.pat_home_phone_gne__c, acc); 
                                }
                            if (!dob.containsKey(acc.pat_dob_gne__c)) 
                                {
                                    dob.put(acc.pat_dob_gne__c, acc); 
                                }
                            if (!other_phone.containsKey(acc.pat_other_phone_gne__c)) 
                                {
                                    other_phone.put(acc.pat_other_phone_gne__c, acc); 
                                }
                        }   //end of try
                    catch(exception e)
                        {
                                acc.adderror('Unexpected error in trigger patient_duplicate_preventer_gne.');
                        }   //end of catch
                }//End of for
          
                result = GNE_CM_patientduplicatecheck.resultset(accs, lname, fname, phone, ssn, dob, other_phone);
                for (integer i=0; i < result.size();i++) 
                    {    
                        if (result.containsKey('1:'+i)) 
                        result.get('1:'+i).addError('Patient with same first name, last name, DOB, SSN and phone numbers exists! Please enter different values.');
                    }//End of Result For 
                                   
             }//End of If Insert 
    
        if (System.Trigger.isUpdate)
            {
                for (Patient_gne__c acc: System.Trigger.new) 
                {
                    try
                        {
                            //acc.DOB_Indexed_gne__c = acc.DOB_Searchable_gne__c;  //PS: 02/08/2013 for CMGTT-29 Commented
                            //PS: 02/08/2013 for CMGTT-29 Start
                            if(acc.DOB_Searchable_gne__c != null)
                            acc.DOB_Indexed_gne__c = String.Valueof(Date.Valueof(acc.DOB_Searchable_gne__c).format()); 
                             //PS: 02/08/2013 for CMGTT-29 End
                            if (acc.Name != System.Trigger.oldMap.get(acc.Id).Name
                            || acc.pat_first_name_gne__c != System.Trigger.oldMap.get(acc.Id).pat_first_name_gne__c
                            || acc.ssn_gne__c != System.Trigger.oldMap.get(acc.Id).ssn_gne__c
                            || acc.pat_home_phone_gne__c != System.Trigger.oldMap.get(acc.Id).pat_home_phone_gne__c
                            || acc.pat_dob_gne__c != System.Trigger.oldMap.get(acc.Id).pat_dob_gne__c
                            || acc.pat_other_phone_gne__c != System.Trigger.oldMap.get(acc.Id).pat_other_phone_gne__c) 
                                {
                                if (!lname.containsKey(acc.Name)) 
                                    {
                                    lname.put(acc.Name, acc);
                                    }
                                if (!fname.containsKey(acc.pat_first_name_gne__c) )
                                    {
                                    fname.put(acc.pat_first_name_gne__c, acc);
                                    }
                                if (!ssn.containsKey(acc.ssn_gne__c) )
                                    {
                                    ssn.put(acc.ssn_gne__c, acc);
                                    }
                                if (!phone.containsKey(acc.pat_home_phone_gne__c) ) 
                                    {
                                    phone.put(acc.pat_home_phone_gne__c, acc);
                                    }
                                if (!dob.containsKey(acc.pat_dob_gne__c)) 
                                    {
                                    dob.put(acc.pat_dob_gne__c, acc);
                                    }
                                if (!other_phone.containsKey(acc.pat_other_phone_gne__c) ) 
                                    {
                                    other_phone.put(acc.pat_other_phone_gne__c, acc);
                                    }
                                }//End of If
                                  
                        }   //end of try
                    catch(exception e)
                        {
                            acc.adderror('Unexpected error in trigger patient_duplicate_preventer_gne.');
                        }   //end of catch
                }//End of For Loop
            
                result = GNE_CM_patientduplicatecheck.resultset(accs, lname, fname, phone, ssn, dob, other_phone);
               
                for (integer i = 0; i < result.size(); i++) 
                    {   
                        if (result.containsKey('0000'))
                            {
                                Trigger.new[0].addError('Unexpected error has occured in class patientduplicatecheck  ' + result.get('0000').pat_first_name_gne__c);
                            }
                        else if (result.containsKey('1:' + i))
                            {
                                result.get('1:' + i).addError('Patient with same first name, last name, DOB, SSN and phone number exists! Please enter different values.');
                            }
                    }//End of Result For 
                  
            }//End of Else Update
            
        //***********************************************************//           
        //**************** Clear maps. ******************************//
        //***********************************************************//
        lname.clear();
        fname.clear();
        phone.clear();
        ssn.clear();
        dob.clear();
        other_phone.clear();
        result.clear();
    }   //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1())

}