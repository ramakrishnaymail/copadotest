//Trigger for Pegasys and any other new products
//If any new product is to be added, make sure to add the product name in GNE_CM_Shipment_Parent_Class
/*
PKambalapally PFS-1074.2/20/2014 Need to update these fields on shipment everytime MH is updated:
	Product_Supply_Type_gne__c,NDC_Product_Vial_1_gne__c,Product_Vial_P1_gne__c,NDC_Product_Vial_3_gne__c,Product_Vial_P3_gne__c
but only if the shipment isn't released yet.i.e., the shipment status = 'OH - On Hold'
PKambalapally 3/10/2014 PFS-1074. Bulkified code by moving out environmentVariable and Product vial queries out of for loop. 

*/
trigger GNE_CM_Shipment_Trigger on Shipment_gne__c (before insert, before update) {
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger || GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
     return;
   }
    
    Set<Id> caseidset =new Set<Id>();
    Map<Id, Case> Case_map=new  Map<Id, Case>(); 
    Case CasRec=new Case();
    String MH_Rx, MH_SMN, Cs_Enr, profile_name;
    Double dosage_0_5_ml = 0;
    Double dosage_1ml = 0;
    double dosage_copegus=0;
    string dispense_copegus;
    Id CaseId;
    boolean Sent_to_ESB=true;    
    Map<String, Case> MHFields=new Map<String, Case>(); 
    string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
    string vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    
    //AS: TARCEVA 05/19/2012
    string Tarceva_product_name = system.label.GNE_CM_TARCEVA_Product_Name;
    
    //[DZ] 02/12/2015 Cotellic
  	String cobi_product_name = system.label.GNE_CM_Cotellic_Product_Name;
    
  	String boomerang_product_name = system.label.GNE_CM_Boomerang_Product_Name;
    
    //AS Changes : PFS-747
    Set<Id> caseIdActemraCheck = new Set<Id>(); 
    List<Shipment_gne__c> lstToCheckShipment = new List<Shipment_gne__c>(); 
    Integer shipmentCountActemra = 0;
    Profile p = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()];
    String currentProfileName = p.Name;
    
    Medical_History_gne__c MH=new Medical_History_gne__c();
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig6()) // Global check for static variable to make sure trigger executes only once
    {
        GNE_CM_case_trigger_monitor.setTriggerInProcessTrig6(); // Setting the static variable to avoid trigger exec after workflow update
        try
        {  
            for(Shipment_gne__c ship :Trigger.new)
            {    
                if(ship.Sent_to_ESB_gne__c ==false)
                { 
                    Sent_to_ESB=false;           
                    if(ship.Case_Shipment_gne__c !=null)
                    CaseId =ship.Case_Shipment_gne__c;
                    else if(ship.Case_Shipment_Request_gne__c!=null) 
                    CaseId =ship.Case_Shipment_Request_gne__c;
                    if (CaseId !=null)
                    caseidset.add(CaseId);
                }
                //AS Changes : PFS-747
                if(ship.Case_Shipment_gne__c!=null && ship.Product_gne__c == 'Actemra')
                caseIdActemraCheck.add(ship.Case_Shipment_gne__c);
            }   //end of for
            if(caseIdActemraCheck.size() > 0)
            {
            	lstToCheckShipment = [Select id from Shipment_gne__c where Status_gne__c = 'SH - Shipped' and Case_Shipment_gne__c in :caseIdActemraCheck];
            	if(!lstToCheckShipment.isEmpty())
            	shipmentCountActemra = lstToCheckShipment.size();
            } 
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
                system.debug('*********CASE MAP*****'+Case_map);
                if(!GNE_CM_Shipment_Parent_Class.shipment_related_flag)
                {
                    GNE_CM_Shipment_Parent_Class.setshipment_related_info(caseidset);
                    MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();
                }
                else 
                MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();          
                
                system.debug('CHECK MH1'+MHFields);      
            }// if Sent_to_ESB ==false

            //PKambalapally 3/10/2014 PFS-1074. Bulkified
            GNE_CM_Shipment_Parent_Class.setproductvialinfo();
            List<Product_vod__c> productVialInfo = GNE_CM_Shipment_Parent_Class.getproductvialinfo();
            /*
            Map<String,List<Environment_Variables__c>> environmentVarMap = new Map<String,List<Environment_Variables__c>>();
            List<Environment_Variables__c> environment_var_val;
            environmentVarMap = GNE_CM_MPS_Utils.populateEnvVariables(new Set<String>{'GNE-CM-Pegasys-SubType-Val'});
            if(environmentVarMap!=null){
                environment_var_val = environmentVarMap.get('GNE-CM-Pegasys-SubType-Val');
            }
			*/
            for(Shipment_gne__c ship :Trigger.new)
            {  
                try
                {  if(ship.Sent_to_ESB_gne__c ==false)
                    {   if(ship.Case_Shipment_gne__c !=null)
                        CaseId =ship.Case_Shipment_gne__c;
                        else if(ship.Case_Shipment_Request_gne__c!=null)
                        CaseId =ship.Case_Shipment_Request_gne__c;
                        
                        CasRec=case_map.get(CaseId);
                        if(CaseId !=null && Case_map.containsKey(CaseId))
                        {   
                            if (CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c ==null)
                            MH_SMN=String.ValueOf(CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c);
                            else MH_SMN=CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c.format();
                            if (CasRec.Enrollment_Form_Rec_gne__c==null)
                            Cs_Enr=String.ValueOf(CasRec.Enrollment_Form_Rec_gne__c);
                            else Cs_Enr=CasRec.Enrollment_Form_Rec_gne__c.format();
                            
                            /******* VALIDATIONS  FOR  GATCF CASE SHIPMENT ******/
                            if(CasRec.recordtype.name =='GATCF - Standard Case')
                            {   if(trigger.isInsert)
                                {  
                                    if((CasRec.product_gne__c =='Pegasys' || CasRec.product_gne__c =='Actemra Subcutaneous') && (CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c ==null || CasRec.medical_history_gne__r.GATCF_SMN_Expiration_Date_gne__c <=system.today()))
                                    { ship.adderror('Error found - GATCF SMN Expiration date [' + MH_SMN + '] on Medical history should be greater than Today\'s Date.');} 
                                    if(CasRec.product_gne__c =='Pegasys' && (CasRec.Enrollment_Form_Rec_gne__c ==null || System.now() >=CasRec.Enrollment_Form_Rec_gne__c.addyears(1) || System.now() < CasRec.Enrollment_Form_Rec_gne__c))
                                    { ship.adderror('Error found - Today\'s Date must be greater than Enroll/SMN Form Rec Date ['+ Cs_Enr + '] on Case and must not exceed 1 year from the Enroll/SMN Form Rec Date.' );}
                                    // Added condition of Shipment type to product Atemra for Defect # 8961
                                    
                                    //Rx Expiration Date Check for Pegasys
                                    if(CasRec.product_gne__c == 'Pegasys'){
                                        MH_Rx = 'Valid';         
                                        if(CasRec.Medical_History_gne__r.Rx_Expiration_gne__c != null && CasRec.Medical_History_gne__r.Rx_Expiration_gne__c <= system.Today())
                                        MH_Rx= CasRec.Medical_History_gne__r.Rx_Expiration_gne__c.format();       
                                        else if(CasRec.Medical_History_gne__r.Rx_Expiration_Pegasys_1ml_gne__c != null && CasRec.Medical_History_gne__r.Rx_Expiration_Pegasys_1ml_gne__c <= system.Today())
                                        MH_Rx= CasRec.Medical_History_gne__r.Rx_Expiration_Pegasys_1ml_gne__c.format();
                                        else if(CasRec.Medical_History_gne__r.Rx_Expiration_Copegus_gne__c != null && CasRec.Medical_History_gne__r.Rx_Expiration_Copegus_gne__c <= system.Today())
                                        MH_Rx=CasRec.Medical_History_gne__r.Rx_Expiration_Copegus_gne__c.format();
                                        else if(CasRec.Medical_History_gne__r.Rx_Expiration_gne__c == null && CasRec.Medical_History_gne__r.Rx_Expiration_Copegus_gne__c == null && CasRec.Medical_History_gne__r.Rx_Expiration_Pegasys_1ml_gne__c ==null)
                                        MH_Rx= null;
                                        
                                        if(MH_Rx != 'Valid' )
                                        ship.adderror('Error found - Rx Expiration date ['+ MH_Rx + '] on Medical history should be greater than Todays Date.'); 
                                    }
                                    
                                } 
                            } // End of GATCF Case Shipment
                            
                        } // end of if
                        
                        if(trigger.isInsert)
                        {
                            if(ship.Case_Shipment_gne__c!=null) 
                            CaseId=ship.Case_Shipment_gne__c;
                            else if(ship.Case_Shipment_Request_gne__c!=null)
                            CaseId=ship.Case_Shipment_Request_gne__c;
                            
                            if(ship.Product_gne__c=='Pegasys'){
                                MH=MHFields.get(CaseId).medical_history_gne__r;
                                ship.Drug_gne__c=MH.Drug_gne__c;ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;
                                ship.NKDA_gne__c=MH.NKDA_gne__c;ship.SMN_Expiration_Date_gne__c=MH.SMN_Expiration_Date_gne__c;
                                ship.GATCF_SMN_Expiration_Date_gne__c=MH.GATCF_SMN_Expiration_Date_gne__c;
                                ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;ship.Dose_mg_kg_wk_gne__c=MH.Dose_mg_kg_wk_gne__c;
                                ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;ship.Others_Pegasys_Prefill_gne__c=MH.Other_Pegasys_Prefilled_gne__c;
                                ship.Dispense_gne__c=MH.Dispense_gne__c;ship.RefillX_PRN_gne__c=MH.RefillX_PRN_gne__c;
                                ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;ship.Rx_Refill_Expiration_Date1_gne__c=MH.Rx_Refill_Expiration_Date1_gne__c;
                                ship.Dose_mg_kg_wk_Pegasys_1ml_gne__c=MH.Dose_mg_kg_wk_Pegasys_1ml_gne__c;
                                ship.Freqcy_of_Admin_Pegasys_1ml_gne__c=MH.Freqcy_of_Admin_Pegasys_1ml_gne__c;
                                ship.Others_Pegasys_1ml_gne__c=MH.Others_Pegasys_1ml_gne__c;ship.Dispense_Pegasys_1ml_gne__c=MH.Dispense_Pegasys_1ml_gne__c;
                                ship.RefillX_PRN_Pegasys_1ml_gne__c=MH.RefillX_PRN_Pegasys_1ml_gne__c;
                                ship.Rx_Expiration_Pegasys_1ml_gne__c=MH.Rx_Expiration_Pegasys_1ml_gne__c;
                                ship.Rx_Refill_Expiration_Date2_gne__c=MH.Rx_Refill_Expiration_Date2_gne__c;
                                ship.Dose_mg_kg_wk_Copegus_gne__c=MH.Dose_mg_kg_wk_Copegus_gne__c;
                                ship.Freqcy_of_Admin_Copegus_gne__c=MH.Freqcy_of_Admin_Copegus_gne__c;
                                ship.Others_Copegus_gne__c=MH.Others_Copegus_gne__c;ship.Dispense_Copegus_gne__c=MH.Dispense_Copegus_gne__c;
                                ship.RefillX_PRN_Copegus_gne__c=MH.RefillX_PRN_Copegus_gne__c;ship.Rx_Expiration_Copegus_gne__c=MH.Rx_Expiration_Copegus_gne__c;
                                ship.Rx_Refill_Expiration_Date3_gne__c=MH.Rx_Refill_Expiration_Date3_gne__c;
                                ship.CM_200mg_of_Tablets_gne__c=MH.CM_200mg_of_Tablets_gne__c;
                                ship.CM_200mg_Total_Tablets_gne__c=MH.CM_200mg_Total_Tablets_gne__c;
                            }
                            
                            if(ship.Product_gne__c==braf_product_name){
                                MH=MHFields.get(CaseId).medical_history_gne__r;
                                
                                if(CasRec.recordtype.name =='GATCF - Standard Case')
                                {
                                    ship.SMN_Expiration_Date_gne__c = MH.GATCF_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                                    ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                                    ship.Dosage_BRAF_gne__c = MH.BRAF_Dosage_gne__c;
                                    ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_BRAF_gne__c;
                                    ship.Dispense_gne__c=MH.Dispense_gne__c;
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Frequency_of_Administration_BRAF_gne__c;
                                    ship.Other_GATCF_BRAF_gne__c = MH.Dosage_Other_BRAF_gne__c;
                                    ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.CM_240_mg_Total_Tablets_gne__c;
                                    ship.Refill_s_BRAF_gne__c = MH.Refill_s_BRAF_gne__c;                        
                                }
                                else if(CasRec.recordtype.name =='C&R - Standard Case')
                                {
                                    ship.SMN_Effective_Date_gne__c = MH.Starter_SMN_Effective_Date_gne__c;
                                    ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                                    ship.SMN_Expiration_Date_gne__c = MH.Starter_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Expiration_gne__c=MH.Starter_Rx_Expiration_Date_gne__c;
                                    ship.Dosage_BRAF_gne__c = MH.Starter_Dosage_gne__c;
                                    ship.Dispense_gne__c=MH.Starter_Dispense_gne__c;
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                                    ship.Starter_Other_BRAF_gne__c = MH.Starter_Other_gne__c;
                                    ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Starter_240mg_Total_Tablets_gne__c;
                                    ship.Refill_s_BRAF_gne__c = MH.Starter_Refill_gne__c;                       
                                }                  
                                
                            }
                            
                             if(ship.Product_gne__c==cobi_product_name)
                             {
                                MH=MHFields.get(CaseId).medical_history_gne__r;
                                
                                if(CasRec.recordtype.name =='GATCF - Standard Case')
                                {
                                    ship.SMN_Expiration_Date_gne__c = MH.GATCF_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Date_gne__c = MH.Rx_Date_gne__c;
                                    ship.Rx_Expiration_gne__c = MH.Rx_Expiration_gne__c;
                                    ship.Dispense_gne__c= MH.Dispense_gne__c;
                                    ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_Cotellic_Days__c;
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Frequency_of_Administration_BRAF_gne__c;
                                    ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.X20mg_Total_Tablets__c;
                                    ship.Refill_s_BRAF_gne__c = MH.Refill_s_BRAF_gne__c;
                                }
                                else if(CasRec.recordtype.name =='C&R - Standard Case')
                                {
                                    ship.SMN_Effective_Date_gne__c = MH.Starter_SMN_Effective_Date_gne__c;
                                    ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                                    ship.SMN_Expiration_Date_gne__c = MH.Starter_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Expiration_gne__c=MH.Starter_Rx_Expiration_Date_gne__c;
                                    ship.Dispense_gne__c= MH.Starter_Dispense_gne__c;
                                    ship.Dosage_BRAF_gne__c = MH.Starter_Dosage_gne__c;
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                                    ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Starter_20mg_Total_Tablets__c;
                                    ship.Refill_s_BRAF_gne__c = MH.Starter_Refill_gne__c;
                                }                  
                                
                            }
                
                            if(ship.Product_gne__c == boomerang_product_name)
                            {
                                MH = MHFields.get(CaseId).medical_history_gne__r;
                                if(CasRec.recordtype.name =='GATCF - Standard Case')
                                {
                                    ship.SMN_Expiration_Date_gne__c = MH.GATCF_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Date_gne__c = MH.Rx_Date_gne__c;
                                    ship.Rx_Expiration_gne__c = MH.Rx_Expiration_gne__c;
                                    
                                    
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Frequency_of_Administration_BRAF_gne__c;
									ship.Refill_s_BRAF_gne__c = MH.Refill_s_BRAF_gne__c;
									
                        			if (ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Initial Titration' ) 
									{
										ship.Dispense_gne__c= MH.Dispense_gne__c;
										ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Total_267_mg_Tabletsf__c;
										ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_BRAF_gne__c;
									}
									else if(ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Maintenance')
									{
										ship.Dispense_gne__c= MH.Dispense_Maintenance__c;
										ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Total_267_mg_Tablets_maint__c;
										ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_maintenance__c;
									}
                                }
                                else if(CasRec.recordtype.name =='C&R - Standard Case')
                                {
                                    ship.SMN_Effective_Date_gne__c = MH.Starter_SMN_Effective_Date_gne__c;
                                    ship.Rx_Date_gne__c=MH.Starter_Rx_Date_gne__c;
                                    ship.SMN_Expiration_Date_gne__c = MH.Starter_SMN_Expiration_Date_gne__c;
                                    ship.Rx_Expiration_gne__c=MH.Starter_Rx_Expiration_Date_gne__c;
                                    ship.Dosage_BRAF_gne__c = MH.Starter_Dosage_gne__c;
                                    ship.Dispense_gne__c= MH.Starter_Dispense_gne__c;
                                    ship.Dispense_CR_Boomerang_gne__c = MH.Starter_Dispense_gne__c;
                                    ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                                    ship.Refill_s_BRAF_gne__c = MH.Starter_Refill_gne__c;
                                    ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Starter_267_mg_Total_Tabletsf__c;
                                }                  
                            }
                
                // stamping fields for vismodegib
                if(ship.Product_gne__c == vismo_product_name)
                {
                    MH = MHFields.get(CaseId).medical_history_gne__r;
                    system.debug('MH VALUES................' + mh);
                    if(CasRec.recordtype.name =='GATCF - Standard Case')
                    {
                        system.debug('inside gatcf case...........');
                        ship.SMN_Expiration_Date_gne__c = MH.GATCF_SMN_Expiration_Date_gne__c;
                        ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                        ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                        ship.Dosage_VISMO_gne__c = MH.BRAF_Dosage_gne__c;
                        ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_BRAF_gne__c;
                        ship.Dispense_gne__c=MH.Dispense_gne__c;
                        ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Frequency_of_Administration_BRAF_gne__c;
                        ship.Other_GATCF_BRAF_gne__c = MH.Dosage_Other_BRAF_gne__c;
                        system.debug('CM_150_mg_Total_Tablets_gne__c value........' + mh.CM_150_mg_Total_Tablets_gne__c);
                        ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.CM_150_mg_Total_Tablets_gne__c;
                        ship.Refill_s_BRAF_gne__c = MH.Refill_s_BRAF_gne__c; 
                        system.debug('ship values...........' + ship);                       
                    }
                    else if(CasRec.recordtype.name =='C&R - Standard Case')
                    {
                        system.debug('inside c&r case...........');
                        ship.SMN_Effective_Date_gne__c = MH.Starter_SMN_Effective_Date_gne__c;
                        ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                        ship.SMN_Expiration_Date_gne__c = MH.Starter_SMN_Expiration_Date_gne__c;
                        ship.Rx_Expiration_gne__c=MH.Starter_Rx_Expiration_Date_gne__c;
                        ship.Dosage_VISMO_gne__c = MH.Starter_Dosage_gne__c;
                        ship.Dispense_gne__c=MH.Starter_Dispense_gne__c;
                        ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                        ship.Starter_Other_BRAF_gne__c = MH.Starter_Other_gne__c;
                        ship.Total_Tablets_Dispensed_BRAF_gne__c = MH.Starter_150mg_Total_Tablets_gne__c;
                        ship.Refill_s_BRAF_gne__c = MH.Starter_Refill_gne__c;                       
                    }                  
                    
                }
                
                //AS: TARCEVA : 05/19/2012
                // stamping fields for TARCEVAdegib
                if(ship.Product_gne__c == Tarceva_product_name)
                {
                    MH = MHFields.get(CaseId).medical_history_gne__r;
                    if(CasRec.recordtype.name =='GATCF - Standard Case')
                    {
                        ship.SMN_Expiration_Date_gne__c = MH.GATCF_SMN_Expiration_Date_gne__c;
                        ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                        ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                        ship.Dosage_TARCEVA_gne__c = MH.BRAF_Dosage_gne__c;
                        ship.Dispense_Other_BRAF_RxData_gne__c=MH.Dispense_Other_BRAF_gne__c;
                        ship.Dispense_gne__c=MH.Dispense_gne__c;
                        ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Frequency_of_Administration_BRAF_gne__c;
                        ship.Other_GATCF_BRAF_gne__c = MH.Dosage_Other_BRAF_gne__c;
                        ship.Refill_s_BRAF_gne__c = MH.Refill_s_BRAF_gne__c; 
                    }
                    else if(CasRec.recordtype.name =='C&R - Standard Case')
                    {
                        ship.SMN_Effective_Date_gne__c = MH.Starter_SMN_Effective_Date_gne__c;
                        ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                        ship.SMN_Expiration_Date_gne__c = MH.Starter_SMN_Expiration_Date_gne__c;
                        ship.Rx_Expiration_gne__c=MH.Starter_Rx_Expiration_Date_gne__c;
                        ship.Dosage_TARCEVA_gne__c = MH.Starter_Dosage_gne__c;
                        ship.Dispense_gne__c=MH.Starter_Dispense_gne__c;
                        ship.Freq_of_Administration_BRAF_Rx_Data_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                        ship.Starter_Other_BRAF_gne__c = MH.Starter_Other_gne__c;
                        ship.Refill_s_BRAF_gne__c = MH.Starter_Refill_gne__c;
                    }                  
                    
                }
                
            }
                        /**** Changes as per Go-Live Issue -SD***/   
                        if( trigger.isInsert || trigger.isupdate)
                        {
                            if(ship.Case_Shipment_gne__c!=null) 
                            CaseId=ship.Case_Shipment_gne__c;
                            else if(ship.Case_Shipment_Request_gne__c!=null)
                            CaseId=ship.Case_Shipment_Request_gne__c;

                            if(ship.Product_gne__c=='Pegasys')
                            {
                                //PR : During creation or update the product supply value from medical history is copied over to shipment product supply.  10/19/2011
                                MH=MHFields.get(CaseId).medical_history_gne__r;
                /* Commented By Swetak for Pegasys Shipment issue (CRITICAL)  for PMORG reqt# 00002926
                                if(MH.Product_Supply_Type_gne__c != null)
                                ship.Product_Supply_Type_gne__c = MH.Product_Supply_Type_gne__c;
                Comment End */
               	 /*
                	PKambalapally PFS-1074.2/20/2014 Need to update these fields on shipment everytime MH is updated:
                		Product_Supply_Type_gne__c,NDC_Product_Vial_1_gne__c,Product_Vial_P1_gne__c,NDC_Product_Vial_3_gne__c,Product_Vial_P3_gne__c
	            	but only if the shipment isn't released yet.
	            	 */
	            	 System.debug('status===='+ship.status_gne__c);
	            	 System.debug('MH in pegasys===='+MH);
                     //PK PFS-1074. 3/5/2014. Added logic to run this block even when the shipment is being released
	            	if(!GNE_CM_Shipment_rx_Data_Calc_Stamp.mhHasUpdatedShipment 
                        && (ship.Status_gne__c =='OH - On Hold' 
                            ||(Trigger.oldMap.get(ship.id).Status_gne__c =='OH - On Hold' 
                                && ship.Status_gne__c =='RE - Released')
                            )
                        ){
	            		
	            		ship.Product_Supply_Type_gne__c = MH.Product_Supply_Type_gne__c;
	            		
	            		Map<string,Product_vod__c> Pegasys_ndc_data = new Map<string,Product_vod__c>();

	            		String Pegasys_Line_Indication;
	            		Map<String,String> Pegasysactualval = new Map<String,String>();
	            		
	            		
			            /*
			            for(integer j = 0;j< environment_var_val.size();j++)
	                    {  
	                        splitVal = environment_var_val[j].Value__c.split(';');
	                        Pegasysactualval.put(Splitval[0],Splitval[1]);
	                    }
			            */
			            List<String> splitVal;
					    String env = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;
					    for(String value : GNE_CM_CustomSettings_Utils.getValues(GNE_CM_Pegasys_SubType_Val__c.getall().values(), env))
						{
							splitVal = value.split(';');
					    	Pegasysactualval.put(Splitval[0],Splitval[1]);
						}
					    /*
					    for(GNE_CM_Pegasys_SubType_Val__c envVar : GNE_CM_Pegasys_SubType_Val__c.getAll().values()){
					       if(envVar.Environment__c == env || envVar.Environment__c.toLowerCase() == 'all'){
					       	   splitVal = envVar.Value__c.split(';');
					    	   Pegasysactualval.put(Splitval[0],Splitval[1]);        	
					       }
					    }		
					    */
			             System.debug('Pegasysactualval0======='+Pegasysactualval);
			             System.debug('productVialInfo===='+productVialInfo);
			             
	            		 if(Pegasysactualval.containskey(ship.Product_Supply_Type_gne__c))
                        {
                            
                            Pegasys_Line_Indication = Pegasysactualval.get(ship.Product_Supply_Type_gne__c) ;
                            
                        }
                        
	            		for (integer i=0; i < productVialInfo.size(); i++) 
			            {
			                if(productVialInfo[i].Parent_Product_vod__r.Name=='Pegasys')
			                {
			                    Pegasys_ndc_data.put(productVialInfo[i].Name, productVialInfo[i]);
			                }
			            }
	            		System.debug('Pegasys_ndc_data====='+Pegasys_ndc_data);
	            		System.debug('Pegasys_Line_Indication====='+Pegasys_Line_Indication);
	            		System.debug('Product_Supply_Type_gne__c====='+ship.Product_Supply_Type_gne__c);
	            		if(Pegasys_ndc_data.containsKey(Pegasys_Line_Indication)){
	            			ship.NDC_Product_Vial_1_gne__c = Pegasys_ndc_data.get(Pegasys_Line_Indication).NDC_Number_gne__c;
	                        ship.Product_Vial_P1_gne__c = Pegasys_ndc_data.get(Pegasys_Line_Indication).Name;
	                        
	                        ship.NDC_Product_Vial_3_gne__c = Pegasys_ndc_data.get('Copegus - 200 mg').NDC_Number_gne__c;
	                        ship.Product_Vial_P3_gne__c = Pegasys_ndc_data.get('Copegus - 200 mg').Name;	
	            		}else{
                             ship.NDC_Product_Vial_1_gne__c = '';
                             ship.Product_Vial_P1_gne__c = '';
                             ship.NDC_Product_Vial_3_gne__c = '';
                             ship.Product_Vial_P3_gne__c = '';
                        }//end check on  Pegasys_ndc_data
	            		
                        
                        System.debug('ship values set in trigger----'+ship.NDC_Product_Vial_1_gne__c+'----Product_Vial_P1_gne__c-----'+ship.Product_Vial_P1_gne__c);
                        System.debug('----NDC_Product_Vial_3_gne__c----'+ship.NDC_Product_Vial_3_gne__c+'----Product_Vial_P3_gne__c----'+ship.Product_Vial_P3_gne__c);
	            	}//end check for shipment status
                	/*
                		end PKambalapally PFS-1074.2/20/2014
                	*/ 
               
                                if(MH.Dose_mg_kg_wk_gne__c!= null)
                                dosage_0_5_ml = MH.Dose_mg_kg_wk_gne__c;
                                if(MH.Dose_mg_kg_wk_Pegasys_1ml_gne__c!= null)
                                dosage_1ml=MH.Dose_mg_kg_wk_Pegasys_1ml_gne__c;
                                if(MH.CM_200mg_Total_Tablets_gne__c != null)
                                dosage_copegus=MH.CM_200mg_Total_Tablets_gne__c;
                                dispense_copegus = MH.Dispense_Copegus_gne__c;
                                if(MH.product_supply_type_gne__c == system.label.GNE_CM_Pegays_line_Indication)
                                {
                                if(dosage_0_5_ml>0&&dosage_0_5_ml<=135) dosage_0_5_ml=1;
                                else if(dosage_0_5_ml>135&&dosage_0_5_ml<=270) dosage_0_5_ml=2;
                                else if(dosage_0_5_ml>270) dosage_0_5_ml=3;
                                }
                                else if(MH.product_supply_type_gne__c == system.label.GNE_CM_Pegays_180_mcg_1ml)
                                {
                               if(dosage_0_5_ml>0&&dosage_0_5_ml<=180) dosage_0_5_ml=4;
                               else if(dosage_0_5_ml>180&&dosage_0_5_ml<=360) dosage_0_5_ml=8;
                               else if(dosage_0_5_ml>360) dosage_0_5_ml=12;
                                }
                                else
                                {
                                if(dosage_0_5_ml>0&&dosage_0_5_ml<=180) dosage_0_5_ml=1;
                                else if(dosage_0_5_ml>180&&dosage_0_5_ml<=360) dosage_0_5_ml=2;
                                else if(dosage_0_5_ml>360) dosage_0_5_ml=3;
                                }
                                if(ship.Dispense_Pegasys_Prefill_ship_gne__c==null||ship.Dispense_Pegasys_Prefill_ship_gne__c=='')
                                ship.Quantity_1_gne__c=0;  
                                else 
                                ship.Quantity_1_gne__c=dosage_0_5_ml*Double.valueOf(ship.Dispense_Pegasys_Prefill_ship_gne__c.subString(0, 1));    
                                if(dosage_1ml>0&&dosage_1ml<=180) dosage_1ml=4;
                                else if(dosage_1ml>180&&dosage_1ml<=360) dosage_1ml=8;
                                else if(dosage_1ml>360) dosage_1ml=12; 
                                if(ship.Dispense_Pegasys_1ml_ship_gne__c==null||ship.Dispense_Pegasys_1ml_ship_gne__c=='')
                                ship.Quantity_2_gne__c=0;
                                else
                                ship.Quantity_2_gne__c=dosage_1ml*Double.valueOf(ship.Dispense_Pegasys_1ml_ship_gne__c.subString(0, 1)); 
                                if(ship.Dispense_Copegus_ship_gne__c ==null || ship.Dispense_Copegus_ship_gne__c =='' || dispense_copegus == null || dispense_copegus == '')
                                ship.Quantity_3_gne__c=0;
                                else 
                                ship.Quantity_3_gne__c=(dosage_copegus*Double.valueOf(ship.Dispense_Copegus_ship_gne__c.subString(0, 1))* 28)/(Double.valueOf(dispense_copegus.substring(0,1)) * 28);    
                                
                            }
                            //AS Changes : PFS-747
                            if(ship.Product_gne__c=='Actemra Subcutaneous' && ship.Case_Type_gne__c == 'C&R - Standard Case')//&& ship.Action_gne__c == 'Starter Prescription'
                            {
                            	MH = MHFields.get(CaseId).medical_history_gne__r;
                            	if(shipmentCountActemra >= 12 && !currentProfileName.contains('GNE-CM-CRSUPERVISOR'))
                            	{
                            		ship.adderror('Only CR Supervisor can create more than 12 shipments.');
                            	}
                            }   

                        }// end of if( trigger.isInsert || trigger.isupdate)  
                    }// End of if Sent to ESB ==false            
                }
                catch(exception e)
                { ship.adderror('Unexpected Error occured while creating Shipment record' + e.getMessage());} // End of catch
            } // end of for



            //Rama - Zelboraf NDC code selection based on Dispense logic - Defect 1147
            String ndc1Zelboraf = null;
            String ndc2Zelboraf = null;
            List<Product_vod__c> zelborafNDCCodes = new List<Product_vod__c>();
            for(Product_vod__c vialInfo : productVialInfo) {
                if(vialInfo.Parent_Product_vod__r.Name.contains(braf_product_name)) {
                    zelborafNDCCodes.add(vialInfo);
                }
            }

            if(zelborafNDCCodes != null && zelborafNDCCodes.size() > 0) {
                for(Product_vod__c ndcCode : zelborafNDCCodes) {
                    if(ndcCode.Name == braf_product_name) {
                        ndc1Zelboraf = ndcCode.NDC_Number_gne__c; //Zelboraf
                    } else {
                        ndc2Zelboraf = ndcCode.NDC_Number_gne__c; //Zelboraf 28 (New NDC Code)
                    }
                }

                for(Shipment_gne__c ship :Trigger.new)
                {  
                    if( trigger.isInsert || trigger.isupdate)
                    {
                        if(ship.Product_gne__c==braf_product_name )
                        { 
                            String dispense_braf_val = null;
                            if(ship.case_type_gne__c == 'GATCF - Standard Case') {
                                dispense_braf_val = ship.Dispense_BRAF_gne__c;
                            }
                            else if(ship.case_type_gne__c == 'C&R - Standard Case') {
                                dispense_braf_val = ship.Dispense_CR_BRAF_gne__c;
                            }

                            if(dispense_braf_val != null) {
                                if(dispense_braf_val == '15' || dispense_braf_val == '30' || dispense_braf_val == '45' || dispense_braf_val == '60' || dispense_braf_val == '75' || dispense_braf_val == '90' || dispense_braf_val == 'Other')
                                {
                                   if(ndc1Zelboraf != null) {
                                       ship.Product_Vial_P1_gne__c=braf_product_name;
                                       ship.NDC_Product_Vial_1_gne__c=ndc1Zelboraf;
                                   }
                                } else {
                                   if(ndc2Zelboraf != null) {
                                       ship.Product_Vial_P1_gne__c=braf_product_name;
                                       ship.NDC_Product_Vial_1_gne__c=ndc2Zelboraf;
                                   }
                                }
                            }

                            System.debug('this.ship.NDC_Product_Vial_1_gne__c@@@: ' + ship.NDC_Product_Vial_1_gne__c);
                       }
                   }
                }
            }
            if (trigger.isupdate)
			{
	            for(Shipment_gne__c ship :Trigger.new)
	            {
	            	if (ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c != Trigger.oldMap.get(ship.ID).Prescription_Type_gne__c)
	            	{
		            	CaseId=ship.Case_Shipment_gne__c;
		            	if (CaseId !=null && Case_map.isEmpty())
		            	{
		                    caseidset.add(CaseId);
		                    if(!GNE_CM_Shipment_Parent_Class.case_map_flag)
		                    {
		                        GNE_CM_Shipment_Parent_Class.setcasemap(caseidset);
		                        Case_map = GNE_CM_Shipment_Parent_Class.getcasemap();
		                    }
		                    else 
		                    {
		                    	Case_map = GNE_CM_Shipment_Parent_Class.getcasemap();
		                    }
		                    	
		                    if(!GNE_CM_Shipment_Parent_Class.shipment_related_flag)
			                {
			                    GNE_CM_Shipment_Parent_Class.setshipment_related_info(caseidset);
			                    MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();
			                }
			                else 
			                {
			                	MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();
			                }
		            	}
	                    if (CaseId !=null && Case_map.containsKey(CaseId))
	                    {
	                    	CasRec=case_map.get(CaseId);
	                    	
	                    	if (ship.Product_gne__c == boomerang_product_name && CasRec.recordtype.name =='GATCF - Standard Case') 
			            	{
			            		MH = MHFields.get(CaseId).medical_history_gne__r;	           
			            		         
			                    if (ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Initial Titration' ) 
			                    {
			                    	ship.Dispense_gne__c=MH.Dispense_gne__c;
			                    	ship.Dispense_Other_BRAF_RxData_gne__c= MH.Dispense_Other_BRAF_gne__c;                                      
			                    	ship.Total_Tablets_Dispensed_BRAF_gne__c=MH.Total_267_mg_Tabletsf__c;  
			                    }
			                    else if(ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Maintenance')
			                    {
			                    	ship.Dispense_gne__c=MH.Dispense_Maintenance__c;
			                    	ship.Dispense_Other_BRAF_RxData_gne__c= MH.Dispense_Other_maintenance__c;                                      
			                    	ship.Total_Tablets_Dispensed_BRAF_gne__c=MH.Total_267_mg_Tablets_maint__c;  
			                    }  
			            	}
	                    }
	            	}
				}
            }
        } // end of global try
        catch(exception e)
        {
            for (Shipment_gne__c Ship: Trigger.new)
            {Ship.adderror('Processing for the Shipment record stopped! Unexpected Error in getting the Shipment related information from other objects: ' + e.getMessage());}
        }
        finally
        {    //caseidset.clear();
            //Case_map.clear();         
        } 
    }   //end of triggerIsInProcess   
}