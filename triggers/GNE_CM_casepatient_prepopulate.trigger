/*--Last Modified By: nadinel, 05/28/2009--*/ 
/*--Moved Vendor Requirements to GNE_CM_Casepatient_Validation_Check class--*/
//GDC - 11/16/2009, Modified code to implement GATCF validations for GES Cases
//MDME - 10/1/2013, Removed Rules (line 352 - 403) around Insurance Eligibility Document fields

trigger GNE_CM_casepatient_prepopulate on Case (before insert, before update, after insert, after update)
{    
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode())
    {
        return;
    }

    //skip this trigger if it is triggered from transfer wizard
    if (GNE_CM_MPS_TransferWizard.isDisabledTrigger)
    {
        System.debug('Skipping trigger GNE_CM_casepatient_prepopulate');
        return;
    }

    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_casepatient_prepopulate'))
    {
        return;
    }
    
    List<Id> MHidset = new List<Id>();  
    Id prevMHId = null ;
    Set<Id> Case_Id_Set=new Set<Id>();
    Id prevcaseId=null;
    Map<Id, Medical_History_gne__c> Medical_History_map;
    //Profile profile_name =new Profile();
    String profile_name=''; //JH 10/21/2013 - SOQL Optimization
    Integer pendingbiflg=0;
    Integer pendingapplvlflg=0;
    Integer pendingclaimflg=0;
    List<Task> openactivitylist=new List<Task>();
    Integer ship_flag=0;
    Integer inf_flag=0;
    Case caseid=new Case();    
    Set<Id> casupdids=new Set<Id>(); 
    List<Case> cases = new List<Case>();
    String whtid=''; 
    List<String> eligibilityDocumentType = new List<String>(); //JH MDME
    String paobjid=Schema.SObjectType.Prior_authorization_gne__c.getKeyPrefix(); 
    Map<String, Schema.RecordTypeInfo> caseRecordType = new Map<String, Schema.RecordTypeInfo>();   
    caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName();
 
    public static Id gatcfStandardCaseRecordTypeId = caseRecordType.get(GNE_CM_Case_Dictionary.RECORD_TYPE_GATCF).getRecordTypeId();
    public static Id ccpCaseRecordTypeId = caseRecordType.get(GNE_CM_Case_Dictionary.RECORD_TYPE_CONTINUOUS_CARE).getRecordTypeId();
    public static Id gesCaseRecordTypeId = caseRecordType.get(GNE_CM_Case_Dictionary.RECORD_TYPE_GES).getRecordTypeId();
    public static Id crCaseRecordTypeId = caseRecordType.get(GNE_CM_Case_Dictionary.RECORD_TYPE_STANDARD).getRecordTypeId();
    
    List<CaseShare> caseshare_list = new  List<CaseShare>();
    string[] documentation_vals = new string[]{};
    integer missing_flag=0;
    Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
    
    //KS: 10/27/2011: Added Vismodegib condition
    String vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    
    //KS: modifications end here 
    //KS: Pertuzumab- Herceptin Combo Clone
    string Pertuzumab_product_Name = system.label.GNE_CM_Pertuzumab_Product_Name;  
    string Foundation_Specialist = system.label.GNE_CM_Foundation_Specialist;
    
    public String SnippetName ='', PatId = null, MedHistoryId = null, ParentCaseId = null, ChildCaseId = null;
    
    //Adding the following condition for bypassing trigger when the case is transferrred
    //wilczekk: why aren't we simply using (trigger.isBefore) ?
    if (!trigger.isAfter)
    {
        if (!GNE_CM_MPS_Transfer_Helper.bypassTriggers)
        {
            //krzyszwi 2010-09-13 - logic for population of Coverage Status when cloning from C&R to GATCF case
            //the logic is just for cloning with clone button - no bulk updates
            if (trigger.isInsert && trigger.new.size() == 1)
            {       
                string relatedCaseID = trigger.new[0].Related_C_R_Case_gne__c;
                if (relatedCaseID != null && relatedCaseID.length() > 0 && trigger.new[0].RecordTypeId == gatcfStandardCaseRecordTypeId)
                {
                    trigger.new[0].Cvg_gne__c = [SELECT Cvg_gne__c FROM Case WHERE id =: trigger.new[0].Related_C_R_Case_gne__c].Cvg_gne__c;
                }   
            }   
            
            for (Case casowr : Trigger.new) 
            {
                if (casowr.After_Trigger_Flag_gne__c == false)
                {
                    casupdids.add(casowr.Id);
                }    
            }      
            
            if (casupdids.size() > 0)   
            {
                profile_name = GNE_SFA2_Util.getCurrentUserProfileName();
                                      
                for (Case cas :Trigger.new)
                {
                    try
                    {   
                        if (cas.Medical_History_gne__c!=null && prevMHId != cas.Medical_History_gne__c)
                        {
                            MHidset.add(cas.Medical_History_gne__c);
                            prevMHId = cas.Medical_History_gne__c;
                        }
                        if (prevcaseId != cas.Id)
                        {   
                            case_id_set.add(cas.Id);
                            prevcaseId = cas.Id;
                        }  
                    }                                       
                    catch (Exception e)
                    {
                        cas.addError('Error encountered while creating Medical histroy/Case set' +e.getmessage());
                    }   
                }
    
                try
                {
                    Medical_History_map = new Map<Id, Medical_History_gne__c>([SELECT ICD9_Code_1_gne__r.Name,ICD9_Code_1_gne__r.ICD9_Descrption_gne__c,ICD9_Code_2_gne__r.Name,ICD9_Code_2_gne__r.ICD9_Descrption_gne__c, ICD9_Code_3_gne__r.Name,ICD9_Code_3_gne__r.ICD9_Descrption_gne__c, Patient_Med_Hist_gne__c, Recordtype.Name, ICD9_Code_1_gne__c, ICD9_Code_2_gne__c, ICD9_Code_3_gne__c from Medical_History_gne__c where Id in :MHidset]);
                }
                catch (Exception e)
                {
                    for (Case cs :Trigger.new)
                    {
                        cs.addError('Error encountered while creating Medical History Map' + e.getmessage());
                    }
                }
                
                // iterate through all cases in the trigger
                for (Case cas :Trigger.new)
                {
                    try
                    {
                        // Profiles check before creating GACTF Stnd case
                        // To check profiles only while inserting cases
                        if (trigger.isInsert)
                        {
                            // names of profiles that are allowed to created GATCF cases
                            // Note: they all have to be in upper case
                            
                            Set<String> profilesAllowedToCreateGatcfCases = new Set<String> {   'GNE-CM-REIMBSPECIALIST', 'GNE-CM-APPEALSSPECIALIST', 'GNE-CM-INTAKE',
                                                                                                'GNE-CM-CASEMANAGER', 'GNE-CM-GATCFFS', 'GNE-CM-CRMANAGER', 'GNE-CM-CRSUPERVISOR',
                                                                                                'GNE-CM-GATCFINTAKE', 'SYSTEM ADMINISTRATOR', 'GNE-CM-GATCFMANAGER', 'GNE-CM-GATCFSUPERVISOR',
                                                                                                'GNE-SYS-AUTOMATEDJOB', 'GNE-SYS-SUPPORT', 'GNE-SFA-InternalUser', 'GNE-CM-INTAKESUPERVISOR', 'GNE-CM-BA'};
                                                                                                
                            if (!profilesAllowedToCreateGatcfCases.contains(profile_name.toUpperCase()) && (cas.RecordTypeId == gesCaseRecordTypeId || cas.RecordTypeId == gatcfStandardCaseRecordTypeId))
                            {
                                cas.adderror('You do not have permissions to create GATCF cases. Please contact the identified Specialist or Manager for assistance.');
                            }
                            
                            if (cas.RecordTypeId == gesCaseRecordTypeId && cas.GES_Status_gne__c !=null && (cas.GES_Status_gne__c == 'Approved' || cas.GES_Status_gne__c =='Denied'))
                            {
                                cas.Approval_Denial_Date_gne__c = system.now();
                            }
                            
                            //SB - 11/13: moved logic from Field Update wrkflw Referred to Vendor/SP: Workflow created to support AS - Report : Triaged Cases
                            if (cas.RecordTypeId != gesCaseRecordTypeId && cas.RecordTypeId != gatcfStandardCaseRecordTypeId && cas.RecordTypeId != ccpCaseRecordTypeId)
                            {
                                if (cas.case_being_worked_by_gne__c != null && cas.case_being_worked_by_gne__c != 'GENENTECH')
                                {
                                    cas.Referred_to_Vendor_SP_gne__c = system.now();
                                }                
                            }
                        }
                        else if (trigger.isUpdate)// To check profiles only while updating cases
                        {
                            // names of profiles that are allowed to created GATCF cases
                            // Note: they all have to be in upper case
                            
                            Set<String> profilesAllowedToUpdateGatcfCases = new Set<String> { 'GNE-CM-REIMBSPECIALIST', 'GNE-CM-APPEALSSPECIALIST', 'GNE-CM-INTAKE',
                                                                                              'GNE-CM-CASEMANAGER', 'GNE-CM-GATCFFS', 'GNE-CM-CRMANAGER',
                                                                                              'GNE-CM-CRSUPERVISOR', 'GNE-CM-GATCFINTAKE', 'SYSTEM ADMINISTRATOR',
                                                                                            'GNE-CM-GATCFMANAGER', 'GNE-CM-GATCFSUPERVISOR', 'GNE-CM-INTAKESUPERVISOR', 'GNE-CM-BA', 'GNE-CM-IHCP-PROFILE' };
                            
                            Boolean isProfileAllowedToEdit = profilesAllowedToUpdateGatcfCases.contains(profile_name.toUpperCase()) || profile_name.startsWith('GNE-SYS') || profile_name == 'GNE-SFA-InternalUser' || profile_name.startsWithIgnoreCase('GNE-SFA-OPS'); 
                            
                            if (!isProfileAllowedToEdit && (cas.RecordTypeId == gesCaseRecordTypeId || cas.RecordTypeId == gatcfStandardCaseRecordTypeId))
                            {
                                cas.addError('You do not have permissions to update GATCF cases. Please contact the identified Specialist or Manager for assistance.');
                            }
                            
                            if (cas.RecordTypeId == gesCaseRecordTypeId && cas.GES_Status_gne__c != null && (cas.GES_Status_gne__c != system.trigger.oldmap.get(cas.Id).GES_Status_gne__c || cas.Approval_Denial_Date_gne__c == null) 
                                    && (cas.GES_Status_gne__c == 'Approved' || cas.GES_Status_gne__c =='Denied'))
                            {
                                cas.Approval_Denial_Date_gne__c = system.now();
                            }
                            
                            //SB - 11/13: moved logic from Field Update wrkflw Referred to Vendor/SP: Workflow created to support AS - Report : Triaged Cases
                            if (cas.RecordTypeId != gesCaseRecordTypeId && cas.RecordTypeId != gatcfStandardCaseRecordTypeId && cas.RecordTypeId != ccpCaseRecordTypeId)
                            {
                                if (cas.case_being_worked_by_gne__c!=null && cas.case_being_worked_by_gne__c != system.trigger.oldmap.get(cas.Id).case_being_worked_by_gne__c && cas.case_being_worked_by_gne__c != 'GENENTECH')
                                {
                                    cas.Referred_to_Vendor_SP_gne__c = system.now();
                                }                
                            }
                        }
                                
                        //Case Manager cannot be changed once it has been assigned to Case Owner    
                        if (trigger.isUpdate)
                        {
                            if (trigger.oldmap.get(cas.Id).Case_manager__c != null && cas.Case_manager__c != trigger.oldmap.get(cas.Id).Case_manager__c)
                            {
                                cas.adderror('Case Ownership should be performed via the Change Owner link');
                            }  
                            
                            if (trigger.oldmap.get(cas.Id).Foundation_Specialist_gne__c != null && cas.Foundation_Specialist_gne__c != trigger.oldmap.get(cas.Id).Foundation_Specialist_gne__c)
                            {
                                cas.adderror('Case Ownership should be performed via the Change Owner link');
                            }  
                            
                            if (cas.RecordTypeId == gatcfStandardCaseRecordTypeId || cas.RecordTypeId == gesCaseRecordTypeId)   // added for Offshore Request 282 and Defect # 8687
                            {   
                                cas.Foundation_Specialist_gne__c = cas.ownerid;
                            }
                            else
                            { 
                                cas.Case_manager__c = cas.ownerid;
                            }
                        }
                                        
                    /*
                    Genentech_Owner_gne__c deleted - lookup reused
                    //Case Being Worked By Req.               
                    if(cas.case_being_worked_by_gne__c !=null)
                    {
                        if (cas.Case_Being_Worked_By_gne__c == 'EXTERNAL - MCKESSON' && (cas.Function_Performed_gne__c == 'Benefits Investigation' || cas.Function_Performed_gne__c == 'Appeals Follow-up') 
                                && cas.Vendor_name_gne__c !=null && cas.Genentech_owner_gne__c ==null)
                        {
                            cas.Genentech_owner_gne__c = cas.OwnerId;
                        }
                    }                 
                    */
                        if (cas.Medical_History_gne__c!=null && Medical_History_map.containsKey(cas.Medical_History_gne__c) && GNE_CM_MedicalEligibilityHelper.isMedicalEligibilityEditableForCase( cas ) == true)
                        {
                            cas.patient_gne__c=Medical_History_map.get(cas.Medical_History_gne__c).Patient_Med_Hist_gne__c;   
                            
                            //if (cas.Product_gne__c != 'Herceptin')
                            {
                                cas.Product_gne__c=Medical_History_map.get(cas.Medical_History_gne__c).Recordtype.Name;
                            }
    
                            if (Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_1_gne__c!=null)
                            {
                                cas.Diagnosis_gne__c = Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_1_gne__r.Name;
                            }
                            else
                            {
                                cas.Diagnosis_gne__c ='';
                            }
        
                            if (Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_2_gne__c!=null)
                            {
                                cas.ICD9_Code_2_gne__c = Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_2_gne__r.Name;
                            }
                            else
                            {
                                cas.ICD9_Code_2_gne__c ='';
                            }
        
                            if (Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_3_gne__c!=null)
                            {
                                cas.ICD9_Code_3_gne__c = Medical_History_map.get(cas.Medical_History_gne__c).ICD9_Code_3_gne__r.Name;
                            }
                            else
                            {
                                cas.ICD9_Code_3_gne__c ='';
                            }  
                            
                            system.debug('inProcess-----' + GNE_CM_case_trigger_monitor.triggerIsInProcess());                      
                        }
                        
                        //end of cas.Medical_History_gne__c!=null                  
                                                                                
                        // Validation for Enrollment Not Complete Reason           
                        if (cas.Enroll_Comp_Original_Receipt_gne__c=='No' && cas.Enrollment_Not_Complete_Reason_gne__c==null)
                        {
                            cas.adderror('Please select values for Enrollment Not Complete Reason from available picklist values.');
                        }
                            
                        // Validation for Primary Case Manager
                        if (cas.RecordTypeId == crCaseRecordTypeId && cas.Case_Manager__c == null)
                        {
                            cas.adderror('Primary Case Manager is required field.');
                        }
                         
                        //Validation for Foundation Specialist
                        if (cas.RecordTypeId == gatcfStandardCaseRecordTypeId && cas.Foundation_Specialist_gne__c == null)
                        {
                            cas.adderror('Foundation Specialist is required field.');
                        } 
                                                     
                        
                        if (cas.RecordTypeId == gesCaseRecordTypeId || cas.RecordTypeId == gatcfStandardCaseRecordTypeId)
                        { // Validation for Medical Eligibility month/year to be less than current year/month
                            if (cas.Medical_Eligibility_Year_gne__c !=null)
                            {
                                if (cas.Medical_Eligibility_Year_gne__c > string.valueof(system.today().year()))
                                {
                                    cas.Medical_Eligibility_Year_gne__c.adderror('Medical Eligibility Year cannot be greater than current year');
                                }
                                else if (cas.Medical_Eligibility_Year_gne__c == string.valueof(system.today().year()))
                                {
                                    if (cas.Medical_Eligibility_Month_gne__c != null)
                                    {
                                        Integer month = GNE_CM_Case_Trigger_Util.getMonthNumber(cas.Medical_Eligibility_Month_gne__c);
                                        
                                        if (month != null && month > system.today().month())
                                        {
                                            cas.Medical_Eligibility_Month_gne__c.adderror('Medical Eligibility month cannot be greater than current month if medical eligibility year is current year');
                                        }
                                    }
                                }   
                            }
                            //Validations for Roll Up Infusions To for GATCF case
                            if (cas.RecordTypeId == gatcfStandardCaseRecordTypeId)
                            { 
                                if (cas.Product_gne__c!='Herceptin' && cas.Roll_Up_Infuisons_To_gne__c!=null)
                                {
                                    cas.Roll_Up_Infuisons_To_gne__c.adderror('Field is not editable, select None from the list.');
                                } 
                                
                                if (cas.Product_gne__c == 'Herceptin' && cas.BeforeInsertFlag_gne__c == false)
                                { 
                                    if (cas.Roll_Up_Infuisons_To_gne__c==null)
                                    {
                                        cas.Roll_Up_Infuisons_To_gne__c.adderror('Please enter value for Roll up Infusions To.');
                                    }
                                    
                                    if (cas.Case_Treating_Physician_gne__c==null && cas.Roll_Up_Infuisons_To_gne__c=='Physician')
                                    {
                                        cas.Roll_Up_Infuisons_To_gne__c.adderror('Please align a Prescriber to case before selecting Physician in Roll up Infusions To.');
                                    }
                                    
                                    if (cas.Facility_gne__c==null && cas.Roll_Up_Infuisons_To_gne__c=='Hospital')
                                    {
                                        cas.Roll_Up_Infuisons_To_gne__c.adderror('Please align a Facility to case before selecting Hospital in Roll up Infusions To.');
                                    }
                                    
                                    if (cas.Practice_gne__c==null && cas.Roll_Up_Infuisons_To_gne__c=='Clinic/Practice')
                                    {
                                        cas.Roll_Up_Infuisons_To_gne__c.adderror('Please align a Clinic/Practice to case before selecting Clinic/Practice in Roll up Infusions To.');
                                    }
                                }
                                // JH MDME START
                                // Automatically populate date to respective Eligibility Document Type values
                                if (trigger.isUpdate || trigger.isInsert) {

                                    // Validation around Approved Status
                                    system.debug('VALIDATION MDME status ' + cas.GATCF_Status_gne__c);
                                    system.debug('VALIDATION MDME ins status' + cas.Ins_Eligibility_Determination_gne__c);
                                    
                                    if ((cas.GATCF_Status_gne__c=='Approved' || cas.GATCF_Status_gne__c=='Approved - Part D Extension') && cas.Ins_Eligibility_Determination_gne__c!='Approved') {
                                        GNE_CM_MPS_Custom_Setting__c setting = GNE_CM_MPS_Custom_Setting__c.getInstance('MPS_Configuration');
                                        Date mdmeGoLive = Date.valueOf(setting.MDME_Production_Date__c);
                                        system.debug(LoggingLevel.INFO, 'Case CreatedDate: '+cas.createdDate+ ' - MDME GoLive: '+mdmeGoLive);
                                        
                                        if((trigger.isUpdate && cas.createdDate > mdmeGoLive) || (trigger.isInsert && system.today() > mdmeGoLive))
                                            cas.GATCF_Status_gne__c.adderror('The case cannot be set to this GATCF Status if Insurance Eligibility Determination is not Approved.');
                                    }

                                    // Auto populate deprecated field for reporting
                                    cas.Eligibility_Document_Type_gne__c = null;

                                    if(cas.Appeal_Denial_gne__c!=null)
                                        eligibilityDocumentType.add('Appeal Denial received');
                                    if(cas.Exception_gne__c!=null)
                                        eligibilityDocumentType.add('Exception');
                                    if(cas.PA_Claim_EOB_gne__c!=null)
                                        eligibilityDocumentType.add('PA/ Claim/ EOB received');
                                    if(cas.Pending_Appeal_Denial_Letter_gne__c!=null)
                                        eligibilityDocumentType.add('Pending Written Appeal Denial Letter');
                                    if(cas.Pending_PA_Claim_Denial_Letter_gne__c!=null)
                                        eligibilityDocumentType.add('Pending Written Denial (PA/Claim)');

                                    cas.Eligibility_Document_Type_gne__c = String.join(eligibilityDocumentType,';');
                                }
                                /* JH MDME Obsoleted per GATCF SME 9/11/2013
                                if (cas.GATCF_Status_gne__c == 'Approved') {
                                    Boolean allowedStatusAndDocumentCombination = false;

                                    allowedStatusAndDocumentCombination |= (cas.Indication_gne__c == 'Label' &&  (cas.Eligibility_Document_Type_gne__c != null && cas.Eligibility_Document_Type_gne__c.contains('Pending Written Denial (PA/Claim)') && cas.Eligibility_Document_Type_gne__c.contains('Pending Written Appeal Denial Letter') && cas.Eligibility_Document_Type_gne__c.contains('PA/ Claim/ EOB received') && cas.Eligibility_Document_Type_gne__c.contains('Appeal Denial received')));
                                    allowedStatusAndDocumentCombination |= (cas.Indication_gne__c == 'Label' && cas.Eligibility_Document_Type_gne__c != null && cas.Eligibility_Document_Type_gne__c.contains('Exception') );
                                    allowedStatusAndDocumentCombination |= (cas.Indication_gne__c == 'Other' &&  (cas.Eligibility_Document_Type_gne__c != null && cas.Eligibility_Document_Type_gne__c.contains('Pending Written Denial (PA/Claim)') && cas.Eligibility_Document_Type_gne__c.contains('PA/ Claim/ EOB received') ));
                                    allowedStatusAndDocumentCombination |= (cas.Indication_gne__c == 'Other' &&  cas.Eligibility_Document_Type_gne__c != null && cas.Eligibility_Document_Type_gne__c.contains('Exception') );
                                    allowedStatusAndDocumentCombination |= (cas.Indication_gne__c == 'Uninsured' );
                                    
                                    if (!allowedStatusAndDocumentCombination) {
                                        cas.adderror('GATCF Status cannot be set to Approved with selected values of Insurance Status and populated Insurance Eligibility Document Dates');
                                    } 
                                }
                                /* JH MDME Obsoleted per GATCF SME 9/10/2013
                                if (cas.Eligibility_Document_Type_gne__c != null) {
                                    if (trigger.isUpdate)
                                    {
                                        EligibilityDocumentType = system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c;
                                    } 
                                    
                                    if (( trigger.isInsert  || (trigger.isUpdate && (EligibilityDocumentType != null &&  !system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c.contains('Appeal Denial received')) || EligibilityDocumentType == null)) && cas.Eligibility_Document_Type_gne__c.contains('Appeal Denial received')&& cas.Appeal_Denial_gne__c == null )
                                    {
                                        cas.Appeal_Denial_gne__c = system.now();
                                    } 
                                    else if ( !cas.Eligibility_Document_Type_gne__c.contains('Appeal Denial received'))
                                    {
                                        cas.Appeal_Denial_gne__c = null;
                                    }  
                                    
                                    if ( (trigger.isInsert || (trigger.isUpdate && (EligibilityDocumentType != null && !system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c.contains('Exception')) ||EligibilityDocumentType == null) ) && cas.Eligibility_Document_Type_gne__c.contains('Exception') &&  cas.Exception_gne__c == null)
                                    {
                                        cas.Exception_gne__c = system.now();
                                    }
                                    else if (!cas.Eligibility_Document_Type_gne__c.contains('Exception'))
                                    {
                                        cas.Exception_gne__c = null;
                                    }  
        
                                    if ( (trigger.isInsert || (trigger.isUpdate && (EligibilityDocumentType != null && !system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c.contains('PA/ Claim/ EOB received')) || EligibilityDocumentType == null)) && cas.Eligibility_Document_Type_gne__c.contains('PA/ Claim/ EOB received') && cas.PA_Claim_EOB_gne__c == null)
                                    {
                                        cas.PA_Claim_EOB_gne__c = system.now();
                                    } 
                                    else if (!cas.Eligibility_Document_Type_gne__c.contains('PA/ Claim/ EOB received'))
                                    {
                                        cas.PA_Claim_EOB_gne__c= null;
                                    }  
        
                                    if ( (trigger.isInsert || (trigger.isUpdate && (EligibilityDocumentType != null && !system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c.contains('Pending Written Appeal Denial Letter')) || EligibilityDocumentType == null)) && cas.Eligibility_Document_Type_gne__c.contains('Pending Written Appeal Denial Letter') &&  cas.Pending_Appeal_Denial_Letter_gne__c == null)
                                    {
                                        cas.Pending_Appeal_Denial_Letter_gne__c = system.now();
                                    } 
                                    else if (!cas.Eligibility_Document_Type_gne__c.contains('Pending Written Appeal Denial Letter'))
                                    {
                                        cas.Pending_Appeal_Denial_Letter_gne__c = null;
                                    }  
        
                                    if ( (trigger.isInsert || (trigger.isUpdate && (EligibilityDocumentType != null && !system.trigger.oldmap.get(cas.Id).Eligibility_Document_Type_gne__c.contains('Pending Written Denial (PA/Claim)')) || EligibilityDocumentType == null)) && cas.Eligibility_Document_Type_gne__c.contains('Pending Written Denial (PA/Claim)') &&  cas.Pending_PA_Claim_Denial_Letter_gne__c == null)
                                    {
                                        cas.Pending_PA_Claim_Denial_Letter_gne__c = system.now();
                                    }
                                    else if (!cas.Eligibility_Document_Type_gne__c.contains('Pending Written Denial (PA/Claim)'))
                                    {
                                        cas.Pending_PA_Claim_Denial_Letter_gne__c = null;
                                    }
                                } else {                                    
                                    cas.Appeal_Denial_gne__c = null;
                                    cas.Exception_gne__c = null; 
                                    cas.PA_Claim_EOB_gne__c= null;
                                    cas.Pending_Appeal_Denial_Letter_gne__c = null; 
                                    cas.Pending_PA_Claim_Denial_Letter_gne__c = null;
                                }*/
                                //JH MDME END       
                            }//end of GATCF                                        
                            
                            //validation on Income Source Multi Select picklist
                            if (cas.Verified_Income_gne__c!=null && cas.Income_Source_gne__c==null)
                            cas.Income_Source_gne__c.adderror('Please select Income Source from available list of values.'); 
                            //defect#cdtp00056718
                            // GDC - 04/08/2009 - Defect # cdtp00058404, further modified as per new req
                            
                            if (cas.Documentation_gne__c!=null)
                            {
                                documentation_vals = cas.Documentation_gne__c.split(';');
                            }
                            
                            for (integer k=0; k<documentation_vals.size(); k++)
                            { 
                                //JH: MDME 10/21/2013 - additional validation exception
                                if (documentation_vals[k] != 'Financial Documentation' && documentation_vals[k] != 'PAN' && documentation_vals[k] != 'Patient Financial Attestation')
                                {
                                    missing_flag = 1;
                                    break;
                                }
                            }
                            
                            //PS: 8/9/2012 if (((cas.GATCF_Status_gne__c=='Approved' || cas.GATCF_Status_gne__c=='Approved - In Appeal' || cas.GATCF_Status_gne__c=='Approved - Tarceva Extension' || cas.GATCF_Status_gne__c == 'Pending Change of Income Review') && cas.Documentation_gne__c!=null) 
                             if (((cas.GATCF_Status_gne__c=='Approved' || cas.GATCF_Status_gne__c=='Approved - In Appeal' || cas.GATCF_Status_gne__c=='Approved - Part D Extension' || cas.GATCF_Status_gne__c == 'Pending Change of Income Review') && cas.Documentation_gne__c!=null)
                                    || (cas.GATCF_Status_gne__c=='Approved - Contingent Enrollment' && missing_flag==1) 
                                    || ((cas.GATCF_Status_gne__c=='Conditional Enrollment Approved' || cas.GATCF_Status_gne__c=='Conditional Enrollment Denied') && (cas.Documentation_gne__c !=null && cas.Documentation_gne__c.contains('PAN'))))
                            cas.GATCF_Status_gne__c.adderror('GATCF Status cannot be set to '+cas.GATCF_Status_gne__c+' when required documents are missing for the Case.');
                            missing_flag=0;
                            
                        }//end of If GATCF case or GES Case                       
                        //auto populate Referred By Person when Referred by Type is Patient
                        if (cas.Referred_By_Type_gne__c=='Patient' && cas.Referred_By_Person_gne__c==null && cas.RecordTypeId != gatcfStandardCaseRecordTypeId && cas.RecordTypeId !=gesCaseRecordTypeId)
                        {
                            cas.Referred_By_Person_gne__c='Referred by Patient';
                        }                     
                        
                        //Stamp Practice/Prescriber on Account 
                        if (cas.Practice_gne__c!=null)
                        {
                            cas.AccountId = cas.Practice_gne__c;
                        }
                        else if (cas.Case_Treating_Physician_gne__c!=null)
                        {  
                            cas.AccountId = cas.Case_Treating_Physician_gne__c;
                        }                  
                        // Stamp Referred to Vendor SP with the current timestamp when Case Being Worked by is Non genentech
                        if ((System.trigger.isInsert && cas.Case_Being_Worked_By_gne__c != null && cas.Case_Being_Worked_By_gne__c != 'GENENTECH') ||
                                (System.trigger.isUpdate && cas.Case_Being_Worked_By_gne__c != null && cas.Case_Being_Worked_By_gne__c != 'GENENTECH' && System.Trigger.oldMap.get(cas.Id).Case_Being_Worked_By_gne__c != cas.Case_Being_Worked_By_gne__c))
                        {
                            cas.Referred_to_Vendor_SP_gne__c = System.now();
                        }                             
                    }   //end of try    
                    catch (Exception e)
                    {
                        cas.adderror('Error encountered while stamping ICD9 Code values, Patient and checking other validations: ' + e.getmessage());
                    }
                }//end of for       
                
                if (System.trigger.isUpdate)
                {
                    try
                    {   
                        openActivityList = [SELECT WhatId, case_id_gne__c, IsClosed, Subject from Task where case_id_gne__c IN :case_id_set];
                    }
                    catch (Exception e)
                    {
                        for (Case css :Trigger.new)
                        css.addError('Exception Raised while fetching open activities:' +e.getmessage());       
                    }                               
                    for (Case casclosed :Trigger.new)
                    {
                        try
                        {  
                            // the key of the environment variable whose values contain names of profiles allowed to edit cases 48hrs after a case has been closed
                            //Set<string> profileEnvVarKey = new Set<String> {'AllObjects_CaseClosed_48hrs_chk_Profiles'};
                            //wilczekk: select in a for loop - please move outside the for
                            //List<Environment_Variables__c> profileEnvVars = GNE_CM_Environment_variable.get_envVariable(profileEnvVarKey);
                            // names of the profile allowed to edit cases 48h after they have been closed
                            String environment = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;  
                            Map<String, GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c> allObjectsCaseClosedMap = GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c.getAll();
                            Set<String> profilesToEditCaseClosed48Hours = new Set<String>();
                            for (GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c envVar : allObjectsCaseClosedMap.values())
                            {
                                if (envVar.Value__c != null && (envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'))
                                {
                                    profilesToEditCaseClosed48Hours.add(envVar.Value__c.toUpperCase());
                                }
                            }
                            
                            // do not allow any updates after 48 hours of closing a case, except for some profiles
                            if (System.trigger.oldmap.get(casclosed.Id).Status.startsWith('Closed') && System.now() >= (System.trigger.oldmap.get(casclosed.Id).ClosedDate.addDays(2)) 
                                    && (profile_name!= 'GNE-CM-CRSUPERVISOR' && profile_name!= 'GNE-CM-CRMANAGER' && profile_name!= 'GNE-CM-GATCFSUPERVISOR' 
                                        && profile_name != 'GNE-CM-GATCFMANAGER' && profile_name!= 'GNE-CM-DIR' && !profilesToEditCaseClosed48Hours.contains(profile_name.toUpperCase())
                                        && !profile_name.startsWith('GNE-SYS') && profile_name!='GNE-SFA-InternalUser' && profile_name!= 'System Administrator' && !profile_name.startsWithIgnoreCase('GNE-SFA-OPS'))
                                    && !GNE_CM_Batch_Fax_AA_post_processing.fieldsAllowed4EditChanged(trigger.oldMap.get(casclosed.Id), casclosed, caseFields, crCaseRecordTypeId)
                                    && !GNE_CM_Static_Flags.isSet('FORCE_CASE_UPDATE'))   
                            {
                                casclosed.adderror('Case cannot be edited once it has been Closed for 48 hours or more.');
                            }
                            else  
                            {  
                                if (casclosed.Status.startsWith('Closed'))    
                                {
                                    //For C&R Cases
                                    if (casclosed.RecordTypeId != gesCaseRecordTypeId && casclosed.RecordTypeId != gatcfStandardCaseRecordTypeId && casclosed.RecordTypeId != ccpCaseRecordTypeId)
                                    {
                                        if (casclosed.Cvg_gne__c != null)
                                        {
                                            if (casclosed.Cvg_gne__c.startsWith('Pending') && !profile_name.startsWith('GNE-SYS') && profile_name!='GNE-SFA-InternalUser' && profile_name!= 'System Administrator' && !profile_name.startsWithIgnoreCase('GNE-SFA-OPS'))
                                            casclosed.adderror('Case cannot be closed with Pending Coverage Status.');
                                        }                    
                                    }//end of If case record type is C&R standard
                                    if (casclosed.RecordTypeId == gatcfStandardCaseRecordTypeId)
                                    {
                                        //KS: Commented the below line to throw error when the user is trying to clone case with GATCF Status as Pending *
                                        //if (casclosed.GATCF_Status_gne__c=='Pending Change of Income Review' || casclosed.GATCF_Status_gne__c=='Pending Documentation' || casclosed.GATCF_Status_gne__c=='Pending GATCF Medical Review' || casclosed.GATCF_Status_gne__c=='Pre-claimed Approved' || casclosed.GATCF_Status_gne__c=='Pre-claimed Denied')
                                        if (casclosed.GATCF_Status_gne__c.startsWith('Pending'))
                                        {
                                            casclosed.adderror('Case cannot be closed with '+casclosed.GATCF_Status_gne__c+' as GATCF Status. Please select some other value for GATCF Status.');
                                        }
                                    }
                                    //end of If case is GATCF  
                                    
                                    //case cannot be closed when there are open activities on case(for C&R and GATCF) or related objects (for C&R cases only)
                                    for (Task tsk1 : openactivitylist)
                                    {
                                        whtid = tsk1.WhatId;
                                        if (tsk1.case_id_gne__c == casclosed.Id && tsk1.WhatId == casclosed.Id && tsk1.IsClosed==false
                                                && !profile_name.startsWith('GNE-SYS') && profile_name!='GNE-SFA-InternalUser' && profile_name!= 'System Administrator' && !profile_name.startsWithIgnoreCase('GNE-SFA-OPS'))
                                        casclosed.adderror('Case cannot be closed because there are open activities for this case.');
                                        
                                        if (tsk1.case_id_gne__c == casclosed.Id && tsk1.WhatId != casclosed.Id && whtid.substring(0, 3) != paobjid && tsk1.IsClosed==false
                                                && !profile_name.startsWith('GNE-SYS') && profile_name!='GNE-SFA-InternalUser' && profile_name!= 'System Administrator' && !profile_name.startsWithIgnoreCase('GNE-SFA-OPS'))
                                        casclosed.adderror('Case cannot be closed because there are open activities on objects related with this case. Please click on Open Activities link on Case, Appeal, Appeal Level, etc.');                           
                                    }                  
                                }//end of If case closed               
                            }//end of else                                                                                    
                        }
                        //end of try
                        catch (Exception e)
                        {
                            casclosed.adderror('Error encountered while closing case: ' + e.getmessage());
                        }                
                    }
                    //end of for
                    
                    /*Validation to lock down GATCF Stnd. case Roll Up Infusions To when Infusion/Shipment exist and to check Pending Appeals, BI, Claims with Case before it can be closed*/
                    try
                    {                                         
                        for (Case[] caseclosechk : [SELECT (select Id from Shipments__r), (Select Id, BI_BI_Status_gne__c, Case_BI_gne__c, Benefit_Type_gne__c, BI_Insurance_gne__r.Rank_gne__c from Benefit_Investigation_gne__r), (Select Id, Appeal_Status_gne__c, Case_gne__c from Appeal_Level_gne__r), (Select Id, Status_gne__c, Case_gne__c from Claims__r), Id, (select Id from Infusions__r), Roll_Up_Infuisons_To_gne__c, RecordType.Name, product_gne__c, Case_Being_Worked_By_gne__c FROM Case where Id IN :case_id_set])
                        {
                            for (integer i=0;i< caseclosechk.size();i++)
                            {
                                pendingbiflg=0;         
                                pendingapplvlflg=0;
                                pendingclaimflg=0;
                                ship_flag=0;
                                inf_flag=0;
                                caseid=Trigger.newMap.get(caseclosechk[i].Id);
                                try
                                { //checking BI status for Pending status in Benefit Investigation associated with case
                                    for (Benefit_Investigation_gne__c bi: caseclosechk[i].Benefit_Investigation_gne__r)
                                    {
                                        if (bi.BI_BI_Status_gne__c != null)
                                        {
                                            if (Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && System.now() < (Trigger.oldMap.get(caseclosechk[i].Id).ClosedDate.addDays(2)) && (bi.BI_BI_Status_gne__c.startsWith('Pending') || bi.BI_BI_Status_gne__c=='BI Pending' || bi.BI_BI_Status_gne__c=='Draft') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')   
                                            {pendingbiflg=1;
                                                break;}
                                            else
                                            if (!Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && (bi.BI_BI_Status_gne__c.startsWith('Pending') || bi.BI_BI_Status_gne__c=='BI Pending' || bi.BI_BI_Status_gne__c=='Draft') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')
                                            {pendingbiflg=1;
                                                break;}
                                        }           
                                    }//end of for Benefit Inv
                                    if (pendingbiflg==1)
                                    caseid.adderror('Case cannot be closed with Pending Benefit Investigation.');                              
                                    
                                    for (Appeal_Level_gne__c applvl: caseclosechk[i].Appeal_Level_gne__r)
                                    {
                                        if (applvl.Appeal_Status_gne__c != null)
                                        {
                                            if (Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && System.now() < (Trigger.oldMap.get(caseclosechk[i].Id).ClosedDate.addDays(2)) && applvl.Appeal_Status_gne__c.startsWith('Pending') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')    
                                            {pendingapplvlflg=1;
                                                break;}
                                            else
                                            if (!Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && applvl.Appeal_Status_gne__c.startsWith('Pending') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')
                                            {pendingapplvlflg=1;
                                                break;}
                                        }
                                    }//end of for Appeal_Level_gne__c 
                                    if (pendingapplvlflg==1)
                                    caseid.adderror('Case cannot be closed with Pending Appeal Level.');                                   
                                    
                                    for (Claim_gne__c cl: caseclosechk[i].Claims__r)
                                    {
                                        if (cl.Status_gne__c != null)
                                        {
                                            if (Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && System.now() < (Trigger.oldMap.get(caseclosechk[i].Id).ClosedDate.addDays(2)) && (cl.Status_gne__c.startsWith('Pending') || cl.Status_gne__c=='Claim not received by payer') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')   
                                            {pendingclaimflg=1;
                                                break;}
                                            else
                                            if (!Trigger.oldMap.get(caseclosechk[i].Id).Status.startsWith('Closed') && caseid.Status.startsWith('Closed') && (cl.Status_gne__c.startsWith('Pending') || cl.Status_gne__c=='Claim not received by payer') && caseclosechk[i].RecordType.Name=='C&R - Standard Case')
                                            {pendingclaimflg=1;
                                                break;}
                                        }
                                    }                                   
                                    if (pendingclaimflg==1)
                                    caseid.adderror('Case cannot be closed with Pending Claims.');  
                                    //Roll up Infusion Check   
                                    for (Shipment_gne__c ship: caseclosechk[i].Shipments__r)
                                    {
                                        if (caseclosechk[i].RecordType.Name=='GATCF - Standard Case' && caseclosechk[i].product_gne__c=='Herceptin')
                                        {ship_flag=1;
                                            break;}
                                    }    
                                    if (ship_flag==1 && caseclosechk[i].Roll_Up_Infuisons_To_gne__c!=caseid.Roll_Up_Infuisons_To_gne__c)
                                    caseid.Roll_Up_Infuisons_To_gne__c.adderror('Field is not editable when Infusion/Shipment exist for case, please change it back to '+caseclosechk[i].Roll_Up_Infuisons_To_gne__c);
        
                                    for (Infusion_gne__c inf: caseclosechk[i].Infusions__r)
                                    {
                                        if (caseclosechk[i].RecordType.Name=='GATCF - Standard Case' && caseclosechk[i].product_gne__c=='Herceptin')
                                        {inf_flag=1;
                                            break;}
                                    }   
                                    if (inf_flag==1 && caseclosechk[i].Roll_Up_Infuisons_To_gne__c!=caseid.Roll_Up_Infuisons_To_gne__c)
                                    caseid.Roll_Up_Infuisons_To_gne__c.adderror('Field is not editable when Infusion/Shipment exist for case, please change it back to '+caseclosechk[i].Roll_Up_Infuisons_To_gne__c);
        
                                }//end of try
                                catch (exception e)
                                {
                                    caseid.adderror('Error encountered while checking BI, Appeal Level, Claim for Pending Status and Shipment/Infusions for Roll Up Infusions to field. '+e.getMessage());
                                }                                                                                                                          
                            }   // end of for (integer i=0;i< caseclosechk.size();i++)                                                                
                        }//end of for caseclosechk
                    }//end of try
                    catch (exception e)
                    {
                        for (Case cs2 :Trigger.new)
                        cs2.adderror('Exception Raised while running relationship query to check Pending Appeals/BI/Appeal Level/Claims:' +e.getmessage());       
                    }
                }//end of If update trigger     
                
                      
        
                //Clear maps, lists, sets  
                Medical_History_map.clear();          
                MHidset.clear();              
                Case_Id_Set.clear();       
                cases.clear();
            }//end of if (casupdids.size()>0)  
            else
            {
                for (Case casupd : Trigger.new) 
                {
                    casupd.After_Trigger_Flag_gne__c=false;
                }
            } 
        }
        casupdids.clear();  
        }//End bypassing
    
//------------------------------------------------------------ P-H Combo Scenarios ----------------------------------------------------------------------------------//    
    //KS: Updating Parent record when the user manually creates a relationship between P-H cases from a H Case (Edit).
    system.debug('CLONING FLAG VALUE in TRIG:: ' + GNE_CM_case_trigger_monitor.triggerIsInProcessCaseUpdate());
    if ((trigger.isUpdate && trigger.isAfter || trigger.isInsert && trigger.isBefore) && !GNE_CM_case_trigger_monitor.triggerIsInProcessCaseUpdate())
    {
        List<Case> CaseUpdateList = new List<Case>();
        List<case> PertUpdateList = new List<case>();
        List<case> PertuzumabCases = new List<case>();
        Set<Id> CaseSet = new Set<Id>();
        Set<Id> HCaseSet = new Set<Id>();
        Map<Id, Id> HCaseMap = new Map<Id, Id>();
        
        try
        {
            for (Case cs : trigger.new)
            {
                if (cs.Product_gne__c == 'Herceptin')
                {
                    //When user is editing a H case.
                    if (cs.IsManualUpdateChild_gne__c ==  true)
                    {
                        if (cs.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c && cs.Combo_Therapy_Case_gne__c != null)
                        {
                            CaseSet.add(cs.Combo_Therapy_Case_gne__c);
                        }
                        else if (cs.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c != null)
                        {
                            CaseSet.add(trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c);
                        }
                    }
                    //When user enters a P case number in Pertuzumab Combo Case Lookup while creating a new H Case.
                    else
                    {
                        if (cs.Combo_Therapy_Case_gne__c != null)
                        {
                            CaseSet.add(cs.Combo_Therapy_Case_gne__c);
                        }
                    }
                }
                
                // this trigger is also run before insert, so IDs might be null, causing a non-selective query exception
                if (cs.Id != null)
                {
                	HCaseSet.add(cs.Id);
                }
            }
            
            System.debug('Cloning...');
            
            // Here we want to initialize two completely different SOQL queries (with different fields and conditions):
            pertuzumabCases = [SELECT id, Combo_Therapy_Case_gne__c, Product_gne__c, Combo_Therapy_Child_Case_gne__c, Medical_History_gne__c, IsManualUpdate_gne__c, Combo_Therapy_Case_Flag_gne__c FROM Case where Combo_Therapy_Child_Case_gne__c in: HCaseSet];
            
            if (CaseSet.size() > 0)
            {
            	caseUpdateList = [SELECT id, Combo_Therapy_Case_gne__c, Combo_Therapy_Case_Flag_gne__c, Combo_Therapy_Child_Case_gne__c FROM Case where id in: CaseSet];
            }
            // Here we want to initialize two completely different SOQL queries (with different fields and conditions):
            // pertuzumabCases = [SELECT id, Combo_Therapy_Case_gne__c, Product_gne__c, Combo_Therapy_Child_Case_gne__c, Medical_History_gne__c, IsManualUpdate_gne__c, Combo_Therapy_Case_Flag_gne__c FROM Case where Combo_Therapy_Child_Case_gne__c in: HCaseSet];
            // caseUpdateList = [SELECT id, Combo_Therapy_Case_gne__c, Combo_Therapy_Case_Flag_gne__c, Combo_Therapy_Child_Case_gne__c FROM Case where id in: CaseSet];
            // We tried to implement this using one query for both conditions:
            // List<Case> mergedCaseResults = [SELECT id, Combo_Therapy_Case_gne__c, Product_gne__c, Combo_Therapy_Child_Case_gne__c, Medical_History_gne__c, IsManualUpdate_gne__c, Combo_Therapy_Case_Flag_gne__c FROM Case where Combo_Therapy_Child_Case_gne__c IN :HCaseSet OR Id IN :CaseSet];
            // but with large data sets it threw a 'Non-selective query' exception.
            
            /*for (Case mergedCaseResult : mergedCaseResults)
            {
                if (caseSet.contains(mergedCaseResult.Id))
                {
                    caseUpdateList.add(mergedCaseResult);
                }
                if (hCaseSet.contains(mergedCaseResult.Combo_Therapy_Child_Case_gne__c))
                {
                    pertuzumabCases.add(mergedCaseResult);
                }
            }*/
            
            if (CaseUpdateList != null && CaseUpdateList.Size() > 0)
            {
                for (Case cs : trigger.new)
                {
                    for (Case cas : CaseUpdateList)
                    {
                        if (cs.Combo_Therapy_Case_gne__c != null && cs.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c != null)
                        {
                            if (PertuzumabCases != null && PertuzumabCases.Size() > 0)
                            {
                                for (Case PC : PertuzumabCases)
                                {
                                    PC.Combo_Therapy_Child_Case_gne__c = null;
                                    PC.IsManualUpdate_gne__c = false;
                                    PC.Combo_Therapy_Case_Flag_gne__c = false; 
                                    PertUpdateList.add(PC);
                                }
                            }
                            if (cs.Combo_Therapy_Case_gne__c != null)
                            {
                                cas.Combo_Therapy_Case_Flag_gne__c = false; 
                                cas.Combo_Therapy_Child_Case_gne__c = cs.id;
                            }
                            cas.IsManualUpdate_gne__c = false;
                        }
                        else if (cs.Combo_Therapy_Case_gne__c != null && cs.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c == null)
                        {
                            cas.Combo_Therapy_Case_Flag_gne__c = true; 
                            cas.Combo_Therapy_Child_Case_gne__c = cs.id;
                        }
                        else if (cs.Combo_Therapy_Case_gne__c != null)
                        {
                            cas.Combo_Therapy_Case_Flag_gne__c = true; 
                            cas.Combo_Therapy_Child_Case_gne__c = cs.id;
                        }
                        else if (cs.Combo_Therapy_Case_gne__c == null && cs.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Case_gne__c != null)
                        {
                            cas.Combo_Therapy_Case_Flag_gne__c = false;  
                            cas.Combo_Therapy_Child_Case_gne__c = null;
                        }
                        cas.IsManualUpdate_gne__c = false;
                        PertUpdateList.add(cas);  
                    }
                }
                if (PertUpdateList.size() > 0)
                {
                    update PertUpdateList;
                }
            } 
        }
        catch (Exception ex)
        {
            SnippetName = 'Manual linking P-H from H Case(Edit).';
            if (PertUpdateList != null && PertUpdateList.Size() > 0)
            {
                for (Case updateList : PertUpdateList)
                {
                    PatId = updateList.Patient_gne__c;
                    MedHistoryId = updateList.Medical_History_gne__c;
                    ParentCaseId = updateList.Combo_Therapy_Case_gne__c; 
                    ChildCaseId = updateList.Combo_Therapy_Child_Case_gne__c;
                }
            }
            
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', SnippetName, PatId, MedHistoryId, ParentCaseId, ChildCaseId);
        }
        finally
        {
            CaseUpdateList.clear();
            PertUpdateList.clear();
            CaseSet.clear();
            HCaseSet.clear();
        }
    }
    
    //KS: Validations for manually updating the Parent Lookup Field on Herceptin child case
    if ((trigger.isUpdate && trigger.isBefore || trigger.isInsert && trigger.isBefore) && !GNE_CM_case_trigger_monitor.triggerIsInProcessCaseUpdate())
    {
        List<Case> CaseToUpdate = new List<Case>();
        List<Case> PertCaseUpdateList = new List<Case>();
        Set<Id> SetPertCaseId = new Set<Id>();
        
        try
        {
            for (Case cas : trigger.new)
            {
                system.debug('trigger.new -----------> ' + cas);
                if ((cas.Product_gne__c == 'Herceptin' && cas.IsManualUpdateChild_gne__c == true && cas.Combo_Therapy_Case_gne__c != trigger.oldMap.get(cas.Id).Combo_Therapy_Case_gne__c && cas.Combo_Therapy_Case_gne__c != null) || (cas.Product_gne__c == 'Herceptin' && cas.Combo_Therapy_Case_gne__c != null && cas.id == null))
                {
                    SetPertCaseId.add(cas.Combo_Therapy_Case_gne__c);
                }
            }
            if (SetPertCaseId != null && SetPertCaseId.size() > 0)
            {
                PertCaseUpdateList = [SELECT id, Combo_Therapy_Child_Case_gne__r.CaseNumber, IsManualUpdateChild_gne__c, Combo_Therapy_Case_gne__c, Combo_Therapy_Child_Case_gne__c, Patient_gne__c, Product_gne__c, RecordType.Id, Medical_History_gne__c FROM Case where id in: SetPertCaseId];
            }
            system.debug('PertCaseUpdateList ---------> '  + PertCaseUpdateList);
            
            if (PertCaseUpdateList != null && PertCaseUpdateList.size() > 0)
            {
                for (Case cs : trigger.new)
                {
                    for (Case cas : PertCaseUpdateList)
                    {
                        if (cas.Combo_Therapy_Child_Case_gne__c != null && cas.Combo_Therapy_Child_Case_gne__c != cs.Combo_Therapy_Case_gne__c)
                        {
                            //trigger.new[0].addError('The Case you are trying to align in Combo Therapy Case field is already associated with Herceptin Combo Case # ' + CaseToUpdate[0].Combo_Therapy_Child_Case_gne__r.CaseNumber);
                            cs.addError(system.label.GNE_CM_Multiple_Herceptin_Alignment_Error + ' ' + cas.Combo_Therapy_Child_Case_gne__r.CaseNumber);
                        }
                        else if (cas.Product_gne__c == cs.Product_gne__c || (cas.Product_gne__c != cs.Product_gne__c && cas.Product_gne__c != Pertuzumab_product_Name))
                        {
                            //cas.addError('Field Combo Therapy Case: Please select the appropriate Master Case related to the Product.');
                             cs.addError(system.label.GNE_CM_Master_Case_Align_Product);
                        }
                        else if (cas.Patient_gne__c != cs.Patient_gne__c && cas.Product_gne__c == Pertuzumab_product_Name)
                        {
                            //cas.addError('Field Combo Therapy Case: Please select the appropriate Master Case related to the Patient.');
                             cs.addError(system.label.GNE_CM_Master_Case_Align_Patient);
                             return;
                        }
                        else
                        {
                            if (cas.Product_gne__c == Pertuzumab_product_Name)
                            {
                                if (cs.RecordTypeId == crCaseRecordTypeId)
                                {
                                    if (cas.RecordTypeId != cs.RecordTypeId)
                                    {
                                        //cs.addError('Field Combo Therapy Case: Please select the appropriate Master case related to C&R Standard Case.');
                                         cs.addError(system.label.GNE_CM_Master_Case_Align_CandR);
                                    }
                                }
                                else if (cs.RecordTypeId == gatcfStandardCaseRecordTypeId)
                                {
                                    if (cas.RecordTypeId != cs.RecordTypeId)
                                    {
                                        //cs.addError('Field Combo Therapy Case: Please select the appropriate Master case related to GATCF Standard Case.');
                                        cs.addError(system.label.GNE_CM_Master_Case_Align_GATCF);
                                    }
                                }
                                else if (cs.RecordTypeId == gesCaseRecordTypeId)
                                {
                                    if (cas.RecordTypeId != cs.RecordTypeId)
                                    {
                                        //cs.addError('Field Combo Therapy Case: Please select the appropriate Master Case related to GES Case.');
                                        cs.addError(system.label.GNE_CM_Master_Case_Align_GES);
                                    }
                                }
                            }
                        }//end of else
                    }
                }
            }
        }
        catch (exception ex)
        {
            SnippetName = 'VR align incorrect P on H(H Edit)';
            for (Case updateList : trigger.new)
            {
                PatId = updateList.Patient_gne__c;
                MedHistoryId = updateList.Medical_History_gne__c;
                ParentCaseId = updateList.Combo_Therapy_Case_gne__c; 
                ChildCaseId = updateList.Combo_Therapy_Child_Case_gne__c;
            }
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', SnippetName, PatId, MedHistoryId, ParentCaseId, ChildCaseId);
        }
        finally
        {
            CaseToUpdate.clear();
            PertCaseUpdateList.clear();
            SetPertCaseId.clear();
        }
    }
    
    //KS: Validations for manually updating Combo Therapy Child Case Lookup Field from a Pertuzumab Case
    if ((trigger.isUpdate && trigger.isBefore || trigger.isInsert && trigger.isBefore)&& !GNE_CM_case_trigger_monitor.triggerIsInProcessCaseUpdate())
    {
        List<Case> HerceptinCaseUpdateList = new List<Case>();
        Set<Id> SetHerceptinCaseId = new Set<Id>();
        
        try
        {
            for (Case cas : trigger.new)
            {
                if ((cas.Product_gne__c == Pertuzumab_product_Name && cas.IsManualUpdate_gne__c == true && cas.Combo_Therapy_Child_Case_gne__c != trigger.oldMap.get(cas.Id).Combo_Therapy_Child_Case_gne__c && cas.Combo_Therapy_Child_Case_gne__c != null) || (cas.Product_gne__c == Pertuzumab_product_Name && cas.Combo_Therapy_Child_Case_gne__c != null && cas.id == null))
                {
                    SetHerceptinCaseId.add(cas.Combo_Therapy_Child_Case_gne__c);
                }
            }
            
            system.debug('SetHerceptinCaseId = ' + SetHerceptinCaseId);
            if (SetHerceptinCaseId != null && SetHerceptinCaseId.size() > 0)
            {
                HerceptinCaseUpdateList = [SELECT id, Combo_Therapy_Case_gne__r.CaseNumber, IsManualUpdateChild_gne__c, Combo_Therapy_Case_gne__c, Combo_Therapy_Child_Case_gne__c, Patient_gne__c, Product_gne__c, RecordType.Id, Medical_History_gne__c FROM Case where id in: SetHerceptinCaseId];
            }
            
            system.debug('HerceptinCaseUpdateList = ' + HerceptinCaseUpdateList);
            if (HerceptinCaseUpdateList != null && HerceptinCaseUpdateList.size() > 0)
            {
                for (Case cas : trigger.new)
                {
                    for (Case cs : HerceptinCaseUpdateList)
                    {
                        if ((cs.Product_gne__c != cas.Product_gne__c && cs.Product_gne__c != 'Herceptin') || cs.Product_gne__c == cas.Product_gne__c)
                        {
                            //cas.addError('Field Combo Therapy Case: Please select the appropriate Child Case related to the Product.');
                             cas.addError(system.label.GNE_CM_Child_Case_Align_Product);
                        }
                        else if (cs.Patient_gne__c != cas.Patient_gne__c && cs.Product_gne__c == 'Herceptin')
                        {
                            //cas.addError('Field Combo Therapy Case: Please select the appropriate Child Case related to the Patient.');
                             cas.addError(system.label.GNE_CM_Child_Case_Align_Patient);
                        }
                        else
                        {
                            if (cs.Combo_Therapy_Case_gne__c != null && cs.Combo_Therapy_Case_gne__c != cas.Combo_Therapy_Child_Case_gne__c)
                            {
                                //cs.addError('The Case you are trying to align in Combo Therapy Case field is already associated with Master Case # ' + ParentPertuzumabCase[0].CaseNumber); 
                                 cas.addError(system.label.GNE_CM_Child_Case_Already_Aligned + ' ' + cs.Combo_Therapy_Case_gne__r.CaseNumber);
                            }
                            else if (cs.RecordTypeId == crCaseRecordTypeId && cs.RecordTypeId != cas.RecordTypeId)
                            {
                                //cs.addError('Field Combo Therapy Case: Please select the appropriate Child case related to C&R Standard Case.');
                                cas.addError(system.label.GNE_CM_Child_Case_Align_CandR);
                            }
                            else if (cs.RecordTypeId == gatcfStandardCaseRecordTypeId && cs.RecordTypeId != cas.RecordTypeId)
                            {
                                //cs.addError('Field Combo Therapy Case: Please select the appropriate Child case related to GATCF Standard Case.');
                                cas.addError(system.label.GNE_CM_Child_Case_Align_GATCF);
                            }
                            else if (cs.RecordTypeId == gesCaseRecordTypeId && cs.RecordTypeId != cas.RecordTypeId)
                            {
                                //cs.addError('Field Combo Therapy Case: Please select the appropriate Child Case related to GES Case.');
                                cas.addError(system.label.GNE_CM_Child_Case_Align_GES);
                            }
                        }
                    }
                }
            }
        }
        catch (exception ex)
        {
            SnippetName = 'VR align incorrect H on P(P Edit)';
            for (Case updateList : trigger.new)
            {
                PatId = updateList.Patient_gne__c;
                MedHistoryId = updateList.Medical_History_gne__c;
                ParentCaseId = updateList.Combo_Therapy_Case_gne__c; 
                ChildCaseId = updateList.Combo_Therapy_Child_Case_gne__c;
            }
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', SnippetName, PatId, MedHistoryId, ParentCaseId, ChildCaseId);
        }
        finally
        {
            HerceptinCaseUpdateList.clear();
            SetHerceptinCaseId.clear();
        }
    }
    
    //***********************************************************************************************************
    // Updating Herceptin Child Record when the user manually aligns a H case on a P case.
    if (trigger.isUpdate && trigger.isAfter)
    {
        List<Case> CaseUpdateList = new List<Case>();
        List<Case> HerceptinCaseUpdateList = new List<Case>();
        List<Case> HerceptinCases = new List<Case>();
        Set<Id> CaseSetChild = new Set<Id>();
        Set<Id> CaseSetParent = new Set<Id>();
        
        try
        {
            for (Case cs : trigger.new)
            {
                if (cs.Product_gne__c == Pertuzumab_product_Name && cs.IsManualUpdate_gne__c == true)
                {
                    if (cs.Combo_Therapy_Child_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c && cs.Combo_Therapy_Child_Case_gne__c != null)
                    {
                        CaseSetChild.add(cs.Combo_Therapy_Child_Case_gne__c);
                    }
                    else if (cs.Combo_Therapy_Child_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c != null)
                    {
                        CaseSetChild.add(trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c);
                    }
                }
                CaseSetParent.add(cs.Id);
            }
            if (CaseSetChild != null && CaseSetChild.size() > 0)
            {
               // getting Herceptin case records
               CaseUpdateList = [SELECT id, Combo_Therapy_Case_gne__c, Combo_Therapy_Case_Flag_gne__c, Combo_Therapy_Child_Case_gne__c FROM Case where Id in: CaseSetChild];  
            }
            
            //Use Case A query
            if (CaseSetParent != null && CaseSetParent.size() > 0)
            {
                HerceptinCases = [SELECT id, Combo_Therapy_Case_gne__c, Combo_Therapy_Case_Flag_gne__c, Combo_Therapy_Child_Case_gne__c FROM Case where Combo_Therapy_Case_gne__c in: CaseSetParent];
            }
        }
        catch (exception ex)
        {
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', 'Error while querying Case.', null, null, null, null);
        }
                   
        //try catch used to update the case when the user is aligning or dis-aligning the relationship between cases.
        try
        {
            if (CaseUpdateList != null && CaseUpdateList.Size() > 0)
            {
                for (Case cs : trigger.new)
                {
                    for (Case cas : CaseUpdateList)
                    {
                        if (cs.IsManualUpdate_gne__c == true && cs.Product_gne__c == Pertuzumab_product_Name)
                        {
                            // user clicked on edit on Perjeta case and changed the Herceptin case number in the Herceptin Combo case lookup field - Use Case A
                            if (cs.Combo_Therapy_Child_Case_gne__c != null && cs.Combo_Therapy_Child_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c != null)
                            {
                                if (HerceptinCases.Size() > 0 && HerceptinCases != null)
                                {
                                    for (Case HC : HerceptinCases)
                                    {
                                        HC.Combo_Therapy_Case_gne__c = null;
                                        HC.IsManualUpdateChild_gne__c = false;
                                        HerceptinCaseUpdateList.add(HC);  
                                    }
                                }
                                    
                                if (cs.Combo_Therapy_Child_Case_gne__c != null)
                                {
                                    cas.Combo_Therapy_Case_Flag_gne__c = false; 
                                    cas.Combo_Therapy_Case_gne__c = cs.id;
                                }
                                cas.IsManualUpdateChild_gne__c = false;
                                HerceptinCaseUpdateList.add(cas);   
                            }
                            // creating relationship manually -  no relationship existed earlier.
                            else if (cs.Combo_Therapy_Child_Case_gne__c != null)
                            {
                                if (cs.Combo_Therapy_Child_Case_gne__c != null)
                                {
                                    cas.Combo_Therapy_Case_Flag_gne__c = false; 
                                    cas.Combo_Therapy_Case_gne__c = cs.id;
                                }
                                cas.IsManualUpdateChild_gne__c = false;
                                HerceptinCaseUpdateList.add(cas);   
                            }
                            //removing relationship manually
                            if (cs.Combo_Therapy_Child_Case_gne__c == null && cs.Combo_Therapy_Child_Case_gne__c != trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c && trigger.oldMap.get(cs.Id).Combo_Therapy_Child_Case_gne__c != null)
                            {
                                cas.Combo_Therapy_Case_gne__c = null;
                                cas.IsManualUpdateChild_gne__c = false;
                                HerceptinCaseUpdateList.add(cas);
                            }
                        }
                    }
                }
                if (HerceptinCaseUpdateList != null && HerceptinCaseUpdateList.size() > 0)
                {
                    update HerceptinCaseUpdateList;
                }
            }
        }
        catch (exception ex)
        {
            SnippetName = 'Manual b/w H & P:H on P.';
            for (Case updateList : trigger.new)
            {
                PatId = updateList.Patient_gne__c;
                MedHistoryId = updateList.Medical_History_gne__c;
                ParentCaseId = updateList.Combo_Therapy_Case_gne__c; 
                ChildCaseId = updateList.Combo_Therapy_Child_Case_gne__c;
            }
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', SnippetName, PatId, MedHistoryId, ParentCaseId, ChildCaseId);
        }
        finally
        {
            CaseUpdateList.clear();
            HerceptinCaseUpdateList.clear();
            HerceptinCases.clear();
            CaseSetChild.clear();
            CaseSetParent.clear();
        }
    }
    
    // User selected a Perjeta standalone case to be created but enters the value of Herceptin case on Pertuzumab case, to create a combo case. - New Pertuzumab case
    if ((trigger.isInsert && trigger.isAfter)&& !GNE_CM_case_trigger_monitor.triggerIsInProcessCaseUpdate())
    {
        List<Case> CaseUpdateList = new List<Case>();
        Set<Id> CaseSetChild = new Set<Id>();
        Set<Id> CaseSetParent = new Set<Id>();
        List<case> HerceptinCaseUpdateList = new List<case>();
        List<Case> ParentCaseList = new List<case>();
        
        try
        {
            for (Case cs : trigger.new)
            {
                CaseSetChild.add(cs.Combo_Therapy_Child_Case_gne__c);
            }
            
            if (CaseSetChild!= null && CaseSetChild.size() > 0)
            {
               //catching herceptin case record
               CaseUpdateList = [SELECT id, Combo_Therapy_Case_gne__c, Combo_Therapy_Case_Flag_gne__c, Combo_Therapy_Child_Case_gne__c FROM Case where id in: CaseSetChild];  
            }
            
            for (Case cs : trigger.new)
            {
                if (cs.Product_gne__c == Pertuzumab_product_Name && cs.Combo_Therapy_Child_Case_gne__c != null)
                {
                    for (Case cas : CaseUpdateList)
                    {
                        cas.Combo_Therapy_Case_Flag_gne__c = false; 
                        cas.Combo_Therapy_Case_gne__c = cs.id;
                        cas.IsManualUpdateChild_gne__c = false;
                        HerceptinCaseUpdateList.add(cas);   
                    }
                }
            }
            if (HerceptinCaseUpdateList != null && HerceptinCaseUpdateList.size() > 0)
            {
                update HerceptinCaseUpdateList;
            }
        }
        catch (Exception ex)
        {
            SnippetName = 'New P with H Id.';
            if (ParentCaseList != null && ParentCaseList.Size() > 0)
            {
                for (Case updateList : ParentCaseList)
                {
                    PatId = updateList.Patient_gne__c;
                    MedHistoryId = updateList.Medical_History_gne__c;
                    ParentCaseId = updateList.Combo_Therapy_Case_gne__c; 
                    ChildCaseId = updateList.Combo_Therapy_Child_Case_gne__c;
                }
            }
            
            GNE_CM_IHCP_Utils.addCaseError(ex, 'Pertuzumab combo case', SnippetName, PatId, MedHistoryId, ParentCaseId, ChildCaseId);
        }
        finally
        {
            CaseUpdateList.clear();
            CaseSetChild.clear();
            CaseSetParent.clear();
            HerceptinCaseUpdateList.clear();
            ParentCaseList.clear();
        }
    }

    computeMedicalEligiblity();

public static void computeMedicalEligiblity(){
    
        if (trigger.isInsert && trigger.isBefore )
        {                       
            for( Case c : trigger.new)
            {
                GNE_CM_MedicalEligibilityHelper.conditionallyLockMedicalEligibility( c );
            }    
        }
        else if (trigger.isUpdate && trigger.isBefore )     
        {                
            System.debug('BBtrigger4');
            for (Case c :trigger.new)
            {   
                GNE_CM_MedicalEligibilityHelper.conditionallyLockMedicalEligibility( c );
                System.debug('BBtrigger5,c:' + c);
                Case oldC = trigger.oldMap.get( c.id );
                /*if( ( c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId ) &&
                      c.Is_Medical_Eligibility_Cloned_gne__c == true  )*/
                if( ( c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId ) &&
                      c.Medical_Eligibility_Status_gne__c == GNE_CM_Case_Dictionary.MEDICAL_ELIGIBILITY_STATUS_CLONED  )
                {
                    System.debug('BBtrigger6');
                    
                    GNE_CM_MedicalEligibilityHelper.updateIsMedicalEligiblityCloned(oldC, c);
                    //should supervisor also should be removed?
                    GNE_CM_MedicalEligibilityHelper.cleanCabReviewSection( c );
                }               
            }
        }
  }
 }
 
 /*   public static void computeMedicalEligiblity(){
        System.debug('BBCM1:');
        if( ( trigger.isInsert || trigger.isUpdate ) && trigger.isBefore )
        {
            fillPatientsForCases();
            fillMedicalHistoriesForCases( );
            fillMedilcalEligibility();  
        }
   */   
        
        
        
    /*  if (trigger.isInsert && trigger.isBefore )
        {                       
            System.debug('BBtrigger1');
            for (Case c :trigger.new)
            {
                System.debug('BBtrigger2');            
                if( (c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId)  && c.Is_Medical_Eligibility_Cloned_gne__c == true)
                {
                    System.debug('BBtrigger3');
                    GNE_CM_MedicalEligibilityHelper.fillMedicalEligibilitySection(c);                       
                }
            }
        }
        else if (trigger.isUpdate && trigger.isBefore )     
        {                
            System.debug('BBtrigger4');
            for (Case c :trigger.new)
            {
                System.debug('BBtrigger5,c:' + c);
                Case oldC = trigger.oldMap.get( c.id );
                if( ( c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId ) ||
                      c.Is_Medical_Eligibility_Cloned_gne__c == true  )                 
                {
                    System.debug('BBtrigger6');
                    GNE_CM_MedicalEligibilityHelper.fillMedicalEligibilitySection(c);
                    // when icd9 code has been changed in case by system, then CAB review should be automatically clear by system
                    
                    GNE_CM_MedicalEligibilityHelper.updateIsMedicalEligiblityCloned(oldC, c);
                    //should supervisor also should be removed?
                    GNE_CM_MedicalEligibilityHelper.cleanCabReviewSection( c );
                }               
            }
        }
       
     }
      */
/*   private static void fillMedicalEligibility( )
     {
        for (Case c :trigger.new)
        {
            if( ( c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId ) )
                                    
            {
                Case copyCase = c.copy(true, true);
                
                GNE_CM_MedicalEligibilityHelper.fillMedicalEligibilitySection( copyCase );
                if( copyCase.ICD9_Determination_1_gne__c == c.ICD9_Determination_1_gne__c && copyCase.ICD9_Determination_2_gne__c == c.ICD9_Determination_2_gne__c  )
                {
                    continue;
                }               
                c.ICD9_Determination_1_gne__c = copyCase.ICD9_Determination_1_gne__c;
                
                                
                GNE_CM_MedicalEligibilityHelper.updateIsMedicalEligiblityCloned( oldC, c );
                GNE_CM_MedicalEligibilityHelper.cleanCabReviewSection( c );
            }               
        }           
     }
*/   
/*   
     private static void fillMedicalHistoriesForCases( )
     {
        Set<Id> mhIds = new Set<Id>( );  
        
        for( Case c : trigger.new )
        {           
            mhIds.add( c.Medical_History_gne__c );
        }
                
        Map<Id, Medical_History_gne__c> medicalHistories = new Map<Id, Medical_History_gne__c> ([
            select
                ICD9_Code_1_gne__r.name,
                ICD9_Code_1_gne__r.ICD9_Code_gne__c,
                ICD9_Code_2_gne__r.name,
                ICD9_Code_2_gne__r.ICD9_Code_gne__c,
                ICD9_Code_3_gne__r.name,
                ICD9_Code_3_gne__r.ICD9_Code_gne__c,
                
                Id, Name, A_unrect_or_mPC_combo_w_gem_gne__c, Address_gne__c, Adjuvant_gne__c, Administration_Location_gne__c, Admission_Date_gne__c, Agent1_Peak_Response_gne__c, Agent_1_Date_gne__c, Agent_1_gne__c,
                Agent_2_Date_gne__c, Agent_2_gne__c, Agent_2_Peak_Response_gne__c, Aliquot_gne__c, Alt_Infusion_Center_gne__c, ALV_Aspartate_Aminotransferase_gne__c, Ancillary_Supplies_gne__c,
                Anticipated_Date_of_Treatment_gne__c, AST_Alanine_Aminotransferase_gne__c, Body_Diagram_gne__c, Body_Surface_Area_gne__c, Bone_Age_Date_Performed_gne__c, Bone_Age_gne__c, BRAF_Date_of_test_gne__c,
                BRAF_Dosage_gne__c, BRAF_Mutation_Positive_gne__c, ByPass_Events__c, CD_20_Tests_gne__c, Chemotherapy_gne__c, Chronological_Age_years_gne__c, Clinical_Impressions_gne__c, Clinical_Nurse_Approved__c,
                Clinical_TNM_Stage_gne__c, Clinical_Trial_End_Date_gne__c, Clinical_Trial_gne__c, Clinical_Trial_Name_gne__c, CM_150_mg_Total_Tablets_gne__c, CM_150mg_of_days_off_gne__c,
                CM_150mg_of_days_on_gne__c, CM_150mg_Sig_Other_gne__c, CM_150mg_tablets_gne__c, CM_150mg_times_per_day_gne__c, CM_150mg_Total_tablets_per_cycle_gne__c, 
                CM_200mg_of_Tablets_gne__c, CM_200mg_Total_Tablets_gne__c, CM_240_mg_Total_Tablets_gne__c, CM_500mg_of_days_off_gne__c, CM_500mg_of_days_on_gne__c, CM_500mg_Sig_Other_gne__c, CM_500mg_tablets_gne__c, 
                CM_500mg_times_per_day_gne__c, CM_500mg_Total_tablets_per_cycle_gne__c, CMA_Expiration_Date_gne__c, Concomitant_Medications_gne__c, Concomitant_Therapies_gne__c, Concurrent_Medications_gne__c, 
                Concurrent_Medications_TNK_gne__c, Concurrent_Other_gne__c, Concurrent_Therapy_gne__c, Concurrent_Therapy_Regimens_gne__c, confirm_surgery_is_inappropriate_gne__c, Coordinator_gne__c, Copegus_200mg_gne__c, 
                Counter_gne__c, CreatedById, CreatedDate, Current_Rtx_Tx_Course_gne__c, Current_Treatment_gne__c, Cycles_per_fill_gne__c, Date_First_Treatment_Status_gne__c, Date_of_Diagnosis_gne__c, 
                Date_of_First_Treatment_gne__c, Date_of_Prev_Treatment_gne__c, Date_of_Transplant_gne__c, Date_Pulmozyme_Discontinued_gne__c, Date_Reviewed_gne__c, Date_Therapy_Initiated_gne__c, 
                Days_in_Cycle_150mg_gne__c, Days_in_Cycle_500mg_gne__c, Declotting_gne__c, Describe_gne__c, DEXA_Scan_gne__c, Diluent_Dispense_10cc_gne__c, Dilute_with_ml_gne__c, Discontinue_Tx_Date_gne__c, 
                Disease_Caracteristics_gne__c, Disease_Characteristics_BRAF_gne__c, Disease_Characteristics_Rituxan_gne__c, Disease_state_gne__c, Dispense_15_days_supply_actemra_subq_gne__c, Dispense_Copegus_gne__c, 
                Dispense_gne__c, Dispense_month_supply_gne__c, Dispense_Months_gne__c, Dispense_Other_BRAF_gne__c, Dispense_Pegasys_1ml_gne__c, Dispense_Reconstitution_Syringes_gne__c, Dosage_Infused_mg_gne__c, 
                Dosage_mg_gne__c, Dosage_mg_kg_gne__c, Dosage_mg_old_gne__c, Dosage_Other_BRAF_gne__c, Dosage_Regimen_gne__c, Dose_Frequency_in_weeks_gne__c, Dose_mg_kg_wk_Copegus_gne__c, Dose_mg_kg_wk_gne__c, 
                Dose_mg_kg_wk_Pegasys_1ml_gne__c, Dose_Modification_gne__c, Dose_per_Inj_ml_gne__c, Drug_Allergies_gne__c, Drug_gne__c, Drug_Substitution_Allowed_gne__c, Dt_of_1st_Trtmt_for_Current_Course_gne__c, 
                Dt_Pt_Last_Seen_gne__c, Duration_of_Therapy_gne__c, Duratoin_of_Therapy_Pegasys_gne__c, Dwell_Time_gne__c, EGF_Status_gne__c, EGFR_Results_gne__c, EIA_Enzyme_Immunoassay_gne__c, ER_Status_gne__c, 
                ER_visits_date_gne__c, ER_Visits_gne__c, Estimated_Duration_gne__c, external_legacy_id_gne__c, Eye_Affected_gne__c, Eye_Being_Treated_gne__c, FEV1_gne__c, FEV_gne__c, First_Assay_Test_Date_gne__c, 
                First_Assay_Test_Fish_Value_gne__c, First_Assay_Test_Result_gne__c, First_Assay_Test_Used_gne__c, FL_LA_or_mNSCLC_w_EFGR_det_by_app_gne__c, Freqcy_of_Admin_Copegus_gne__c, Freqcy_of_Admin_gne__c, 
                Freqcy_of_Admin_Pegasys_1ml_gne__c, Frequency_of_Admin_actemra_subq_gne__c, Frequency_of_Administration_BRAF_gne__c, GATCF_Letter_Date_gne__c, GATCF_Other_gne__c, GATCF_SMN_Expiration_Date_gne__c, 
                GATCFSMN_Expiration_Flag_gne__c, Genotype_gne__c, GH_Stim_Test_gne__c, Growth_Velocity_cm_yr_gne__c, H1_antihistamines_gne__c, Has_Patient_Started_Therapy_gne__c, Has_Treatment_Started__c, HCV_RNA_gne__c, 
                HDL_LDL_gne__c, Her2_Test_gne__c, History_of_Positive_or_RAST_Test_gne__c, ICD9_Code_1_gne__c, ICD9_Code_2_gne__c, ICD9_Code_3_gne__c, IgE_Test_Date_gne__c, IgE_Test_Results_IU_ml_gne__c, IGF_1_Level_gne__c, 
                IGFBP_3_gne__c, Impact_on_Life_gne__c, Infuse_mg_Day1_Day15_gne__c, Infuse_Other_gne__c, Injection_Device_gne__c, Injections_Week_gne__c, Injs_per_week_gne__c, Investigator_Sponsored_Trial_GATCF_gne__c, 
                IsDeleted, IsLocked, IST_Study_Number_gne__c, IWF_gne__c, Karyotype_Results_gne__c, LA_BCC_radiation_or_n_candidate_for_rad__c, LA_BCC_surgery_or_n_candidate_for_surgry__c, 
                LA_or_mNSCLC_fail_1_prior_chemo_regm_gne__c, LA_or_mNSCLC_n_progress_aft_4_cy_Pla_gne__c, LA_unrect_or_mPC_combo_w_gem_gne__c, Last_Injection_Date_gne__c, LastActivityDate, LastModifiedById, LastModifiedDate, 
                Legacy_McKesson_ID_gne__c, Lesion_Position_gne__c, Lesion_Size_gne__c, Lesion_Size_Is_gne__c, Lesion_Type_gne__c, Lipid_Results_gne__c, Loading_Dose_mg_gne__c, Loading_Dose_Units_Billed_gne__c, 
                Maint_Dose_mg_gne__c, Maint_Dose_Units_Billed_gne__c, MayEdit, medhis_VA_Eye_Being_Treated2_gne__c, Medical_Assessment_Determination_Date__c, Medical_Assessment_Determined_By__c, Medical_Assessment_gne__c, 
                Medical_Assessment_Rationale__c, Medical_History_Note_gne__c, Medical_Justification_gne__c, Medical_Justification_Others_gne__c, Medical_Rationale_gne__c, Metastatic_BCC__c, Metastatic_Sites_gne__c, 
                Moderate_to_severe_allergic_Asthma_gne__c, MPS_Form_gne__c, MRI_CT_Results_gne__c, MTV_Franchise_gne__c, Needle_Size_gne__c, New_to_GNE_Date_gne__c, Next_Clinic_Date_gne__c, NKDA_gne__c, NKDAchk_gne__c, 
                Num_of_Refills_gne__c, Number_Doses_Status_gne__c, Number_of_Doses_gne__c, Number_of_Refills_gne__c, Number_Syringes_Dispense_gne__c, Onset_gne__c, Or_years_with_psoriasis_gne__c, 
                Other_Administration_Location_gne__c, Other_Asthma_Therapies_gne__c, Other_CIU_therapies_gne__c, Other_Duration_Therapy_gne__c, Other_ICD9_Code_gne__c, Other_ICD9_Description_gne__c, 
                Other_Medications_gne__c, Other_Pegasys_Prefilled_gne__c, Other_Previous_Treatment_gne__c, Other_Psoriasis_gne__c, Other_Shipping_Location_gne__c, Other_Test_Section_gne__c, Other_Therapies_gne__c, 
                Other_Type_Infusion_Center_gne__c, Other_Who_Will_Administer_gne__c, Others_Copegus_gne__c, Others_LUC_gne__c, Others_Pegasys_1ml_gne__c, Outcome_gne__c, OwnerId, PASI_gne__c, 
                Patient_has_CIU_more_than_6_weeks_gne__c, Patient_Height_gne__c, Patient_Height_Percentile_gne__c, Patient_Med_Hist_gne__c, Patient_s_height_Percentile__c, 
                Patient_s_weight_Percentile__c, Patient_Weight_Date_gne__c, Patient_Weight_kg_gne__c, Patient_Weight_Percentile_gne__c, Pegasys_180mcg_1ml_Vial_gne__c, 
                Pegasys_Prefilled_180mcg_0_5ml_gne__c, Percentile_gne__c, Phone_gne__c, Place_of_Administration_gne__c, Place_of_Administration_Name_gne__c, 
                Place_of_Administration_Tax_Id_gne__c, PR_Status_gne__c, Predicted_Adult_Height_gne__c, Preferred_Specialty_Pharmacy_gne__c, Preferred_Thrombolytic_gne__c, 
                Prescription_Type_gne__c, Prev_Treated_With_Interferon_Alpha_gne__c, Previous_Other_gne__c, Previous_Therapy_Regimens_gne__c, Previous_Therapy_Transplant_gne__c, Previous_Tx_Current_Eye_gne__c, 
                Previous_Tx_Current_Eye_Other_gne__c, Prior_Thrombolytic_Agents_Used_gne__c, Prior_Treatments_gne__c, Prior_Treatments_Others_gne__c, Product_gne__c, Product_Supply_Type_gne__c, Prophylaxis_gne__c, 
                Qty_162_mg_actemra_subq_gne__c, Quality_of_Life_Questionaire_gne__c, Quantity_of_100mg_Vials_gne__c, Quantity_of_200mg_Vials_gne__c, Quantity_of_400mg_Vials_gne__c, Quantity_of_500mg_Vials_gne__c, 
                Quantity_of_80mg_Vials_gne__c, Question_1__c, Question_2__c, Reason_Original_Discontinuance_gne__c, Reason_Original_Discontinuane_Other_gne__c, Reason_Rx_Not_Filled_gne__c, RecordTypeId, 
                Refill_s_BRAF_gne__c, Refill_Through_Date_gne__c, Refill_times_gne__c, RefillX_PRN_Copegus_gne__c, RefillX_PRN_gne__c, RefillX_PRN_Pegasys_1ml_gne__c, Region_Code_gne__c, Related_Medical_History_gne__c, 
                Release_gne__c, Requested_Ship_Date_gne__c, Retest_Assay_Test_Date_gne__c, Retest_Assay_Test_Result_gne__c, Retest_Assay_Test_Used_gne__c, Reviewed_By_gne__c, Route_of_Admin_gne__c, Rx_Date_gne__c, 
                Rx_Effective_Date_gne__c, Rx_Expiration_Copegus_gne__c, RX_Expiration_Flag_gne__c, Rx_Expiration_gne__c, Rx_Expiration_Pegasys_1ml_gne__c, Rx_Refill_Expiration_Date1_gne__c, Rx_Refill_Expiration_Date2_gne__c, 
                Rx_Refill_Expiration_Date3_gne__c, RxC_GATCF_Refills_Left_gne__c, RxC_GATCF_Units_Left_gne__c, RxC_Starter_Refills_Left_gne__c, RxC_Starter_Units_Left_gne__c, Severity_Psoriasis_gne__c, 
                Ship_1_cycle_for_week_supply_150mg_gne__c, Ship_1_cycle_for_week_supply_500mg_gne__c, Ship_2_cycle_for_week_supply_150mg_gne__c, Ship_2_cycle_for_week_supply_500mg_gne__c, 
                Ship_3_cycle_for_week_supply_150mg_gne__c, Ship_3_cycle_for_week_supply_500mg_gne__c, Ship_4_cycle_for_week_supply_150mg_gne__c, Ship_4_cycle_for_week_supply_500mg_gne__c, 
                Ship_5_cycle_for_week_supply_150mg_gne__c, Ship_5_cycle_for_week_supply_500mg_gne__c, Ship_6_cycle_for_week_supply_150mg_gne__c, Ship_6_cycle_for_week_supply_500mg_gne__c, 
                Ship_To_gne__c, Shipping_Location_gne__c, Sig_Mg_SubQ_gne__c, Significant_Symptoms_gne__c, Site_Number_gne__c, SMN_Effective_Date_gne__c, SMN_Expiration_Calc_gne__c, SMN_Expiration_Date_gne__c, 
                SMN_Form_gne__c, Specialty_Pharmacy_Needed_gne__c, SPOC_Referred_Patient_gne__c, Starter_150mg_Total_Tablets_gne__c, Starter_240mg_Total_Tablets_gne__c, Starter_Begin_Date_gne__c, Starter_Dispense_gne__c, 
                Starter_Dosage_gne__c, Starter_Frequency_of_Administration_gne__c, Starter_Other_gne__c, Starter_Refill_gne__c, Starter_Rx_Date_gne__c, Starter_Rx_Expiration_Date_gne__c, Starter_SMN_Effective_Date_gne__c, 
                Starter_SMN_Expiration_Date_gne__c, Study_Site_gne__c, SystemModstamp, Tanner_Stage_gne__c, Tarceva_Rx_Filled_gne__c, Tests_gne__c, Tests_Other_gne__c, Therapy_Sequence_gne__c, Therapy_Type_gne__c, 
                Thyroid_Function_gne__c, Thyroid_Type_gne__c, Time_Patient_Observed_gne__c, TNM_Staging_gne__c, Total_Cholesterol_gne__c, Total_Mg_Used_gne__c, Treatment_Date_gne__c, Treatment_Location_gne__c, 
                Treatment_Start_Date_gne__c, Tumor_Staging_gne__c, Type_of_Psoriasis_gne__c, Units_Billed_gne__c, Unscheduled_office_visits_date_gne__c, Unscheduled_Office_Visits_gne__c, Use_gne__c, 
                VA_eye_being_treated_gne__c, VA_for_Right_Eye_gne__c, Vial_Qty_gne__c, Vial_Size_gne__c, Weekly_Dose_mg_gne__c, Weekly_Dose_ml_gne__c, Who_will_administer_gne__c, With_Needles_gne__c, 
                X100_mg_Qty_gne__c, X100mg_Total_Number_of_Tablets_gne__c, X150_mg_Qty_gne__c, X150mg_Total_Number_of_Tablets_gne__c, X25_mg_Qty_gne__c, X25mg_Total_Number_of_Tablets_gne__c
            from
                Medical_History_gne__c 
            where 
                id in :mhIds
        ]);
        for ( Case c : trigger.new )
        {
            Medical_History_gne__c theMedicalHistory = medicalHistories.get( c.Medical_History_gne__c );
            if( theMedicalHistory == null )
            {
                continue;
            }
            c.Medical_History_gne__r = theMedicalHistory;
        }   
     }
        
     private static void  fillPatientsForCases( ) 
     {      
        Set<Id> patientIds = new Set<Id>( );  
        
        for( Case c : trigger.new )
        {
            if( (c.recordTypeId == gatcfStandardCaseRecordTypeId || c.recordTypeId == gesCaseRecordTypeId)  ) 
            {
                try
                {
                    Decimal d = c.Patient_gne__r.Age_gne__c;
                } 
                catch ( SObjectException e ) 
                {
                    patientIds.add( c.Patient_gne__c ); 
                } 
            }   
        }
        if( patientIds.size() == 0)
        {
            return;
        }
        Map<Id, Patient_gne__c> patientsMap = new Map<Id, Patient_gne__c> ([
            select
                Id, Name, Active_GATCF_Case__c, Age_gne__c, Counter_gne__c, Created_Date_Calc_gne__c, CreatedById, CreatedDate, Dist_Pat_ID_gne__c, DOB_Indexed_gne__c, DOB_Searchable_gne__c,
                Eligible_for_Nutropin_Starter_gne__c, Eligible_for_Pulmozyme_Starter_gne__c, external_legacy_id_gne__c, Full_Name_gne__c, Hearing_Impaired_gne__c, Is_yes_is_death_disease_progression_gne__c, 
                IsDeleted, IsLocked, LastActivityDate, LastModifiedById, LastModifiedDate, Legacy_McKesson_ID__c, Legacy_Patient_ID_gne__c, MayEdit, Mid_Initial_gne__c, Non_English_Speaking_gne__c, 
                Not_Participating_Anticipated_Access_gne__c, Not_Participating_in_Recert_Rem_gne__c, Note_gne__c, OK_to_Contact_Patient_gne__c, OwnerId, PAN1_Expiration_Flag_gne__c, PAN2_Expiration_Flag_gne__c, 
                PAN_Form_1_Expiration_Date_gne__c, PAN_Form_1_Product_gne__c, PAN_Form_2_Exipration_Date_gne__c, PAN_Form_2_gne__c, PAN_Form_2_old_gne__c, PAN_Form_2_Product_gne__c, PAN_Form_2_Rec_gne__c, 
                PAN_Form_2_Signed_gne__c, PAN_Form_Rec_gne__c, PAN_Form_Signed_Consolidated_gne__c, PAN_Form_Signed_gne__c, PAN_gne__c, PAN_old_gne__c, PAN_TAT_gne__c, pat_dob_gne__c, pat_email_gne__c, 
                pat_first_name_gne__c, pat_gender_gne__c, pat_home_phone_gne__c, pat_income_gne__c, pat_other_phone_gne__c, pat_other_phone_type_gne__c, pat_patient_deceased_gne__c, pat_prefix_gne__c, 
                pat_work_phone_gne__c, Patient_ID_gne__c, Patient_Initial_Referral_Date_gne__c, Patient_Name__c, Patient_Name_no_link_gne__c, Patient_Number_gne__c, Patient_Preferred_Distributor_gne__c, 
                Preferred_Language_gne__c, Primary_Phone_gne__c, Region_Code_gne__c, Release_gne__c, Service_Quality_gne__c, Service_Quality_Offered_Date_gne__c, ssn_gne__c, Status_Change_Date_gne__c, Suffix_gne__c, 
                SystemModstamp, Translator_Needed_gne__c, Vendor_Case_ID_gne__c, Verbal_Consent_Date_gne__c, Verbal_Consent_gne__c, Web_Pat_ID_gne__c 
            from
                Patient_gne__c 
            where 
                id in :patientIds
        ]);
        for ( Case c : trigger.new )
        {
            Patient_gne__c patient = patientsMap.get( c.Patient_gne__c );
            if( patient == null )
            {
                continue;
            }
            c.Patient_gne__r = patient;
        }       
     }      
   
}*/