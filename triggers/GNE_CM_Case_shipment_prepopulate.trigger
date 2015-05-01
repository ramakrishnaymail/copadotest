trigger GNE_CM_Case_shipment_prepopulate on Shipment_gne__c (before insert, before update) 
{
	// skip this trigger during merge process
	if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
		return;
	}

  //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
   
	if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_Case_shipment_prepopulate')){
		return;
    }     
   
  Id PrevCaseId =null;
  set<Id> caseidset =new set<Id>();
  Map<Id, Case> Case_map=new  Map<Id, Case>(); 
  Case CasRec=new Case();
  String MH_Rx, MH_SMN, Cs_Enr, Cs_ED, GATCFCs_Enr, profile_name, Cs_AD;
  string ShipInfo='';string CathfloNDC=''; 
  Id CaseId;
  boolean Sent_to_ESB=true;
  double ShipListPrice, ShipWAPrice;
  Map<String, String> SAPInfo=new Map<String, String>(); 
  Ship_Action_Type__c[] ShipActionRecords=new List<Ship_Action_Type__c>();
  Map<String, String> ShippedFromSite=new Map<String, String>();
  Map<String, String> ShipActionTypeID=new Map<String, String>(); 
  Map<String, String> ProductGroupId=new Map<String, String>();      
  Map<String, String> Nut_AQ_drug_vals=new Map<String, String>();      
  Map<String, Product_vod__c> ProdVialPrices=new Map<String, Product_vod__c>();
  Map<String, String> Shipment_State_Country = new Map<String, String>();
  Map<String, String> Shipment_Country_State = new Map<String, String>();  
  //List<Environment_Variables__c> environment_var_val=new List<Environment_Variables__c>();
  List<Product_vod__c> ProductVialInfo=new List<Product_vod__c>();
  //List<Environment_Variables__c> envVar=new List<Environment_Variables__c>();
  List<Product_vod__c> ActivaseProductInfo=new List<Product_vod__c>(); integer ListIndex=0;
  string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
  
  //KS: VISMO: 11/24/2011
  string vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
  //KS: VISMO: 11/24/2011: end here
  
  //KS: Pertuzumab Changes
  string Pertuzumab_Product_Name = system.label.GNE_CM_Pertuzumab_Product_Name;
  //KS: Pertuzumab Changes end here
  
  //AS: TARCEVA: 05/19/2012
  string Tarceva_product_name = system.label.GNE_CM_TARCEVA_Product_Name;
  //AS: TARCEVA: 05/19/2012: end here
  
  //T-DM1 Launch
  string TDM1_Product_Name = system.label.GNE_CM_TDM1_Product_Name;
  //T-DM1 Launch end here
  
  //[DZ] 02/12/2015 Cotellic
  String cobi_product_name = system.label.GNE_CM_Cotellic_Product_Name;
  
  String boomerang_product_name = system.label.GNE_CM_Boomerang_Product_Name;
  
  Map<String, String> GATCF_Profiles=new Map<String, String>(); Map<String, String> CRProfiles=new Map<String, String>(); Map<String, String> Case_Profiles=new Map<String, String>();Map<String, String> SR_Create_Profiles=new Map<String, String>();
  if(!GNE_CM_case_trigger_monitor.triggerIsInProcess()) // Global check for static variable to make sure trigger executes only once
   {
    GNE_CM_case_trigger_monitor.setTriggerInProcess(); // Setting the static variable to avoid trigger exec after workflow update
    try
     {
       for(Shipment_gne__c ship :Trigger.new)
       {
        if(ship.Sent_to_ESB_gne__c ==false)
        { Sent_to_ESB=false;
            if (ship.Shipdate_flag_gne__c ==False ) 
            {
                If (system.trigger.isupdate && ship.Shipped_date_gne__c != trigger.OldMap.get(ship.Id).Shipped_date_gne__c)
                {
                    ship.Shipdate_flag_gne__c = True;                    
                    system.debug ('**************** SENSING CHANGE IN SHIPPED DATE ****************');                    
                }
                else if (system.trigger.isinsert)
                {
                    ship.Shipdate_flag_gne__c=True;
                }
            }
            if(trigger.isupdate)
            { if(system.trigger.oldmap.get(ship.id).status_gne__c =='SH - Shipped' 
                    && system.trigger.oldmap.get(ship.id).status_gne__c !=ship.status_gne__c && ship.Case_Shipment_Request_gne__c==null)
                    ship.adderror('Updating the status of shipment that is already shipped is not allowed');
            }
            if(ship.Case_Shipment_gne__c !=null)
            CaseId =ship.Case_Shipment_gne__c;
            else if(ship.Case_Shipment_Request_gne__c!=null)
            CaseId =ship.Case_Shipment_Request_gne__c;
            if (CaseId !=null)
                caseidset.add(CaseId);
        }
       }   //end of for
    if(Sent_to_ESB ==false)
      { if(caseidset.size()>0)
        {
            if(!GNE_CM_Shipment_Parent_Class.case_map_flag)
            {   
                GNE_CM_Shipment_Parent_Class.setcasemap(caseidset);
                Case_map = GNE_CM_Shipment_Parent_Class.getcasemap();               
            }
            else 
            Case_map = GNE_CM_Shipment_Parent_Class.getcasemap();
        }
        system.debug('****CHECK MAP****'+GNE_CM_Shipment_Parent_Class.getcasemap());
         if(!GNE_CM_Shipment_Parent_Class.prodvialinfo_flag)
         {
            GNE_CM_Shipment_Parent_Class.setproductvialinfo();
            ProductVialInfo = GNE_CM_Shipment_Parent_Class.getproductvialinfo();
         }
         else
         ProductVialInfo = GNE_CM_Shipment_Parent_Class.getproductvialinfo();
         
         system.debug('****CHECK PRODUCT****'+GNE_CM_Shipment_Parent_Class.getproductvialinfo());
       if (ProductVialInfo.size()>0)
        {   for (integer i=0; i< ProductVialInfo.size(); i++)
            {   ProdVialPrices.put(ProductVialInfo[i].NDC_Number_gne__c, ProductVialInfo.get(i)); 
                if(ProductVialInfo[i].Parent_Product_vod__r.name =='Activase')
                {   if(ProductVialInfo[i].Name.toUpperCase().startsWith('CATHFLO'))
                        CathfloNDC=ProductVialInfo[i].NDC_Number_gne__c;
                    else
                        ActivaseProductInfo.add(ProductVialInfo[i]);
                }
            } 
        }
        
        if(!GNE_CM_Shipment_Parent_Class.ship_action_flag)
        {
            GNE_CM_Shipment_Parent_Class.setshipactionrecords();
            ShipActionRecords= GNE_CM_Shipment_Parent_Class.getshipactionrecords();
        }
        else
        ShipActionRecords= GNE_CM_Shipment_Parent_Class.getshipactionrecords();
        
        if (ShipActionRecords.size()>0)
        {  for(integer i=0; i < ShipActionRecords.size(); i++)
            {   SAPInfo.put( ShipActionRecords[i].Case_Record_Type_gne__c + ShipActionRecords[i]. Ship_Action_Type_gne__c + ShipActionRecords[i].Product_Group_Name_gne__c,ShipActionRecords[i].A_Account_gne__c);
                ShippedFromSite.put( ShipActionRecords[i].Case_Record_Type_gne__c + ShipActionRecords[i]. Ship_Action_Type_gne__c + ShipActionRecords[i].Product_Group_Name_gne__c,ShipActionRecords[i].Shipped_from_Site_gne__c);
                ShipActionTypeID.put( ShipActionRecords[i].Case_Record_Type_gne__c + ShipActionRecords[i]. Ship_Action_Type_gne__c + ShipActionRecords[i].Product_Group_Name_gne__c,ShipActionRecords[i].Internal_Shipment_Action_Type_ID_gne__c);
                ProductGroupId.put( ShipActionRecords[i].Case_Record_Type_gne__c + ShipActionRecords[i]. Ship_Action_Type_gne__c + ShipActionRecords[i].Product_Group_Name_gne__c,ShipActionRecords[i].Product_Group_ID_gne__c);
            }
        }
        
        if(!GNE_CM_Shipment_Parent_Class.profile_flag)
        {
            GNE_CM_Shipment_Parent_Class.setprofilename();
            Profile_name= GNE_CM_Shipment_Parent_Class.getprofilename();
        }
        else 
        Profile_name= GNE_CM_Shipment_Parent_Class.getprofilename();
        /*
        if(!GNE_CM_Shipment_Parent_Class.envVar_flag) 
        {
            GNE_CM_Shipment_Parent_Class.setenvironment_vars();
            envVar = GNE_CM_Shipment_Parent_Class.getenvironment_vars();
        }
        else
        envVar = GNE_CM_Shipment_Parent_Class.getenvironment_vars();
        
        for (integer MI=0; MI<envVar.size(); MI++)
        {   if (envVar[MI].Key__c =='Shipment_Create_GATCF_Profiles')
                GATCF_Profiles.put(envVar[MI].Value__c, envVar[MI].Value__c);
            if (envVar[MI].Key__c =='Shipment_Create_C_R_Profiles')
                CRProfiles.put(envVar[MI].Value__c, envVar[MI].Value__c); 
            if (envVar[MI].Key__c =='AllObjects_CaseClosed_48hrs_chk_Profiles')
                Case_Profiles.put(envVar[MI].Value__c, envVar[MI].Value__c);
            if (envVar[MI].Key__c =='Shipment_Nuspin_AQ_Drug_Vals')
                Nut_AQ_drug_vals.put(envVar[MI].Value__c, envVar[MI].Value__c);
            if (envVar[MI].Key__c =='Shipment_Request_Create_Profiles')
                SR_Create_Profiles.put(envVar[MI].Value__c, envVar[MI].Value__c);}
        */
        String environment = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;                   
	    for(Shipment_Create_GATCF_Profiles__c envVar : Shipment_Create_GATCF_Profiles__c.getAll().values()){
	       if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'){
	    	   GATCF_Profiles.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }                             
	    for(Shipment_Create_C_R_Profiles__c envVar : Shipment_Create_C_R_Profiles__c.getAll().values()){
	       if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'){
	    	   CRProfiles.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }                        
	    for(Shipment_Nuspin_AQ_Drug_Vals__c envVar : Shipment_Nuspin_AQ_Drug_Vals__c.getAll().values()){
	       if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'){
	    	   Nut_AQ_drug_vals.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }                      
	    for(Shipment_Request_Create_Profiles__c envVar : Shipment_Request_Create_Profiles__c.getAll().values()){
	       if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'){
	    	   SR_Create_Profiles.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }  
	    for(GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c envVar : GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c.getAll().values()){
	       if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all'){
	    	   Case_Profiles.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }  	 
	                       
        //kostusir - 12/01/2010 - HD0000002145074 - Shipment Validation Rule Adjustment for PR 
        string env = GlobalUtils.getEnvironment();//check if it is available
		/*        
        environment_var_val=[Select Environment__c, Key__c, Value__c , Description_Name__c
                             from Environment_Variables__c 
                             where Key__c in ('Shipment_State_Value') 
                             and Environment__c=:env order by key__c]; 
        for (integer i=0; i < environment_var_val.size(); i++)
        {
            if(environment_var_val[i].Key__c=='Shipment_State_Value')
            {
                Shipment_State_Country.put(environment_var_val[i].Value__c, environment_var_val[i]. Description_Name__c.toUpperCase());
                Shipment_Country_State.put(environment_var_val[i].Description_Name__c.toUpperCase(), environment_var_val[i].Value__c);
            }
        }
        */
	    for(Shipment_State_Value__c envVar : Shipment_State_Value__c.getAll().values()){
	       if(envVar.Environment__c == env || envVar.Environment__c.toLowerCase() == 'all'){
                Shipment_State_Country.put(envVar.Value__c, envVar.Description_Name__c.toUpperCase());
                Shipment_Country_State.put(envVar.Description_Name__c.toUpperCase(), envVar.Value__c);       	
	       }
	    }
        
        }// if Sent_to_ESB ==false
   for(Shipment_gne__c ship :Trigger.new)
    {  try
       {
         if(ship.Sent_to_ESB_gne__c ==false)
         {   if(ship.Case_Shipment_gne__c !=null)
                    CaseId =ship.Case_Shipment_gne__c;
                    else if(ship.Case_Shipment_Request_gne__c!=null)
                    CaseId =ship.Case_Shipment_Request_gne__c;
                    
            CasRec=case_map.get(CaseId);
            
            if(CaseId !=null && Case_map.containsKey(CaseId))
            {   if (CasRec.medical_history_gne__r.Rx_Expiration_gne__c ==null)
                    MH_Rx=String.ValueOf(CasRec.medical_history_gne__r.Rx_Expiration_gne__c);
                else MH_Rx=CasRec.medical_history_gne__r.Rx_Expiration_gne__c.format();
                if (CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c ==null)
                    MH_SMN=String.ValueOf(CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c);
                else MH_SMN=CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c.format();
                if (CasRec.Enrollment_Form_Rec_gne__c==null)
                    Cs_Enr=String.ValueOf(CasRec.Enrollment_Form_Rec_gne__c);
                else Cs_Enr=CasRec.Enrollment_Form_Rec_gne__c.format();
                if (CasRec.Eligibility_Determination_Date_gne__c==null)
                    Cs_ED=String.ValueOf(CasRec.Eligibility_Determination_Date_gne__c);
                else Cs_ED=CasRec.Eligibility_Determination_Date_gne__c.format();
                if (CasRec.GATCF_Enroll_Date_gne__c==null)
                  GATCFCs_Enr=String.ValueOf(CasRec.GATCF_Enroll_Date_gne__c);
                else GATCFCs_Enr=CasRec.GATCF_Enroll_Date_gne__c.format();    
                if (CasRec.Approval_Date_gne__c==null)
                    Cs_AD=String.ValueOf(CasRec.Approval_Date_gne__c);
                else Cs_AD=CasRec.Approval_Date_gne__c.format();                  
                /****** VALIDATIONS  FOR   C & R STANDARD CASE SHIPMENT *****/
                if(CasRec.recordtype.name =='C&R - Standard Case')
                {  if(trigger.isInsert)
                    {   
                        if(CRProfiles !=null && CRProfiles.containsKey(profile_name))
                        { } 
                        else
                        {
                            ship.adderror('Error found - You do not have sufficient permissions to create C&R Shipments. Please contact your administrator.');
                        }
                        //KS: Removed "CasRec.product_gne__c =='Tarceva'" from below condition sinec for a C&R Tarceva shipment we dont consider these fields.
                        if(ship.Action_gne__c !='Ship Replacement Program' && (CasRec.product_gne__c =='Nutropin' || CasRec.product_gne__c =='Pulmozyme' || CasRec.product_gne__c =='Raptiva')&&
                          (CasRec.medical_history_gne__r.Rx_Expiration_gne__c ==null || CasRec.medical_history_gne__r.Rx_Expiration_gne__c <=system.today()))
                        { 
                            ship.adderror('Error found - Rx Expiration date ['+ MH_Rx + '] on Medical history should be greater than Today\'s Date.');
                        }
                          if(CasRec.Case_Treating_Physician_gne__c==null)
                          ship.adderror('Error found - No treating physician aligned to Case.');
                    }
                    else
                    {     if((Trigger.oldMap.get(ship.id).Action_gne__c =='Ship Replacement Program') && (ship.Action_gne__c !='Ship Replacement Program')&&
                          (CasRec.product_gne__c =='Nutropin' || CasRec.product_gne__c =='Pulmozyme' || CasRec.product_gne__c =='Tarceva' || CasRec.product_gne__c =='Raptiva') &&
                           (CasRec.medical_history_gne__r.Rx_Expiration_gne__c ==null || CasRec.medical_history_gne__r.Rx_Expiration_gne__c <=system.today()))
                          { ship.adderror('Error found - Rx Expiration date ['+ MH_Rx + '] on Medical history should be greater than Today\'s Date.');}     
                    }
                    //krzyszwi - commented out per req no 2695   
                    //if( CasRec.product_gne__c =='Nutropin' &&  ship.Action_gne__c !=null && ship.Action_gne__c !='Ship Replacement Program' && ship.Drug_gne__c !=null && Nut_AQ_drug_vals.containsKey(ship.Drug_gne__c) )
                    //{ ship.adderror('C&R Shipments with NuSpin drug can only have a Shipment Type of Ship Replacement Program. Please review Drug entered on Medical History/Shipment Type entered on Shipment.');  }
                }                   
                /****** VALIDATIONS  FOR   C & R CONTINOUS CARE SHIPMENT   **********/
                 if(CasRec.recordtype.name =='C&R - Continuous Care Case')
                   { if(trigger.isInsert)
                    {
                     if(CRProfiles !=null && !CRProfiles.containsKey(profile_name) && ship.Case_Shipment_gne__c!=null)
                        ship.adderror('Error found - You do not have sufficient permissions to create C&R Shipments. Please contact your administrator.');
                     if(SR_Create_Profiles !=null && !SR_Create_Profiles.containsKey(profile_name) && ship.Case_Shipment_Request_gne__c!=null)
                     ship.adderror('Error found - You do not have sufficient permissions to create CCP Shipment Requests. Please contact your administrator.');

                     if(CasRec.Case_Treating_Physician_gne__c==null)
                     ship.adderror('Error found - No treating physician aligned to Case.');                               
                     //Defect # 8961
                     if(CasRec.product_gne__c =='Actemra' && (CasRec.medical_history_gne__r.Rx_Expiration_gne__c ==null || CasRec.medical_history_gne__r.Rx_Expiration_gne__c <=system.today()))
                     { ship.adderror('Error found - Rx Expiration date [' + MH_Rx + '] on Medical history should be greater than Today\'s Date.');}
                    }
                    }                   
            /******* VALIDATIONS  FOR  GATCF CASE SHIPMENT ******/
            if(CasRec.recordtype.name =='GATCF - Standard Case')
            {   if(trigger.isInsert)
                {  if(GATCF_Profiles !=null && GATCF_Profiles.containsKey(profile_name))
                    { } 
                    else
                    { ship.adderror('Error found - You do not have sufficient permissions to create GATCF Shipments. Please contact your administrator.');}
                    if(CasRec.GATCF_Status_gne__c=='Approved - Contingent Enrollment' && (CasRec.GATCF_Enroll_Date_gne__c ==null || CasRec.GATCF_Enroll_Date_gne__c.adddays(45) <=system.now()))
                    { ship.adderror('Error found - Today\'s Date must be less than 45 days from GATCF Enrollment Date [' + GATCFCs_Enr + '] on Case.'); }                            
                    // 07/02/09 - Alex Chupkin M&E T130 -- Add validation to all products
                    //KS: VISMO: 11/24/2011: Added Vismo in If condition
                    if((CasRec.product_gne__c =='Nutropin' || CasRec.product_gne__c =='Lucentis' || CasRec.product_gne__c =='Raptiva' ||
                      CasRec.product_gne__c =='Xolair' || CasRec.product_gne__c =='Rituxan RA' || CasRec.product_gne__c =='Avastin' || 
                      CasRec.product_gne__c =='Herceptin' || CasRec.product_gne__c =='Tarceva' || CasRec.product_gne__c =='Activase' ||
                      CasRec.product_gne__c =='Pulmozyme' || CasRec.product_gne__c =='Rituxan' || CasRec.product_gne__c =='TNKase' || CasRec.product_gne__c =='Actemra' || CasRec.product_gne__c =='Xeloda' || CasRec.product_gne__c == cobi_product_name || CasRec.product_gne__c ==braf_product_name || CasRec.product_gne__c == vismo_product_name || CasRec.product_gne__c == pertuzumab_product_name || CasRec.product_gne__c == TDM1_product_name || CasRec.product_gne__c == boomerang_product_name) &&  
                      (CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c ==null || CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c <=system.today()))
                    { ship.adderror('Error found - GATCF SMN Expiration date [' + MH_SMN + '] on Medical History should be greater than Today\'s Date.');} 
                    if((CasRec.product_gne__c =='Rituxan' || CasRec.product_gne__c =='Herceptin' || CasRec.product_gne__c =='Tarceva' || CasRec.product_gne__c =='Avastin' || CasRec.product_gne__c =='Activase' || CasRec.product_gne__c =='TNKase'|| CasRec.product_gne__c =='Xeloda' || CasRec.product_gne__c == cobi_product_name || CasRec.product_gne__c == pertuzumab_product_name || CasRec.product_gne__c == TDM1_product_name || CasRec.product_gne__c == boomerang_product_name) && 
                      (CasRec.Enrollment_Form_Rec_gne__c ==null ||
                       System.now() >=CasRec.Enrollment_Form_Rec_gne__c.addyears(1) ||
                       System.now() < CasRec.Enrollment_Form_Rec_gne__c))
                    { ship.adderror('Error found - Today\'s Date must be greater than Enroll/SMN Form Rec Date ['+ Cs_Enr + '] on Case and must not exceed 1 year from the Enroll/SMN Form Rec Date.' );}
                    // Added condition of Shipment type to product Atemra for Defect # 8961
                    //KS: VISMO: 11/24/2011: Added Vismo in If condition
                    if((CasRec.product_gne__c =='Nutropin' || CasRec.product_gne__c =='Pulmozyme' || CasRec.product_gne__c =='Raptiva' || CasRec.product_gne__c =='Tarceva' || CasRec.product_gne__c =='Xolair' || CasRec.product_gne__c == cobi_product_name || CasRec.product_gne__c ==braf_product_name || CasRec.product_gne__c == vismo_product_name || CasRec.product_gne__c == boomerang_product_name || (CasRec.product_gne__c =='Actemra' && ship.Action_gne__c !='GATCF Replacement')) && 
                      (CasRec.medical_history_gne__r.Rx_Expiration_gne__c ==null || CasRec.medical_history_gne__r.Rx_Expiration_gne__c <=system.today()))
                    { ship.adderror('Error found - Rx Expiration date [' + MH_Rx + '] on Medical History should be greater than Today\'s Date.');}
                    
                    //KS: VISMO: 11/24/2011: Added Vismo in If condition
                    if ((CasRec.GATCF_Status_gne__c ==null || CasRec.GATCF_Status_gne__c !='Approved - Contingent Enrollment') && 
                        ((CasRec.Eligibility_Determination_Date_gne__c ==null ) || (System.now() >=CasRec.Eligibility_Determination_Date_gne__c.addyears(1)) ||
                         (System.now() < CasRec.Eligibility_Determination_Date_gne__c)) && CasRec.product_gne__c !=braf_product_name && CasRec.product_gne__c != cobi_product_name && CasRec.product_gne__c != vismo_product_name && CasRec.product_gne__c != boomerang_product_name)
                    { ship.adderror('Error found - Today\'s Date must be greater than or equal to Eligibility Determination Date ['+ Cs_ED + '] on Case and must not exceed 1 year from the Eligibility Determination Date.' );}
                    
                    //KS: VISMO: 11/24/2011: Added Vismo in If condition
                    if(CasRec.product_gne__c !=braf_product_name && CasRec.product_gne__c != cobi_product_name && CasRec.product_gne__c != vismo_product_name && CasRec.product_gne__c != boomerang_product_name) 
                    {
                        if(CasRec.GATCF_Status_gne__c =='Approved' || CasRec.GATCF_Status_gne__c =='Approved - Part D Extension' || CasRec.GATCF_Status_gne__c =='Conditional Enrollment Approved' || CasRec.GATCF_Status_gne__c =='Approved - In Appeal' || CasRec.GATCF_Status_gne__c =='Approved - Contingent Enrollment')
                        {} 
                        else
                        {ship.adderror('Error found - The GATCF Status ['+ CasRec.GATCF_Status_gne__c + '] on Case must be one of the Approved statuses in order to create a shipment');}
                    }
                    else {                 
                    if(CasRec.GATCF_Status_gne__c =='Approved' || CasRec.GATCF_Status_gne__c =='Approved - Part D Extension' || CasRec.GATCF_Status_gne__c =='Approved - In Appeal' || CasRec.GATCF_Status_gne__c =='Approved - Contingent Enrollment' )
                    {} 
                    else
                    {ship.adderror('Error found - The GATCF Status ['+ CasRec.GATCF_Status_gne__c + '] on Case must be one of the Approved statuses in order to create a shipment');}
                    
                    //For BRAF
                    if ((CasRec.GATCF_Status_gne__c ==null || CasRec.GATCF_Status_gne__c !='Approved - Contingent Enrollment') && 
                        ((CasRec.Approval_Date_gne__c ==null ) || (System.today() >=CasRec.Approval_Date_gne__c.addyears(1)) ||
                         (System.today() < CasRec.Approval_Date_gne__c)))
                    { ship.adderror('Error found - Today\'s Date must be greater than or equal to Approval Date ['+ Cs_AD + '] on Case and must not exceed 1 year from the Approval Date.' );}
                    
                    
                    }              
                    if(CasRec.Case_Treating_Physician_gne__c ==null)
                    {   if (CasRec.product_gne__c =='Activase' || CasRec.product_gne__c =='TNKase' )
                        {}
                        else 
                        ship.adderror('Error found - No treating physician aligned to Case.');
                    }
                    } 
                } // End of GATCF Case Shipment
            if(trigger.isInsert)
            {  if(CasRec.patient_gne__c !=null && ship.Case_Shipment_Request_gne__c==null)
                {  if(((CasRec.patient_gne__r.PAN_Form_1_Expiration_Date_gne__c !=null && CasRec.patient_gne__r.PAN_Form_1_Expiration_Date_gne__c >=system.today()) || 
                        (CasRec.patient_gne__r.PAN_Form_2_Exipration_Date_gne__c !=null && CasRec.patient_gne__r.PAN_Form_2_Exipration_Date_gne__c >=system.today()))
                        || (CasRec.product_gne__c =='Actemra' && CasRec.recordtype.name =='C&R - Continuous Care Case'))
                    { }
                    else
                    ship.adderror('No unexpired PAN found on Patient. Either of PAN Expiration 1/PAN Expiration 2 Date should be greater than/equal to current date.');
                }     
            }    
            if( Case_Profiles !=null && !(Case_Profiles.containsKey(profile_name)) && CasRec.Status.startsWith('Closed') && System.now() >=(CasRec.ClosedDate.addDays(2)))   
                ship.adderror('Shipment cannot be created/edited once associated case has been Closed for 48 hours or more.');
            if(CasRec.patient_gne__c !=null)
            {   ship.Patient_gne__c=CasRec.patient_gne__c;                                           
                /* nleblanc - T-385 Case Type must be CCP for Xolair until ESB update */
                if(CasRec.product_gne__c =='Xolair' && ship.Case_Shipment_Request_gne__c !=null)
                {   ship.Case_Type_gne__c='C&R - Continuous Care Case';      
                }
                else
                    ship.Case_Type_gne__c=CasRec.RecordType.Name;      
            }       
            if(ship.Account_gne__c !=null)
            {   ship.Product_gne__c='Herceptin';
                ship.Case_Type_gne__c='GATCF - Standard Case';
            }      
            else
                ship.Product_gne__c=CasRec.Product_gne__c;                      
       } // end of if
        //kostusir - 12/01/2010 - HD0000002145074 - Shipment Validation Rule Adjustment for PR
        if (ship.State_UI_gne__c !=null && ship.State_UI_gne__c !='')
        {
            if (Shipment_State_Country.containsKey(ship.State_UI_gne__c)) // if State == 'PR'
            {
                ship.Country_gne__c = Shipment_State_Country.get(ship.State_UI_gne__c); //then Country_gne__c = 'Puerto Rico'
                ship.State_gne__c = ship.State_UI_gne__c;
                ship.State_UI_gne__c = null;
            }
            else
                ship.State_gne__c = ship.State_UI_gne__c;
        }
        if (ship.Country_gne__c !=null && ship.Country_gne__c !='')
        {
            if (Shipment_Country_State.containsKey(ship.Country_gne__c.toUpperCase())) //if Country_gne__c = 'Puerto Rico'
            {
                ship.State_UI_gne__c = null;
                ship.State_gne__c = Shipment_Country_State.get(ship.Country_gne__c.toUpperCase()); //then State_gne__c= 'PR'
            }
            else
                ship.State_gne__c = ship.State_UI_gne__c;           
        }
        else
        {
            ship.Country_gne__c = 'UNITED STATES';
            ship.State_gne__c = null;
        }          
       
        }// End of if Sent to ESB ==false            
   }
       catch(exception e)
       { ship.adderror('Unexpected Error occured while creating Shipment record' + e.getMessage());} // End of catch
   } // end of for
    for(Shipment_gne__c ship :Trigger.new)
    { try
       { if(ship.Sent_to_ESB_gne__c ==false)
            { ShipListPrice=0.0; ShipWAPrice=0.0; double Qty1, Qty2, Qty3;
            if((ship.Product_gne__c !=null) && (ship.Action_gne__c !=null) && (ship.Case_Type_gne__c !=null))
            {   ShipInfo=ship.Case_Type_gne__c + ship.Action_gne__c + ship.Product_gne__c;
                //KS: VISMO: 11/24/2011: Added Vismo in Ifcondition 
                //AS: TARCEVA: 05/19/2012: Added Tarceva in Ifcondition
                if(ship.Case_Type_gne__c == 'C&R - Standard Case' && (ship.Product_gne__c == cobi_product_name || ship.Product_gne__c == braf_product_name || ship.Product_gne__c == vismo_product_name || ship.Product_gne__c == Tarceva_product_name || ship.Product_gne__c == boomerang_product_name))
                ShipInfo=ship.Case_Type_gne__c + 'Starter Prescription' + ship.Product_gne__c;
                if(SAPInfo.containsKey(ShipInfo))
                    ship.SAP_Account_Id_gne__c=SAPInfo.get(ShipInfo);
                if(ShippedFromSite.containsKey(ShipInfo))
                    ship.Shipped_From_Site_gne__c=ShippedFromSite.get(ShipInfo);
                    system.debug('inside case shipment prepopulate trigger.....');
                    system.debug('ship.Shipped_From_Site_gne__c..............' + ship.Shipped_From_Site_gne__c);
                if(ShipActionTypeID.containsKey(ShipInfo))
                    ship.Ship_Action_Type_Code_gne__c=ShipActionTypeID.get(ShipInfo);
                if(ProductGroupId.containsKey(ShipInfo))
                    ship.Ship_Action_Product_Code_gne__c=ProductGroupId.get(ShipInfo);
            } 
        Ship.SAP_Material_Id_1_gne__c=''; Ship.SAP_Material_Id_2_gne__c=''; Ship.SAP_Material_Id_3_gne__c=''; 
        ship.List_price_1_gne__c=null; ship.List_price_2_gne__c=null; ship.List_price_3_gne__c=null;
        // If Drug value for Activase changes then change the corresponding NDC #. 
        if (trigger.isUpdate && ship.Product_gne__c =='Activase' && ship.Drug_gne__c !=system.trigger.oldmap.get(ship.Id).Drug_gne__c)
        {   if(ship.Drug_gne__c.toUpperCase().startsWith('CATHFLO'))
            {   ship.Product_Vial_P1_gne__c=ProdVialPrices.get(CathfloNDC).Name;
                ship.NDC_Product_Vial_1_gne__c=ProdVialPrices.get(CathfloNDC).NDC_Number_gne__c;
                ship.Quantity_2_gne__c=null; ship.Product_Vial_P2_gne__c='';ship.NDC_Product_Vial_2_gne__c=null;
            } 
            else
            {  if(ship.Drug_gne__c.startsWith('Activase')) 
                {   for (integer la =0 ; la <ActivaseProductInfo.size(); la++)
                    { if (la ==0)
                     {  ship.Product_Vial_P1_gne__c=ActivaseProductInfo[la].Name;
                        ship.NDC_Product_Vial_1_gne__c=ActivaseProductInfo[la].NDC_Number_gne__c;
                     }
                     if(la ==1)
                     {  ship.Product_Vial_P2_gne__c=ActivaseProductInfo[la].Name; ship.NDC_Product_Vial_2_gne__c=ActivaseProductInfo[la].NDC_Number_gne__c;}
                    } 
                }  
                else 
                { ship.Quantity_1_gne__c=null; ship.Product_Vial_P1_gne__c='';ship.NDC_Product_Vial_1_gne__c=null;ship.Quantity_2_gne__c=null; ship.Product_Vial_P2_gne__c='';ship.NDC_Product_Vial_2_gne__c=null;}
            } // end of else
        } 
        system.debug('ship.Actual_Quantity1_gne__c: ' + ship.Actual_Quantity1_gne__c);

        if (ship.Shipped_From_Site_gne__c =='RxCrossroads' && (ship.Actual_Quantity1_gne__c !=null || ship.Actual_Quantity2_gne__c !=null || ship.Actual_Quantity3_gne__c !=null))
        {   Qty1=ship.Actual_Quantity1_gne__c ==null ? 0 : ship.Actual_Quantity1_gne__c; Qty2=ship.Actual_Quantity2_gne__c ==null ? 0 : ship.Actual_Quantity2_gne__c; Qty3=ship.Actual_Quantity3_gne__c ==null ? 0 : ship.Actual_Quantity3_gne__c;
           system.debug('Qty1' + Qty1 + 'Qty2' + Qty2 + 'Qty3' + Qty3);
        }
        else 
        {   Qty1=ship.Quantity_1_gne__c ==null ? null : ship.Quantity_1_gne__c; Qty2=ship.Quantity_2_gne__c ==null ? null : ship.Quantity_2_gne__c; Qty3=ship.Quantity_3_gne__c ==null ? null : ship.Quantity_3_gne__c;
           system.debug('Qty1' + Qty1 + 'Qty2' + Qty2 + 'Qty3' + Qty3);

        } 
        // If there is any calculation change for these please ensure that the corresponding change is also made in other trigger for Nutropin, Raptiva and Xolair.
        system.debug('Ship.NDC_Product_Vial_1_gne__c...........' + Ship.NDC_Product_Vial_1_gne__c);
        boolean testflag = false;
        if(ProdVialPrices.ContainsKey(Ship.NDC_Product_Vial_1_gne__c))
        {
            testflag =true;
        }
        system.debug('testflag value........' + testflag);
        
        if((Ship.NDC_Product_Vial_1_gne__c !=null) && (ProdVialPrices.ContainsKey(Ship.NDC_Product_Vial_1_gne__c)))    
        {   system.debug('------------------> Enter into this code');
            Ship.SAP_Material_Id_1_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).SAP_Material_ID_gne__c;  
            if(ship.Product_gne__c !='Xeloda' )                     //&& (ship.Product_gne__c != Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case')
            ship.List_price_1_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c;
            else
            {
                ship.List_price_1_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Tablet_List_Price_gne__c;
                system.debug('-------------------->ship.List_price_1_gne__c'+ship.List_price_1_gne__c);
            }
            //KS: VISMO: 11/24/2011: Added Vismo in if condition
            if (Qty1 !=null && ((ship.Product_gne__c != cobi_product_name && ship.Product_gne__c !='Avastin' && ship.Product_gne__c !='Nutropin' && Ship.Product_gne__c !='Raptiva' && ship.Product_gne__c !='Xolair' && ship.Product_gne__c !='Xeloda' && ship.Product_gne__c !=braf_product_name && ship.Product_gne__c != vismo_product_name && ship.Product_gne__c != boomerang_product_name) && ship.Product_gne__c != Tarceva_product_name))
            { 
               if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c; 
            }
            if(Qty1 !=null && (ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case'))
            { 
               if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c; 
            }
        //BRAF
        //KS: VISMO: 11/24/2011: Added Vismo in if condition
        //AS: Tarceva: 06/08/2012
        system.debug('Qty1: ' + Qty1);
        system.debug('Qty2: ' + Qty2);
        system.debug('Qty3: ' + Qty3);
         
           if (Qty1 !=null && (ship.Product_gne__c == cobi_product_name || ship.Product_gne__c =='Xeloda' || ship.Product_gne__c ==braf_product_name || ship.Product_gne__c == vismo_product_name || ship.Product_gne__c == boomerang_product_name || (ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c == 'C&R - Standard Case')))
            {   
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Tablet_List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Tablet_List_Price_gne__c;
            }
            if (Qty1 !=null && ship.Product_gne__c == 'Avastin')//CM-83: HN: Loop added for Avastin
            { 
               if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty1*ProdVialPrices.get(Ship.NDC_Product_Vial_1_gne__c).List_Price_gne__c; 
            }               
        }
        if((Ship.NDC_Product_Vial_2_gne__c !=null) && (ProdVialPrices.ContainsKey(Ship.NDC_Product_Vial_2_gne__c)))    
        {   Ship.SAP_Material_Id_2_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).SAP_Material_ID_gne__c; 
            if(ship.Product_gne__c !='Xeloda' && (ship.Product_gne__c != Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case'))
            ship.List_price_2_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c;
            else
            ship.List_price_2_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Tablet_List_Price_gne__c;
            if (Qty2 !=null && ((ship.Product_gne__c !='Avastin' && ship.Product_gne__c !='Nutropin' && Ship.Product_gne__c !='Raptiva' && ship.Product_gne__c !='Xolair' && ship.Product_gne__c !='Xeloda') && ship.Product_gne__c != Tarceva_product_name))////AS: Tarceva: 06/08/2012
            {   if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c; 
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c;
            }
            if (Qty2 !=null && (ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case'))////AS: Tarceva: 06/08/2012
            {   if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c; 
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c;
            }
            //AS: Tarceva: 06/08/2012
            else if((Qty2 !=null && ship.Product_gne__c =='Xeloda') || (Qty2 !=null && ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c == 'C&R - Standard Case')) 
            {
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Tablet_List_Price_gne__c!=null)            
                    ShipListPrice=ShipListPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Tablet_List_Price_gne__c; 
            }
            else if(Qty2 !=null && ship.Product_gne__c =='Avastin')//CM-83: HN: Loop added for Avastin 
            {
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).Wholesale_Acquisition_Price_gne__c;
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c!=null)            
                    ShipListPrice=ShipListPrice + Qty2*ProdVialPrices.get(Ship.NDC_Product_Vial_2_gne__c).List_Price_gne__c; 
            }
        } 
        if((Ship.NDC_Product_Vial_3_gne__c !=null) && (ProdVialPrices.ContainsKey(Ship.NDC_Product_Vial_3_gne__c)))    
        {   Ship.SAP_Material_Id_3_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).SAP_Material_ID_gne__c; 
            if(ship.Product_gne__c !='Pegasys' && (ship.Product_gne__c != Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case'))
            ship.List_price_3_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).List_Price_gne__c;
            else
            ship.List_price_3_gne__c=ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Tablet_List_Price_gne__c;
            if (Qty3 !=null && ((ship.Product_gne__c !='Avastin' && ship.Product_gne__c !='Nutropin' && Ship.Product_gne__c !='Raptiva' && ship.Product_gne__c !='Xolair' && ship.Product_gne__c !='Pegasys') && ship.Product_gne__c != Tarceva_product_name))//AS: Tarceva: 06/08/2012
            {   if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).List_Price_gne__c; 
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Wholesale_Acquisition_Price_gne__c;
            }
            if (Qty3 !=null && (ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c != 'C&R - Standard Case'))//AS: Tarceva: 06/08/2012
            {   if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).List_Price_gne__c; 
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Wholesale_Acquisition_Price_gne__c;
            }
            //AS: Tarceva: 06/08/2012
            else if((Qty3 !=null && ship.Product_gne__c =='Pegasys') || (Qty3 !=null && ship.Product_gne__c == Tarceva_product_name && ship.Case_Type_gne__c == 'C&R - Standard Case'))
            {   
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Tablet_List_Price_gne__c!=null)
                    ShipListPrice=ShipListPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Tablet_List_Price_gne__c; 
                if (ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c !=null)
                    ShipWAPrice=ShipWAPrice + Qty3*ProdVialPrices.get(Ship.NDC_Product_Vial_3_gne__c).Tablet_Wholesale_Acquisition_Price_gne__c;
            }
        }
        System.debug('[DZ] ship.NDC_Product_Vial_1_gne__c: ' + Ship.NDC_Product_Vial_1_gne__c);
        System.debug('[DZ] Ship.NDC_Product_Vial_2_gne__c: ' + Ship.NDC_Product_Vial_2_gne__c);
        System.debug('[DZ] Ship.NDC_Product_Vial_3_gne__c: ' + Ship.NDC_Product_Vial_3_gne__c);
        
        System.debug('[DZ] ShipListPrice: ' + ShipListPrice);
        System.debug('[DZ] ShipWAPrice: ' + ShipWAPrice);
        System.debug('[DZ] ship.Product_gne__c: ' + ship.Product_gne__c);
           
        if (ship.Product_gne__c !=null && ship.Product_gne__c !='Nutropin' && Ship.Product_gne__c !='Raptiva' && ship.Product_gne__c !='Xolair')
        {   ship.Total_Shipment_Cost_List_Price_gne__c=ShipListPrice;
            ship.Total_Shipment_Cost_Wholesale_Price_gne__c=ShipWAPrice;
            system.debug('---------------------->Calculated Values'+ship.Total_Shipment_Cost_Wholesale_Price_gne__c+'---------------------->Calculated Values1'+ship.Total_Shipment_Cost_List_Price_gne__c);
        } 
        if((ship.Product_gne__c =='Xolair') && (ship.Dose_Frequency_in_weeks_gne__c !=null) && (ship.Dosage_Authorized_gne__c !=null) && (ship.Case_Type_gne__c =='GATCF - Standard Case'))
        {   if(ship.Dose_Frequency_in_weeks_gne__c =='Every 4 weeks')
            {   ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(ship.Dosage_Authorized_gne__c.intValue() * 28);
                ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays((ship.Dosage_Authorized_gne__c.intValue() * 28)-10);
            }
           if((ship.Dose_Frequency_in_weeks_gne__c =='Every 2 weeks') && (ship.Dosage_Authorized_gne__c !=null))
            {   ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(ship.Dosage_Authorized_gne__c.intValue() * 14);
                ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays((ship.Dosage_Authorized_gne__c.intValue() * 14)-10);
            }
        }
        if(ship.Case_Shipment_Request_gne__c!=null) {
        //stamp SAP Material Id for Shipment Request
        if(ProdVialPrices.containsKey(ship.NDC_Number_gne__c))
         ship.SAP_Material_Id_1_gne__c=ProdVialPrices.get(ship.NDC_Number_gne__c).SAP_Material_ID_gne__c;
        //stamp A Account and Shipped From Site             
        ShipInfo=ship.Case_Type_gne__c + 'null'+ship.Product_gne__c;
        if(SAPInfo.containsKey(ShipInfo))
          ship.SAP_Account_Id_gne__c=SAPInfo.get(ShipInfo);
        if(ShippedFromSite.containsKey(ShipInfo))
          ship.Shipped_From_Site_gne__c=ShippedFromSite.get(ShipInfo);     
        if(ship.Status_gne__c=='OH - On Hold')
        ship.Status_gne__c='PE - Pending';   
        }                               
        }               
    }
    catch(exception e)
    {  ship.adderror('Unexpected Error : '+ e.getMessage());} 
}  
} // end of global try
 catch(exception e)
  {
    for (Shipment_gne__c Ship: Trigger.new)
    {Ship.adderror('Processing for the Shipment record stopped! Unexpected Error in getting the Shipment related information from other objects: ' + e.getMessage());}
  }
   finally
   {    GATCF_Profiles.clear();CRProfiles.clear();Case_Profiles.clear();caseidset.clear();SR_Create_Profiles.clear();
       // Case_map.clear(); 
        SAPInfo.clear();
       // ShipActionRecords.clear();
        ProdVialPrices.clear();
      //  ProductVialInfo.clear();
   } 
}   //end of triggerIsInProcess              
}