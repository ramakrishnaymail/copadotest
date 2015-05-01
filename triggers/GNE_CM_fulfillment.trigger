// Name of trigger : GNE_CM_fulfillment
// Created by : Ravinder Singh(GDC)
// Last Modified on :11/05/2008
// Last Modified By: Vineet Kaul 
// System should only allow a user to create one fulfilment record per case. 
// The system should prevent a user from adding a second fulfilment record. 
// Modified By: Shweta Bhardwaj 10/23/2008: Restrict user from editing Fulfillment when case
// has been closed for 48 hours or more
// Modified by : Vineet Kaul (OFFSHORE 243)
// Modified by : Kanima Singh : 2/11/2011: to allow user to create multiple fulfillment records for single case 

trigger GNE_CM_fulfillment on Fulfillment_gne__c (before insert, before update)
{
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    Id PrevId = null;
    Set<Id> idset = new Set<Id>(); 
    List<Fulfillment_gne__c> fulfil = new List<Fulfillment_gne__c>();
    String code_status;
    Map<Id, Case> Case_map; 
    Map<Id, Account> FulAccount = new Map<Id, Account>();
    Map<Id, Account> FulAccountInOut;
    List<Id> fulaccset = new List<Id>();
    Set<Id> PrevAcc = new Set<Id>();
    Account temp_acc;
    String Contact_Name;
    string Contact_Fax;
    string Contact_Phone; 
    Integer tmp1 = 0;
    Integer tmp2 = 0;
    Boolean tmpbool = false;
    Set<string> variable = new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'};
    List<Environment_Variables__c> env_var = new List<Environment_Variables__c>();
    Map<String, String> Case_Profiles = new Map<String, String>();
    String ProfileId = Userinfo.getProfileId();
    string Profile_name ='';
    List<Environment_Variables__c>envVarList = new List<Environment_Variables__c>();
    
    try
    {
    
    // ********************************************************************//
    // Code to check Reason Treatment Not started validation **************//  
    // ********************************************************************//
    code_status = 'Code to check Reason Treatment Not started validation';
    for(Fulfillment_gne__c ful : Trigger.new)
        {         
        if(ful.Did_Patient_Start_Treatment_gne__c == 'No' && ful.Reason_Treatment_Not_Started_gne__c == null)
            {
                ful.adderror('Please fill in Reason Treatment Not started.');
            }
        }
    
    
    
    // ********************************************************************//
    // Generate a list of all case IDs from fulfilment. **************//  
    // ********************************************************************//  
    code_status = 'Generate a list of all case IDs from fulfilment'; 
    for(Fulfillment_gne__c ful : Trigger.new)
    {
        if (ful.Case_Fulfillment_gne__c != null && ful.Case_Fulfillment_gne__c != PrevId)
            {
                idset.add(ful.Case_Fulfillment_gne__c);
                PrevId = ful.Case_Fulfillment_gne__c;
            }   //end of if
    }
    
    
    
    // ***************************************************************
    // Run SOQL for the checks.
    // ***************************************************************
    code_status = 'Run SOQL for the checks.'; 
    fulfil = [Select Id, Case_Fulfillment_gne__c from Fulfillment_gne__c where 
            Case_Fulfillment_gne__c IN :idset];
      
    Case_map = new Map<Id, Case>([select CaseNumber, patient_gne__c, status, closeddate,Product_gne__c from Case where Id IN :idset]);
            
    
    // **************************************************************//
    // ******************Code to check 48 hrs validation*************//
    // **************************************************************//
    code_status = 'Code to check 48 hrs validation'; 
    Profile_name = [select name from Profile where Id =:profileId limit 1].Name;
    env_var = GNE_CM_Environment_variable.get_env_variable(variable);
    
    for (integer MI = 0; MI<env_var.size(); MI++)
    {   
        if (env_var[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
        Case_Profiles.put(env_var[MI].Value__c, env_var[MI].Value__c);
    }
    
    for(Fulfillment_gne__c ful : Trigger.new)
     {
        if(ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c))
        {   
            if(Case_map.get(ful.Case_Fulfillment_gne__c).Status.startsWith('Closed') && System.now() >= (Case_map.get(ful.Case_Fulfillment_gne__c).ClosedDate.addDays(2)) && Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)))   
            {
                ful.adderror('Fulfillment cannot be created/edited once associated case has been Closed for 48 hours or more.');
            }
        }   
     }
     
    // **************************************************************//
    // ******************Code to stamp patient***********************//
    // **************************************************************//
    code_status = 'Code to stamp patient';
       for(Fulfillment_gne__c ful : Trigger.new)
        {
        if(ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c))
            {                       
                ful.Patient_fulfillment_gne__c = Case_map.get(ful.Case_Fulfillment_gne__c).patient_gne__c;
            }   
        }
    
    // **************************************************************************
    // Update address even if account have not been changeed in crrect operation.
    // Address would be updated on each Fulfilment update.
    // **************************************************************************
    code_status = 'Set tmpbool = true for update operation';
    if (trigger.isUPDATE)
    {       
        tmpbool = true;
    }
    
    // ***************************************************************
    // If fields have been updated in the earlier step, then create a 
    // account id list for getting details.
    // ***************************************************************
    
     code_status = 'account id list for getting details';
    if (trigger.isINSERT || tmpbool == true)
    {
    for(Fulfillment_gne__c ful : Trigger.new)
    {
        //system.assertequals (PrevAcc.size(), 1);
        if (ful.In_network_name_gne__c != null && !PrevAcc.contains(ful.In_network_name_gne__c))
            {
                fulaccset.add(ful.In_network_name_gne__c);
                PrevAcc.add(ful.In_network_name_gne__c);
            }   //end of if
        if (ful.Out_network_Name_gne__c != null && !PrevAcc.contains(ful.Out_network_Name_gne__c))
            {
                fulaccset.add(ful.Out_network_Name_gne__c);
                PrevAcc.add(ful.Out_network_Name_gne__c);
            }   //end of if
        if (ful.alt_site_of_treatment_name_gne__c != null && !PrevAcc.contains(ful.alt_site_of_treatment_name_gne__c))
            {
                fulaccset.add(ful.alt_site_of_treatment_name_gne__c);
                PrevAcc.add(ful.alt_site_of_treatment_name_gne__c);
            }   //end of if  
    }   //end of for
    } // end of if


    // ***************************************************************
    // Run SOQL for gettin account details.
    // ***************************************************************    
    code_status = 'Run SOQL for getting account details';
    if ((fulaccset.size() > 0) && (trigger.isINSERT || tmpbool == true))
    {
        FulAccount = new Map<Id, Account>([SELECT Id, Account.Name, Account.Fax, Account.Phone,
                    (SELECT Contact.Id, Contact.Name, Contact.C_R_Specific_gne__c, Contact.Is_Primary_for_gne__c, 
                            Contact.phone, Contact.fax, Contact.Drug_gne__c FROM Contacts) 
                            FROM Account WHERE Account.Id IN :fulaccset]);
   
    }
    
    // ***************************************************************//
    // *******************Check if multiple contacts exist for the ***//
    // ***** account. If does then delete account from list   ********//
    // ***************************************************************//
    
    If (FulAccount != null && !FulAccount.IsEmpty()) 
    {
        FulAccountInOut = FulAccount.deepClone();
        for(Fulfillment_gne__c ful : Trigger.new)
        {
            code_status = 'Check if multiple contacts exist for In Network';
            temp_acc = FulAccount.get(ful.In_network_name_gne__c);
            if (temp_acc != null)
            {
            for (Contact cont : temp_acc.Contacts)
                {
                    if (ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c) 
                        && cont.Is_Primary_for_gne__c != null && cont.Is_Primary_for_gne__c.contains('C&R') && Cont.C_R_Specific_gne__c == True
                        && cont.Drug_gne__c != null && Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c!=null 
                        && cont.Drug_gne__c.indexof(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c) != -1)
                    {
                        tmp1 = tmp1 + 1;
                    }
                } 
            }
            if (tmp1 > 1)  
            {
                FulAccountInOut.remove(ful.In_network_name_gne__c);
            }
            
            code_status = 'Check if multiple contacts exist for Out Network';
            temp_acc = FulAccount.get(ful.Out_network_name_gne__c);
            
            if (temp_acc != null)
            {
            for (Contact cont : temp_acc.Contacts)
                {
                    if (ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c)
                        && cont.Is_Primary_for_gne__c != null && cont.Is_Primary_for_gne__c.contains('C&R') && Cont.C_R_Specific_gne__c == True
                        && cont.Drug_gne__c != null && Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c!=null
                        && cont.Drug_gne__c.indexof(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c) != -1)
                    {
                        tmp2 = tmp2 + 1;
                    }
                }   
            }
            if (tmp2 > 1)  
            {
                FulAccountInOut.remove(ful.Out_network_name_gne__c);
            }
            
            code_status = 'Reset multiple check variables.';
            tmp1 = 0;
            tmp2 = 0;
            temp_acc = null;
        }
    }
    
    // ***************************************************************//
    // *******************Code to get the In Details.*****************//
    // ***************************************************************//
    code_status = 'Code to get the In Details';
    for(Fulfillment_gne__c ful : Trigger.new)
    {
        If ((fulaccset.size() > 0) && (trigger.isINSERT || tmpbool == true))
        {
            if ((ful.In_network_name_gne__c != null) && (FulAccountInOut.containsKey(ful.In_network_name_gne__c)))
            {
            Contact_Name = '';
            Contact_Fax = '';
            Contact_Phone = '';
            temp_acc = FulAccountInOut.get(ful.In_network_name_gne__c);
            
                if(ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c))
                {
                    if(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c!=null)
                    { 
                        for (Contact cont : temp_acc.Contacts)
                        {
                            if (cont.Is_Primary_for_gne__c != null && cont.Is_Primary_for_gne__c.contains('C&R') 
                                && cont.C_R_Specific_gne__c == true && cont.Drug_gne__c != null 
                                && cont.Drug_gne__c.indexof(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c) != -1)
                            {
                                Contact_Name = cont.Name;
                                Contact_Fax = cont.Fax;
                                Contact_Phone = cont.Phone;                    
                                break;
                            }
                        }
                    }
                } 
                       
            if (Contact_Name == '' || Contact_Name == null) 
            {
                ful.In_network_Contact_Name_gne__c = '';
            } 
            else 
            {
                ful.In_network_Contact_Name_gne__c = Contact_Name;
            }
            
            if (Contact_Fax == '' || Contact_Fax == null) 
            {
                ful.In_network_Fax_Number_gne__c = '';
            } 
            else 
            {
                ful.In_network_Fax_Number_gne__c = Contact_Fax;
            }
            
            if (Contact_Phone == '' || Contact_Phone == null) 
            {
                ful.In_network_Phone_Number_gne__c = '';
            } 
            else 
            {
                ful.In_network_Phone_Number_gne__c = Contact_Phone;
            }
        }
        else
        {
            ful.In_network_Contact_Name_gne__c = '';
            ful.In_network_Fax_Number_gne__c = '';
            ful.In_network_Phone_Number_gne__c = '';
        }

        // ***************************************************************//
        // *******************Code to get the Out Details.****************//
        // ***************************************************************//
        
        code_status = 'Code to get the Out Details';
        if ((ful.Out_network_name_gne__c != null) && (FulAccountInOut.containsKey(ful.Out_network_Name_gne__c)))
        {
        Contact_Name = '';
        Contact_Fax = '';
        Contact_Phone = '';
        temp_acc = FulAccountInOut.get(ful.Out_network_Name_gne__c);

            if(ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c))
            {
                if(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c!=null)
                { 
                    for (Contact cont : temp_acc.Contacts)
                    {
                        if (cont.Is_Primary_for_gne__c != null && cont.Is_Primary_for_gne__c.contains('C&R') 
                            && cont.C_R_Specific_gne__c == true && cont.Drug_gne__c != null 
                            && cont.Drug_gne__c.indexof(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c) != -1)
                        {
                            Contact_Name = cont.Name;
                            Contact_Fax = cont.Fax;
                            Contact_Phone = cont.Phone;                    
                            break;
                        }
                    }
                }
            }
                        
            if (Contact_Name == '' || Contact_Name == null) 
            {
                ful.Out_network_Contact_Name_gne__c = '';
            }
            else 
            {
                ful.Out_network_Contact_Name_gne__c = Contact_Name;
            }
            
            if (Contact_Fax == '' || Contact_Fax == null) 
            {
                ful.Out_network_Fax_Number_gne__c = '';
            }
            else 
            {
                ful.Out_network_Fax_Number_gne__c = Contact_Fax;
            }
            
            if (Contact_Phone == '' || Contact_Phone == null) 
            {
                ful.Out_network_Phone_Number_gne__c = '';
            }
            else 
            {
                ful.Out_network_Phone_Number_gne__c = Contact_Phone;
            }
        }
        else
        {
            ful.Out_network_Contact_Name_gne__c = '';
            ful.Out_network_Fax_Number_gne__c = '';
            ful.Out_network_Phone_Number_gne__c = '';
        }


            //********************************************//
            //***** Alternate Site processing ************//
            //********************************************//
            if (FulAccount.containsKey(ful.alt_site_of_treatment_name_gne__c))
            {
            Contact_Name = '';
            Contact_Fax = '';
            Contact_Phone = '';
            temp_acc = FulAccount.get(ful.alt_site_of_treatment_name_gne__c);
            //ful.alt_site_of_treat_fax_number_gne__c = temp_acc.Fax;
            //ful.alt_site_of_treat_number_gne__c = temp_acc.Phone;
            
            if(ful.Case_Fulfillment_gne__c != null && Case_map.containsKey(ful.Case_Fulfillment_gne__c))
            {
                if(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c!=null)
                { 
                    for (Contact cont : temp_acc.Contacts)
                    {
                        if (cont.C_R_Specific_gne__c == true && cont.Drug_gne__c !=null 
                            && cont.Drug_gne__c.indexof(Case_map.get(ful.Case_Fulfillment_gne__c).Product_gne__c) != -1)
                        {
                            Contact_Name = cont.Name;
                            Contact_Fax = cont.Fax;
                            Contact_Phone = cont.Phone;                    
                            break;
                        }
                    }
                }
            }
                        
            if (Contact_Name == '' || Contact_Name == null) 
            {
                ful.alt_site_of_treat_contact_name_gne__c = '';
            } 
            else 
            {
                ful.alt_site_of_treat_contact_name_gne__c = Contact_Name;
            } 
            
            if (Contact_Fax == '' || Contact_Fax == null) 
            {
                ful.alt_site_of_treat_fax_number_gne__c = '';
            } 
            else 
            {
                ful.alt_site_of_treat_fax_number_gne__c = Contact_Fax;
            }
            
            if (Contact_Phone == '' || Contact_Phone == null) 
            {
                ful.alt_site_of_treat_number_gne__c = '';
            } 
            else 
            {
                ful.alt_site_of_treat_number_gne__c = Contact_Phone;
            }          
            }
        }
    }


    /****SB: Added on 4/23/2009****/   
     
    code_status = 'Check either of IN / OUT Selected Distributor is set to Yes.';
    for(Fulfillment_gne__c ful : Trigger.new)
    {
        if (ful.In_network_name_gne__c != null && (ful.In_network_Selected_Distributor_gne__c == 'No' || ful.In_network_Selected_Distributor_gne__c == null))
            {
                if(ful.Out_network_Name_gne__c != null && (ful.Out_network_Selected_Distributor_gne__c == 'No' || ful.Out_network_Selected_Distributor_gne__c == null))
                ful.adderror('Selected distributor for either In Network or Out of Network should be set to "Yes".');
                else if(ful.Out_network_Name_gne__c == null)
                ful.In_network_Selected_Distributor_gne__c = 'Yes';
            }
        else if(ful.In_network_name_gne__c == null && ful.Out_network_Name_gne__c != null && (ful.Out_network_Selected_Distributor_gne__c == 'No' || ful.Out_network_Selected_Distributor_gne__c == null))
             ful.Out_network_Selected_Distributor_gne__c = 'Yes';
             
        // To NULL OUT the contact fields if corresponding distributor is cleared out
        
         if(ful.Out_network_Name_gne__c == null )
        {
            ful.Out_network_Contact_Name_gne__c = '';
            ful.Out_network_Fax_Number_gne__c = '';
            ful.Out_network_Phone_Number_gne__c = '';
        }
        if(ful.In_network_name_gne__c == null )
        {
            ful.In_network_Contact_Name_gne__c = '';
            ful.In_network_Fax_Number_gne__c = '';
            ful.In_network_Phone_Number_gne__c = '';
        }
    }
    // *********************************************************//
    // *******************Check for duplicate case.*************//
    // *********************************************************//
    // KS: 2/11/2011 - Commented out below lines to allow users to create multiple Fulfillment records per case.
    // KS: 1/30/2012 - Added the blow logic as part of vismo/erivedge post production launch.
    envVarList = [select id, key__c, value__c from Environment_Variables__c where key__c = 'Allow Multiple Fulfillment'];
    code_status = 'Check for duplicate case';
    if(envVarList[0].value__c == 'No')
    {
        if (trigger.isUPDATE)
            {
            for (Fulfillment_gne__c ful : Trigger.new)
                {
                    for(Fulfillment_gne__c fil : fulfil)
                        {
                            if (fil.Case_Fulfillment_gne__c == ful.Case_Fulfillment_gne__c && fil.Id != ful.Id)
                            {
                                ful.adderror('Case is associated with a different fulfilment.');
                            }
                        }   //end of try
                }
            }
        else if (trigger.isINSERT)
            {
            for (Fulfillment_gne__c ful : Trigger.new)
                {
                    for(Fulfillment_gne__c fil : fulfil)
                        {
                            if (fil.Case_Fulfillment_gne__c == ful.Case_Fulfillment_gne__c)
                            {
                                ful.adderror('Case is associated with a different fulfilment.');
                            }
                        }   //end of try
                }
            }
         //KS: Modifications end here   
    }
    }
    catch (exception e)
    {
        for (Fulfillment_gne__c ful : Trigger.new)
        {ful.adderror('Error has occured in trigger. : [pointer: ' + code_status + ']Error :' + e.getMessage());}
    }
    Case_Profiles.clear();  
    Case_map.clear();   //to clear the map once trigger records had been processed
    idset.clear();  //to clear the set once trigger records had been processed  
    fulfil.clear(); //to clear the set once trigger records had been processed
    
}   //end of trigger