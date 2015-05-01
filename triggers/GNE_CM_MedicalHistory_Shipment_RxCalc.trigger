trigger GNE_CM_MedicalHistory_Shipment_RxCalc on Shipment_gne__c (before insert, before update) {

    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
        return;
    }
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    Map<String, Case> MHFields=new Map<String, Case>();
    Set<Id> caseidset=new set<Id>(); Set<string> product=new Set<string>();
     List<Product_vod__c> AllProductDetails = new List<Product_vod__c>();
    List<Product_vod__c> ProdDetails = new List<Product_vod__c>();Id CaseId;
    Map<Id, Case> Case_map;
    double[] InjWeekVal=new double[]{7.0, 3.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 2.0, 14.0};
    string[] InjWeekMH=new string[]{'QD', 'QOD', 'Once a Week','2/W','3/W','4/W','5/W','6/W','TIW','BID'};
    string[] Dispense=new string[]{'30 Days', '60 Days', '90 Days'};
    integer[] DispenseDouble=new integer[]{30, 60, 90};
    string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
    string vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    string Pertuzumab_Product_Name = system.label.GNE_CM_Pertuzumab_Product_Name;
    string TDM1_Product_Name = system.label.GNE_CM_TDM1_Product_Name;
    String cobi_product_name = system.label.GNE_CM_Cotellic_Product_Name;
    String boomerang_product_name = system.label.GNE_CM_Boomerang_Product_Name;
    
    Medical_History_gne__c MH=new Medical_History_gne__c();
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig3())
    {  GNE_CM_case_trigger_monitor.setTriggerInProcessTrig3();
        for(Shipment_gne__c ship :Trigger.new)
        {  try
            { if(ship.Sent_to_ESB_gne__c==false)
              { if(ship.Case_Shipment_gne__c!=null)CaseId=ship.Case_Shipment_gne__c;
                 else if(ship.Case_Shipment_Request_gne__c!=null)CaseId=ship.Case_Shipment_Request_gne__c;         
                 if (CaseId!=null)
                 caseidset.add(CaseId);
                  if (ship.Product_gne__c!=null) product.add(ship.Product_gne__c);
              }
             }
             catch(exception e){ship.adderror('Unexpected error has occured:' + e.getmessage());}
        }
        try
        {
            if(!GNE_CM_Shipment_Parent_Class.shipment_related_flag)
            {
                GNE_CM_Shipment_Parent_Class.setshipment_related_info(caseidset);
                MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();
            }
            else
            MHFields = GNE_CM_Shipment_Parent_Class.getshipment_related_info();
            
            system.debug('CHECK MH2'+MHFields);
            if(!GNE_CM_Shipment_Parent_Class.prodvialinfo_flag)
             {
                GNE_CM_Shipment_Parent_Class.setproductvialinfo();
                AllProductDetails = GNE_CM_Shipment_Parent_Class.getproductvialinfo();
             }
             else
             AllProductDetails = GNE_CM_Shipment_Parent_Class.getproductvialinfo();
            for(integer prod=0; prod<AllProductDetails.size(); prod++)
            {
                if( AllProductDetails[prod].Parent_Product_vod__r.Name == 'Raptiva' || AllProductDetails[prod].Parent_Product_vod__r.Name == 'Nutropin' || AllProductDetails[prod].Parent_Product_vod__r.Name == 'Xolair')
                ProdDetails.add(AllProductDetails[prod]);
            }
          }
        catch(exception e) {
             for (integer i=0;i < trigger.new.size();i++)
                if (MHFields.containsKey('Error'))
                    trigger.new[i].adderror('Unexpected error has occured while updating Prescription data from Medical history' + MHFields.get('Error').Id);
         }
      for (Shipment_gne__c ship: Trigger.new)
       {
        try
         {
          if(ship.Sent_to_ESB_gne__c==false)
           { double InjWeek=0.0;double UsefulDays=0.0;double VialPerCarton=0.0;double WAPPrice=0.0;
            Double listPrice=0.0;
            double VialSize;double MgPerDay, DayPerVial;double VailQuotient=0.0;double remainder=0.0;
            if(ship.Case_Shipment_gne__c!=null) CaseId=ship.Case_Shipment_gne__c;
            else if(ship.Case_Shipment_Request_gne__c!=null)CaseId=ship.Case_Shipment_Request_gne__c;
            
            if (trigger.isUpdate&&system.trigger.oldmap.get(ship.Id).Status_gne__c!='RE - Released'&&ship.Status_gne__c=='RE - Released'&&ship.Shipped_From_Site_gne__c!=null&&ship.Shipped_From_Site_gne__c.equalsIgnoreCase('RxCrossroads')&&ship.Case_Shipment_Request_gne__c==null)
            {  
                /*if( (ship.Product_gne__c!='Avastin'&& ship.Product_gne__c!='Tarceva'&& ship.Product_gne__c!='Activase'&& ship.Product_gne__c!='TNKase' && ship.Product_gne__c!=braf_product_name && ship.Rx_Date_gne__c==null && ship.Product_gne__c!=vismo_product_name) // && ship.Product_gne__c!= pertuzumab_product_name)
                   ||(ship.Product_gne__c=='Tarceva'&&MHFields.get(ship.Case_Shipment_gne__c).medical_history_gne__r.Rx_Date_gne__c==null) || ((ship.product_gne__c == braf_product_name || ship.Product_gne__c== vismo_product_name) && ship.case_type_gne__c == 'GATCF - Standard Case' && ship.Rx_Date_gne__c==null))
                   ship.adderror('RxCrossroad Shipments cannot be Released when Rx Date/Rx Effective Date on associated Medical Histroy is null.');*/

                   if((ship.Product_gne__c != 'Actemra Subcutaneous' && ship.Product_gne__c!='Avastin'&& ship.Product_gne__c!='Tarceva'&& ship.Product_gne__c!='Activase'&& ship.Product_gne__c!='TNKase' && ship.Product_gne__c!=braf_product_name && ship.Product_gne__c!=cobi_product_name && ship.Product_gne__c != boomerang_product_name && ship.Rx_Date_gne__c==null && ship.Product_gne__c!=vismo_product_name)
                    ||(ship.Product_gne__c=='Tarceva'&&MHFields.get(ship.Case_Shipment_gne__c).medical_history_gne__r.Rx_Date_gne__c==null && ship.case_type_gne__c == 'GATCF - Standard Case') 
                    ||(ship.Product_gne__c=='Actemra Subcutaneous'&&MHFields.get(ship.Case_Shipment_gne__c).medical_history_gne__r.Rx_Date_gne__c==null && ship.case_type_gne__c == 'GATCF - Standard Case') 
                    ||((ship.product_gne__c == braf_product_name || ship.Product_gne__c== vismo_product_name || ship.product_gne__c == cobi_product_name || ship.product_gne__c == boomerang_product_name) && ship.case_type_gne__c == 'GATCF - Standard Case' && ship.Rx_Date_gne__c==null))
                    ship.adderror('RxCrossroad Shipments cannot be Released when Rx Date/Rx Effective Date on associated Medical History is null.');
                    //Kishore added this for tarceva starter shipments on 6/20/12
                    if (((ship.product_gne__c =='Tarceva') && ship.case_type_gne__c == 'C&R - Standard Case' && ship.starter_begin_date_gne__c==null) ||
                        (ship.Product_gne__c=='Actemra Subcutaneous'&&MHFields.get(ship.Case_Shipment_gne__c).medical_history_gne__r.Starter_Rx_Date_gne__c==null && ship.case_type_gne__c == 'C&R - Standard Case'))
                        ship.adderror('RxCrossroad Shipments cannot be Released when Starter Rx Date on associated Medical History is null.');
            }
            if((MHFields.containsKey(CaseId)&&MHFields.get(CaseId).Diagnosis_gne__c!=null&&MHFields.get(CaseId).Diagnosis_gne__c!=''))
            {   string Icd9_Code=MHFields.get(CaseId).Diagnosis_gne__c;
                integer index=Icd9_Code.indexOf('-');
                if (index==-1)index=Icd9_Code.indexOf(' ');
                if(index!=-1)ship.ICD9_Code_1_gne__c=Icd9_Code.Substring(0, index);
            }
            for(integer i=0;i< ProdDetails.size();i++)
            {  if (ship.Product_gne__c==ProdDetails[i].Parent_Product_vod__r.name&&ProdDetails[i].NDC_Number_gne__c==ship.NDC_Product_Vial_1_gne__c)
                {   if (ProdDetails[i].Vial_Size_gne__c!=null) VialSize=ProdDetails[i].Vial_Size_gne__c;
                    if (ProdDetails[i].Vial_Per_Carton_pd_gne__c!=null) VialPerCarton=ProdDetails[i].Vial_Per_Carton_pd_gne__c;
                    if (ProdDetails[i].Useful_Days_gne__c!=null) UsefulDays=Double.valueOf(ProdDetails[i].Useful_Days_gne__c);
                    if (ProdDetails[i].Wholesale_Acquisition_Price_gne__c!=null) WAPPrice=ProdDetails[i].Wholesale_Acquisition_Price_gne__c;
                    if (ProdDetails[i].List_Price_gne__c!=null) listPrice=ProdDetails[i].List_Price_gne__c;
                    
              }
          }
            Date Saturday_date=null;
            system.debug('Ship.Expected_Ship_Date_gne__c-------->'+Ship.Expected_Ship_Date_gne__c+'---------->Ship.Carrier_Code_gne__c'+Ship.Carrier_Code_gne__c);
            if(Ship.Expected_Ship_Date_gne__c!=null&&Ship.Carrier_Code_gne__c !=null&&ship.Case_Shipment_Request_gne__c==null)
            {   
                
                if(Ship.Carrier_Code_gne__c=='F01 - FedEx Priority Overnight'||Ship.Carrier_Code_gne__c=='F03 - FedEx Standard Overnight'||Ship.Carrier_Code_gne__c=='UPS01 - UPS Priority Overnight'||Ship.Carrier_Code_gne__c=='UPS02 - UPS Standard Overnight'||Ship.Carrier_Code_gne__c=='UPS03 - UPS Economy Service' )
                    ship.Expected_Delivery_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(1);
                if(Ship.Carrier_Code_gne__c=='F05 - FedEx Economy Service'||Ship.Carrier_Code_gne__c=='UPS06 - UPS Second Day Delivery'||Ship.Carrier_Code_gne__c=='F05 - FedEx 2 Day')
                    ship.Expected_Delivery_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(2);
                if(Ship.Carrier_Code_gne__c=='F06 - FedEx Saturday Delivery'||Ship.Carrier_Code_gne__c=='UPS04 - UPS Saturday Delivery' )
                {   Saturday_date=Ship.Expected_Ship_Date_gne__c.tostartofweek();
                    if(Saturday_date.daysbetween(Ship.Expected_Ship_Date_gne__c)==6)
                        ship.Expected_Delivery_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(7);
                    for(integer k=0;k<=5;k++)
                    { if(Saturday_date.daysbetween(Ship.Expected_Ship_Date_gne__c)==k) ship.Expected_Delivery_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(6-k);}                       
                 }
               if (ship.Expected_Delivery_Date_gne__c!=null)
                    {   Saturday_date=ship.Expected_Delivery_Date_gne__c.tostartofweek();
                        if (Saturday_date.daysbetween(ship.Expected_Delivery_Date_gne__c)==6)
                         {ship.Saturday_Shipment_gne__c='Yes';ship.Carrier_Code_gne__c='UPS04 - UPS Saturday Delivery';}
                        else if(Saturday_date.daysbetween(ship.Expected_Delivery_Date_gne__c)==0)ship.Saturday_Shipment_gne__c='Yes';
                    }
            }
            if (ship.Product_gne__c=='Actemra')
            {   if(Ship.Expected_Delivery_Date_gne__c!=null&&Ship.Action_gne__c!='GATCF Replacement')
                    Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(28);
                else 
                    Ship.Exhaust_Date_gne__c=null;
            }
// DSO change 10/28/2013 Start            
            if (ship.Product_gne__c=='Actemra Subcutaneous')
            {   if(Ship.Expected_Ship_Date_gne__c!=null&&Ship.Action_gne__c!='GATCF Replacement'){
                    if (Ship.Action_gne__c == 'GATCF Upfront'){
                        if (Ship.Dispense_Copegus_gne__c == '1 Month') 
                            Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.addDays(1 * 28);
                        else if (Ship.Dispense_Copegus_gne__c == '2 Month') 
                            Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.addDays(2 * 28);
                        else if (Ship.Dispense_Copegus_gne__c == '3 Month') 
                            Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.addDays(3 * 28);  
                        else // When user choose Other in Dispense and put in a number in Other field
                        {  
                            if(Ship.Dispense_Other_BRAF_RxData_gne__c != null)
                            Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.addDays(Integer.Valueof(Ship.Dispense_Other_BRAF_RxData_gne__c) * 28);
                        }            
                    }
                    else
                        Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(28);
                }
                else Ship.Exhaust_Date_gne__c=null;
            }
// DSO change 10/28/2013 End            
            if (ship.Product_gne__c==braf_product_name)
            {   if(Ship.Expected_Delivery_Date_gne__c!=null)
                {  
                  if(ship.Dispense_BRAF_gne__c !=null && ship.case_type_gne__c == 'GATCF - Standard Case')
                  { 
                     if(ship.Dispense_BRAF_gne__c != 'Other')   
                     Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseBRAF(ship.Dispense_BRAF_gne__c)));
                     else if(ship.Dispense_Other_BRAF_gne__c != null)
                     Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(ship.Dispense_Other_BRAF_gne__c));                
                  }
                  else if(ship.case_type_gne__c == 'C&R - Standard Case' && ship.Dispense_CR_BRAF_gne__c != null)
                  Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseBRAF(ship.Dispense_CR_BRAF_gne__c)));
                  else
                  Ship.Exhaust_Date_gne__c=null;
                }
                else Ship.Exhaust_Date_gne__c=null;
            }
            else if (ship.Product_gne__c == cobi_product_name)
            {   
            	Ship.Exhaust_Date_gne__c = null;
            	if(Ship.Expected_Delivery_Date_gne__c != null)
                {  
                  if(ship.Dispense_COBI_gne__c !=null && ship.case_type_gne__c == 'GATCF - Standard Case')
                  { 
                    if(ship.Dispense_COBI_gne__c != 'Other')   
			      	{   
			         	ship.Exhaust_Date_gne__c = ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseBRAF(ship.Dispense_COBI_gne__c)));
			      	}
			      	else if(ship.Dispense_Other_Cotellic_Days__c != null)
			      	{
			   			ship.Exhaust_Date_gne__c = ship.Expected_Delivery_Date_gne__c.adddays(Integer.valueof(ship.Dispense_Other_Cotellic_Days__c));	
			      	} 
                  }
                  else if(ship.case_type_gne__c == 'C&R - Standard Case' && ship.Dispense_CR_COBI_gne__c != null)
	              {
	              	ship.Exhaust_Date_gne__c = ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseBRAF(ship.Dispense_CR_COBI_gne__c)));
	              }
                }
            }
            else if(ship.Product_gne__c == boomerang_product_name) 
            {
            	System.debug('+++++++++++ ship.ID: ' + ship.ID +  ' ship.Exhaust_Date_gne__c: ' + ship.Exhaust_Date_gne__c);
            	Ship.Exhaust_Date_gne__c = null;
            	if(Ship.Expected_Delivery_Date_gne__c != null)
                {  
					if(ship.Dispense_Boomerang_gne__c !=null && ship.case_type_gne__c == 'GATCF - Standard Case')
					{ 
						Integer dispenseDays = 0;
				      	if (ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Initial Titration' ) 
						{
							if (ship.Dispense_Boomerang_gne__c == 'Other' && ship.Dispense_Other_BRAF_gne__c != null)
							{
								dispenseDays = Integer.valueOf(ship.Dispense_Other_BRAF_gne__c);
							}
							else
							{
								dispenseDays = Integer.valueOf(ship.Dispense_Boomerang_gne__c);
							}
						}
						else if(ship.Prescription_Type_gne__c != null && ship.Prescription_Type_gne__c == 'Maintenance')
						{
							if (ship.Dispense_Boomerang_Maintenance_gne__c == 'Other' && ship.Dispense_Other_Maintenance_gne__c != null)
							{
								dispenseDays = Integer.valueOf(ship.Dispense_Other_Maintenance_gne__c);
							}
							else
							{
								dispenseDays = Integer.valueOf(ship.Dispense_Boomerang_Maintenance_gne__c);
							}
						}
                		ship.Exhaust_Date_gne__c = ship.Expected_Delivery_Date_gne__c.adddays(dispenseDays);	
                  	}
	                else if(ship.case_type_gne__c == 'C&R - Standard Case' && ship.Dispense_CR_Boomerang_gne__c != null)
	                {
	                  	ship.Exhaust_Date_gne__c = ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseBRAF(ship.Dispense_CR_Boomerang_gne__c)));
	                }
                }
                System.debug('+++++++++++ ship.ID: ' + ship.ID +  ' ship.Exhaust_Date_gne__c: ' + ship.Exhaust_Date_gne__c);
            }
            else if(ship.Product_gne__c == vismo_product_name)
            {
                if(Ship.Expected_Delivery_Date_gne__c!=null)
                {  
                  if(ship.Dispense_VISMO_gne__c !=null && ship.case_type_gne__c == 'GATCF - Standard Case')
                  { 
                     if(ship.Dispense_VISMO_gne__c != 'Other')   
                     //Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(ship.Dispense_VISMO_gne__c)); //PS: 08/21/2012 Commented
                     Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseErivedge(ship.Dispense_VISMO_gne__c))); //PS: 08/21/2012 Added  
                     else if(ship.Dispense_Other_BRAF_gne__c != null)
                     Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(ship.Dispense_Other_BRAF_gne__c));                
                  }
                  else if(ship.case_type_gne__c == 'C&R - Standard Case' && ship.Dispense_CR_VISMO_gne__c != null)
                  //Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(ship.Dispense_CR_VISMO_gne__c)); //PS: 08/21/2012 Commented
                  Ship.Exhaust_Date_gne__c=Ship.Expected_Delivery_Date_gne__c.adddays(integer.valueof(GNE_CM_MPS_Utils.getDispenseErivedge(ship.Dispense_CR_VISMO_gne__c))); //PS: 08/21/2012 Added  
                  else
                  Ship.Exhaust_Date_gne__c=null;
                }
                else Ship.Exhaust_Date_gne__c=null;
            }
            
            if ((ship.Product_gne__c=='Tarceva')||(ship.Product_gne__c=='Raptiva'))
            {   if((Ship.Days_Supply_Authorized_gne__c!=null)&&(Ship.Days_Supply_Authorized_gne__c!=''))
                {   Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Integer.valueof(Ship.Days_Supply_Authorized_gne__c));
                    Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Integer.valueof(Ship.Days_Supply_Authorized_gne__c) - 10);
                }
            }
            if (ship.Product_gne__c=='Lucentis')  
            { ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(28);ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(18);}   
            
            //KS: Pertuzumab Condition
            if (ship.Product_gne__c == Pertuzumab_Product_Name || ship.Product_gne__c == TDM1_Product_Name)  
            { 
                ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(28);
                ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(18);
            }  
            //KS: Pertuzumab Condition ends here
            
            if (ship.Product_gne__c!='Herceptin')
                MH=MHFields.get(CaseId).medical_history_gne__r;
            if (ship.Product_gne__c=='Nutropin'&&ship.Case_Shipment_Request_gne__c==null)
            {   if(trigger.isInsert){ship.Product_Vial_P1_gne__c=MH.Drug_gne__c;
                    ship.Drug_gne__c=MH.Drug_gne__c;ship.Dose_mg_kg_wk_gne__c=MH.Dose_mg_kg_wk_gne__c;
                    ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                    ship.Number_Syringes_Dispense_gne__c=MH.Number_Syringes_Dispense_gne__c;ship.With_Needles_gne__c=MH.With_Needles_gne__c;
                    ship.Dispense_Reconstitution_Syringes_gne__c=MH.Dispense_Reconstitution_Syringes_gne__c;
                    ship.Needle_Size_gne__c=MH.Needle_Size_gne__c;ship.Sig_Mg_SubQ_gne__c=MH.Sig_Mg_SubQ_gne__c;
                    ship.Dilute_with_ml_gne__c=MH.Dilute_with_ml_gne__c;ship.Dose_per_Inj_ml_gne__c=MH.Dose_per_Inj_ml_gne__c;
                    ship.Injs_per_week_gne__c=MH.Injs_per_week_gne__c;ship.Dispense_Months_gne__c=MH.Dispense_Months_gne__c;
                    ship.RefillX_PRN_gne__c=MH.RefillX_PRN_gne__c;ship.Injection_Device_gne__c=MH.Injection_Device_gne__c;
                    ship.Patient_Weight_kg_gne__c=MH.Patient_Weight_kg_gne__c;
                }
                if(ship.Status_gne__c=='OH - On Hold')
               {
                    for(integer i=0;i<InjWeekMH.size();i++)
                    {   if (ship.Injs_per_week_gne__c==InjWeekMH[i]) InjWeek=InjWeekVal[i];
                    }
                    Ship.Mg_Injection_gne__c=null;Ship.Mg_Needed_gne__c=null;Ship.Mg_Received_gne__c=null;
                    ship.Total_Shipment_Cost_Wholesale_Price_gne__c=null;Ship.Exhaust_Date_gne__c=null;Ship.Reorder_Date_gne__c=null;
                    if (Ship.Sig_Mg_SubQ_gne__c>0) Ship.Mg_Injection_gne__c=Ship.Sig_Mg_SubQ_gne__c;
                    else
                    {   if ((Ship.Dose_mg_kg_wk_gne__c!=null)&&(Ship.Dose_mg_kg_wk_gne__c!=0)&&(Ship.Injs_per_week_gne__c!=null)&&(ship.Patient_Weight_kg_gne__c!=null))
                        {   if (InjWeek!=0.0) Ship.Mg_Injection_gne__c=(Ship.Dose_mg_kg_wk_gne__c * ship.Patient_Weight_kg_gne__c)/InjWeek;
                        }
                        else
                        {   if ((Ship.Dose_per_Inj_ml_gne__c!=0)&&(Ship.Dose_per_Inj_ml_gne__c!=null)&& (Ship.Dilute_with_ml_gne__c!=null)&&(Ship.Dilute_with_ml_gne__c!=0)&&(VialSize!=null)&&(VialSize!=0)&&(Ship.Mg_Injection_gne__c==null||Ship.Mg_Injection_gne__c<=0))
                                Ship.Mg_Injection_gne__c=(VialSize * Ship.Dose_per_Inj_ml_gne__c)/Ship.Dilute_with_ml_gne__c;}
                    }
                    if(Ship.Mg_Injection_gne__c!=null&&Ship.Mg_Injection_gne__c.format().contains('.'))
                    { string Tempval=String.ValueOf(Ship.Mg_Injection_gne__c);integer DecVal=Tempval.indexOf('.');integer Len=Tempval.length();
                        if(Tempval.substring(DecVal, Len).length()>3) Tempval=Tempval.substring(0,DecVal + 4);
                        Ship.Mg_Injection_gne__c=Double.ValueOf(Tempval);
                    }
                     if ((Ship.Days_Supply_Authorized_gne__c!=null )&&(InjWeek!=0.0)&&(Ship.Mg_Injection_gne__c !=null))
                            Ship.Mg_Needed_gne__c=(Double.valueof(Ship.Days_Supply_Authorized_gne__c) * InjWeek * Ship.Mg_Injection_gne__c)/7;
                     Ship.of_Vials_Needed_gne__c=null;
                     if ((ship.Mg_Injection_gne__c!=null)&& (Ship.Mg_Needed_gne__c!=null))
                    {       MgPerDay=(InjWeek * Ship.Mg_Injection_gne__c)/7;
                            if ((VialSize!=null)&&(MgPerDay !=0))
                                DayPerVial=Math.roundtoLong(VialSize/MgPerDay);
                            if ((UsefulDays!=0.0&&Ship.Days_Supply_Authorized_gne__c!=null&&Integer.valueof(Ship.Days_Supply_Authorized_gne__c)==UsefulDays.intValue())&&(VialSize!=null)&&(Ship.Mg_Needed_gne__c < VialSize))
                                Ship.of_Vials_Needed_gne__c=1;
                            if (DayPerVial!=null&&(UsefulDays.intValue()>DayPerVial)&&(UsefulDays!=0.0)&& (Ship.Days_Supply_Authorized_gne__c!=null)&&(Ship.of_Vials_Needed_gne__c==null ||Ship.of_Vials_Needed_gne__c <=0))
                                 Ship.of_Vials_Needed_gne__c=1 + math.ceil(Double.valueof(Ship.Days_Supply_Authorized_gne__c)/UsefulDays.intValue());
                            if ((VialSize!=null)&&(VialSize!=0)&&(Ship.Mg_Needed_gne__c!=null))
                        {   VailQuotient=Ship.Mg_Needed_gne__c/VialSize;
                            remainder=VailQuotient - VailQuotient.intValue();
                            if(remainder>0.1)
                              Ship.of_Vials_Needed_gne__c=math.ceil(Ship.Mg_Needed_gne__c/VialSize);
                            else
                               Ship.of_Vials_Needed_gne__c=(Ship.Mg_Needed_gne__c/VialSize).intValue();
                        }
                     }
                   ship.Quantity_1_gne__c=Ship.of_Vials_Needed_gne__c;
                   Ship.of_Cartons_to_Ship_gne__c=null;
                   if ((Ship.of_Vials_Needed_gne__c!=null )&&(VialPerCarton!=null))
                   { VailQuotient=0.0;remainder=0.0;
                     if ( VialPerCarton.intValue()!=0 )
                     { VailQuotient=Ship.of_Vials_Needed_gne__c/(VialPerCarton.intValue());
                          remainder=VailQuotient - VailQuotient.intValue();
                          if(remainder>0.1)Ship.of_Cartons_to_Ship_gne__c=math.ceil(Ship.of_Vials_Needed_gne__c/VialPerCarton.intValue());
                          else Ship.of_Cartons_to_Ship_gne__c=(Ship.of_Vials_Needed_gne__c/VialPerCarton.intValue()).intValue();
                     }
                   }
                     if ((VialSize!=null )&&(VialSize!=0)&&(VialPerCarton!=null)&&(Ship.of_Cartons_to_Ship_gne__c !=null))
                        Ship.Mg_Received_gne__c=VialSize * VialPerCarton.intValue()* Ship.of_Cartons_to_Ship_gne__c;
                     if((ship.Drug_gne__c.startsWith('NuSpin')||ship.Drug_gne__c.startsWith('Nutropin'))&& Ship.Injs_per_week_gne__c!=''&&Ship.Expected_Ship_Date_gne__c !=null&&Ship.Mg_Injection_gne__c !=null&&Ship.Mg_Received_gne__c!=null)
                    {   if(UsefulDays!=0.0&&DayPerVial!=null&&DayPerVial>UsefulDays.intValue())
                         {   if((VialSize!=null)&&(VialSize!=0))
                            {   Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Math.round((UsefulDays*Ship.Mg_Received_gne__c)/VialSize));
                                Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Math.round((UsefulDays*Ship.Mg_Received_gne__c)/VialSize) - 10);                           
                            }
                         }
                        else
                        {   if ((MgPerDay!=null)&&(MgPerDay!=0))
                            {   Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Math.round(Ship.Mg_Received_gne__c/MgPerDay));
                                Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Math.round(Ship.Mg_Received_gne__c/MgPerDay) - 10);
                            }
                         }
                    }
                }
                    if(ship.Shipped_From_Site_gne__c!=null && ship.Shipped_From_Site_gne__c.equalsIgnoreCase('RxCrossroads')&&ship.Actual_Number_of_Vials_Shipped_gne__c!=null)
                       ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.Actual_Number_of_Vials_Shipped_gne__c * WAPPrice;
                    else if(Ship.of_Vials_Needed_gne__c!=null)
                       ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.of_Vials_Needed_gne__c * WAPPrice;
                }
            if (ship.Product_gne__c=='Pulmozyme')
                {
              if(trigger.isInsert)            {
                    ship.Ancillary_gne__c=MH.Ancillary_Supplies_gne__c; ship.Drug_gne__c=MH.Drug_gne__c;
                    ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                    ship.Dispense_gne__c=MH.Dispense_gne__c;ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;
                    if((Ship.Dispense_gne__c!=null)&&(Ship.Dispense_gne__c!='')&&(Ship.Expected_Ship_Date_gne__c!=null))
                  {
                    for(integer j=0;j<3;j++)
                      {   if (Dispense[j]==ship.Dispense_gne__c)
                            Ship.Days_Supply_Authorized_gne__c=String.valueOf(DispenseDouble[j]);}  
                  }
                  }
              if(Ship.Quantity_1_gne__c==1)
          { Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(30);
            Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(20);}
          else if(Ship.Quantity_1_gne__c==2)
          { Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(60);
            Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(50);}
          else if(Ship.Days_Supply_Authorized_gne__c!=null)
          { Ship.Exhaust_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Integer.valueof(Ship.Days_Supply_Authorized_gne__c));
            Ship.Reorder_Date_gne__c=Ship.Expected_Ship_Date_gne__c.adddays(Integer.valueof(Ship.Days_Supply_Authorized_gne__c) - 10);}
          else
          { Ship.Exhaust_Date_gne__c=null;
            Ship.Reorder_Date_gne__c=null;}
             }
           if(trigger.isInsert)
            {  
                if(ship.Product_gne__c=='Avastin')
                {   
                     ship.Drug_gne__c=MH.Drug_gne__c;ship.Dosage_Infused_mg_gne__c=MH.Dosage_Infused_mg_gne__c;ship.Dosage_mg_kg_gne__c=MH.Dosage_mg_kg_gne__c;
                     ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;ship.Units_Billed_gne__c=MH.Units_Billed_gne__c;
                     ship.Dosage_Regimen_gne__c=MH.Dosage_Regimen_gne__c;ship.GATCF_SMN_Expiration_Date_gne__c=MH.GATCF_SMN_Expiration_Date_gne__c;
                     ship.Number_of_Doses_gne__c=MH.Number_of_Doses_gne__c;ship.Vial_Size_gne__c=MH.Vial_Size_gne__c;
                }
                
                if(ship.Product_gne__c==TDM1_Product_Name)
                {    
                    GNE_CM_Shipment_rx_Data_Calc_Stamp.setShipmentDefaults(ship, MH);
                }
            }
            if(ship.Product_gne__c=='Raptiva')
            {  if(trigger.isInsert)
                { ship.Vial_Size_gne__c='125 mg';
                   ship.Drug_gne__c=MH.Drug_gne__c;ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                   ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;ship.Therapy_Type_gne__c=MH.Therapy_Type_gne__c;
                   ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;ship.NKDA_gne__c=MH.NKDA_gne__c;
                   ship.Patient_Weight_kg_gne__c=MH.Patient_Weight_kg_gne__c;ship.Weekly_Dose_mg_gne__c=MH.Weekly_Dose_mg_gne__c;
                   ship.Weekly_Dose_ml_gne__c=MH.Weekly_Dose_ml_gne__c;ship.Injs_per_week_gne__c=MH.Injs_per_week_gne__c;
                   ship.Dispense_gne__c=MH.Dispense_gne__c;ship.Refill_times_gne__c=MH.Refill_times_gne__c;
                   ship.Refill_Through_Date_gne__c=MH.Refill_Through_Date_gne__c;ship.Mg_Injection_gne__c=MH.Weekly_Dose_mg_gne__c;
               }
               if(ship.Status_gne__c=='OH - On Hold')
               {    for(integer i=0;i<InjWeekMH.size();i++)
                    { if (ship.Injs_per_week_gne__c==InjWeekMH[i])
                        InjWeek=InjWeekVal[i];
                    }
                    ship.of_Vials_Needed_gne__c=null;ship.Quantity_1_gne__c=null;Ship.of_Cartons_to_Ship_gne__c=null;
                    Ship.Mg_Received_gne__c=null;Ship.Mg_Needed_gne__c=null;ship.Total_Shipment_Cost_Wholesale_Price_gne__c=null;
                    if((ship.Weekly_Dose_mg_gne__c!=null&&Ship.Days_Supply_Authorized_gne__c!=null)&&(InjWeek * ship.Weekly_Dose_mg_gne__c>375))
                        ship.of_Vials_Needed_gne__c=16 * Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)/30;
                    if ((ship.Weekly_Dose_mg_gne__c!=null&&Ship.Days_Supply_Authorized_gne__c!=null)&&(InjWeek * ship.Weekly_Dose_mg_gne__c>250)&&(InjWeek * ship.Weekly_Dose_mg_gne__c <=375))
                        ship.of_Vials_Needed_gne__c=12 * Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)/30;
                    if ((ship.Weekly_Dose_mg_gne__c!=null&&Ship.Days_Supply_Authorized_gne__c!=null)&&(InjWeek * ship.Weekly_Dose_mg_gne__c>125)&&(InjWeek * ship.Weekly_Dose_mg_gne__c <=250))
                        ship.of_Vials_Needed_gne__c=8 * Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)/30;
                    if ((ship.Weekly_Dose_mg_gne__c!=null&&Ship.Days_Supply_Authorized_gne__c!=null)&&(InjWeek * ship.Weekly_Dose_mg_gne__c <=125))
                        ship.of_Vials_Needed_gne__c=4 * Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)/30;
                    ship.Quantity_1_gne__c=Ship.of_Vials_Needed_gne__c;
                    if ((Ship.of_Vials_Needed_gne__c!=null )&&(VialPerCarton!=null) &&(VialPerCarton!=0))
                        Ship.of_Cartons_to_Ship_gne__c=math.ceil(Ship.of_Vials_Needed_gne__c/VialPerCarton.intValue());                               
                    if ((ship.of_Vials_Needed_gne__c!=null)&&(VialSize!=null)&&(VialSize!=0))
                        Ship.Mg_Received_gne__c=VialSize * ship.of_Vials_Needed_gne__c;
                    if (ship.Weekly_Dose_mg_gne__c!=null&&Ship.Days_Supply_Authorized_gne__c!=null)
                    { if (Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)==30) Ship.Mg_Needed_gne__c=ship.Weekly_Dose_mg_gne__c * InjWeek * 4;
                      if (Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)==60) Ship.Mg_Needed_gne__c=ship.Weekly_Dose_mg_gne__c * InjWeek * 8;
                      if (Integer.valueOf(Ship.Days_Supply_Authorized_gne__c)==90) Ship.Mg_Needed_gne__c=ship.Weekly_Dose_mg_gne__c * InjWeek * 12;
                    }
               }
          if(ship.Shipped_From_Site_gne__c!=null && ship.Shipped_From_Site_gne__c.equalsIgnoreCase('RxCrossroads')&&ship.Actual_Number_of_Vials_Shipped_gne__c!=null)
                   ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.Actual_Number_of_Vials_Shipped_gne__c * WAPPrice;
                else if(Ship.of_Vials_Needed_gne__c!=null)
                   ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.of_Vials_Needed_gne__c * WAPPrice;
            }
            if(trigger.isInsert)
            {  if(ship.Product_gne__c=='Tarceva')
               {    
                if(ship.case_type_gne__c == 'GATCF - Standard Case')
                {
                    ship.Quantity_1_gne__c=MH.X150_mg_Qty_gne__c;ship.Quantity_2_gne__c=MH.X100_mg_Qty_gne__c;ship.Quantity_3_gne__c=MH.X25_mg_Qty_gne__c;
                    ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                    ship.Dosage_gne__c=MH.Dosage_mg_gne__c;ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                }
                else if(ship.case_type_gne__c == 'C&R - Standard Case')
                {
                    ship.Quantity_1_gne__c = MH.X150mg_Total_Number_of_Tablets_gne__c;
                    ship.Quantity_2_gne__c = MH.X100mg_Total_Number_of_Tablets_gne__c;
                    ship.Quantity_3_gne__c = MH.X25mg_Total_Number_of_Tablets_gne__c;
                    ship.starter_begin_date_gne__c = MH.Starter_Rx_Date_gne__c;
                    //ship.Rx_Expiration_Date_gne__c = MH.Starter_Rx_Expiration_Date_gne__c;
                }
               }
            }
            // JH 11/22/2013 - Reformatted for Xolair CIU
            if(ship.Product_gne__c=='Xolair'&&ship.Case_Shipment_Request_gne__c==null)
            {  
              if(trigger.isInsert)
              { 
                //JH Note - get vial size from product catalog?
                //ship.Vial_Size_gne__c='150 mg';
                if(ship.Action_gne__c!='GATCF Replacement') {
                  ship.Mg_Injection_gne__c=MH.Dosage_mg_gne__c;
                }
                ship.Drug_gne__c=MH.Drug_gne__c;
                ship.Dispense_month_supply_gne__c=MH.Dispense_month_supply_gne__c;
                ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                ship.Refill_times_gne__c=MH.Refill_times_gne__c;
                ship.Dose_Frequency_in_weeks_gne__c=MH.Dose_Frequency_in_weeks_gne__c;
                ship.Drug_Substitution_Allowed_gne__c=MH.Drug_Substitution_Allowed_gne__c;
                ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
              }
              if(ship.Status_gne__c=='OH - On Hold')
              { 
                Ship.Mg_Needed_gne__c=null;
                
                //PK 12/9/2013 The calculation of of_Vials_Needed_gne__c is done in GNE_CM_ShipExtensionController.cls
               // Ship.of_Vials_Needed_gne__c=null;
                ship.Quantity_1_gne__c=null;
                Ship.Mg_Received_gne__c=null;
                ship.Total_Shipment_Cost_Wholesale_Price_gne__c=null;
                ship.Exhaust_Date_gne__c=null;
                ship.Reorder_Date_gne__c=null;
                
                  if((Ship.Mg_Injection_gne__c!=null)&&(Ship.Dosage_Authorized_gne__c!=null))
                    Ship.Mg_Needed_gne__c=Ship.Mg_Injection_gne__c * Ship.Dosage_Authorized_gne__c;
                  
                  //PK 12/9/2013 This calculation of of_Vials_Needed_gne__c is done in GNE_CM_ShipExtensionController.cls
                  //Hence commenting this part
                  //if((Ship.Mg_Injection_gne__c!=null)&&(Ship.Dosage_Authorized_gne__c!=null))
                  //  Ship.of_Vials_Needed_gne__c=math.ceil(Ship.Mg_Injection_gne__c/150) * Ship.Dosage_Authorized_gne__c;
                    
                    //JH Note - won't this always execute when on hold......
                    ship.Quantity_1_gne__c=Ship.of_Vials_Needed_gne__c;
                  if(Ship.of_Vials_Needed_gne__c!=null)
                    Ship.Mg_Received_gne__c=Ship.of_Vials_Needed_gne__c * 150;
                  if((ship.Dose_Frequency_in_weeks_gne__c=='Every 4 weeks')&&(ship.Dosage_Authorized_gne__c!=null))
                  {
                    ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(ship.Dosage_Authorized_gne__c.intValue() * 28);
                    ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays((ship.Dosage_Authorized_gne__c.intValue() * 28)-10);
                  }
                  if((ship.Dose_Frequency_in_weeks_gne__c=='Every 2 weeks')&&(ship.Dosage_Authorized_gne__c!=null))
                  {   
                    ship.Exhaust_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays(ship.Dosage_Authorized_gne__c.intValue() * 14);
                    ship.Reorder_Date_gne__c=ship.Expected_Ship_Date_gne__c.adddays((ship.Dosage_Authorized_gne__c.intValue() * 14)-10);
                  }
              }
              //PK 12/6/2013 for Xolair CIU. List Price calculated the same way as wholesale price.
              if(ship.Shipped_From_Site_gne__c!=null && ship.Shipped_From_Site_gne__c.equalsIgnoreCase('RxCrossroads')&&ship.Actual_Number_of_Vials_Shipped_gne__c!=null){
                ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.Actual_Number_of_Vials_Shipped_gne__c * WAPPrice;
                ship.Total_Shipment_Cost_List_Price_gne__c=Ship.Actual_Number_of_Vials_Shipped_gne__c * listPrice;
                
              }
              else if(Ship.of_Vials_Needed_gne__c!=null){
                ship.Total_Shipment_Cost_Wholesale_Price_gne__c=Ship.of_Vials_Needed_gne__c * WAPPrice;
                ship.Total_Shipment_Cost_List_Price_gne__c=Ship.of_Vials_Needed_gne__c * listPrice;
              }
            }//end block for Xolair
            
            if(trigger.isInsert)
            { 
                if(ship.Product_gne__c=='Activase')
                {  ship.Drug_gne__c=MH.Drug_gne__c;ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                   ship.Vial_Size_gne__c=MH.Vial_Size_gne__c;ship.Number_of_Doses_gne__c=MH.Number_of_Doses_gne__c;
                   ship.Aliquot_gne__c=MH.Aliquot_gne__c;ship.Vial_Qty_gne__c=MH.Vial_Qty_gne__c;ship.Route_of_Admin_gne__c=MH.Route_of_Admin_gne__c;
                 }
                 if(ship.Product_gne__c=='Rituxan'||ship.Product_gne__c=='Rituxan RA')
                 { ship.Drug_gne__c=MH.Drug_gne__c;ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;
                  ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                  ship.Units_Billed_gne__c=MH.Units_Billed_gne__c;ship.Route_of_Admin_gne__c=MH.Route_of_Admin_gne__c;
                 }
                 if(ship.Product_gne__c=='Rituxan RA')
                 {   ship.Quantity_of_100mg_Vials_gne__c=MH.Quantity_of_100mg_Vials_gne__c;ship.Number_of_Refills_gne__c=MH.Number_of_Refills_gne__c;
                     ship.Infuse_mg_Day1_Day15_gne__c=MH.Infuse_mg_Day1_Day15_gne__c;ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                     ship.Quantity_of_500mg_Vials_gne__c=MH.Quantity_of_500mg_Vials_gne__c;ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;
                     ship.NKDA_gne__c=MH.NKDA_gne__c;ship.Infuse_Other_gne__c=MH.Infuse_Other_gne__c;
                 }
                 if(ship.Product_gne__c=='Lucentis')
                 {   ship.Drug_gne__c=MH.Drug_gne__c; ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                     ship.Refill_times_gne__c=MH.Refill_times_gne__c;ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;
                     ship.Eye_Being_Treated_gne__c=MH.Eye_Being_Treated_gne__c;ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;
                     ship.NKDA_gne__c=MH.NKDA_gne__c;ship.Rx_Date_gne__c=MH.Rx_Effective_Date_gne__c;
                     ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;ship.SMN_Effective_Date_gne__c=MH.SMN_Effective_Date_gne__c;
                     ship.SMN_Expiration_Date_gne__c=MH.SMN_Expiration_Date_gne__c;
                 }
                 
                 //KS: Pertuzumab Condition
                 if(ship.Product_gne__c== Pertuzumab_Product_Name)
                 {   
                    system.debug('setting value for drug from MH....'+MH.Drug_gne__c);
                    ship.Drug_gne__c = MH.Drug_gne__c; 
                    ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                    ship.Refill_times_gne__c=MH.Refill_times_gne__c;
                    ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;
                    ship.Eye_Being_Treated_gne__c=MH.Eye_Being_Treated_gne__c;
                    ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;
                    ship.NKDA_gne__c=MH.NKDA_gne__c;
                    //ship.Rx_Date_gne__c = MH.Rx_Date_gne__c;
                    //ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                    ship.SMN_Effective_Date_gne__c=MH.SMN_Effective_Date_gne__c;
                    ship.SMN_Expiration_Date_gne__c=MH.SMN_Expiration_Date_gne__c;
                 }
                 //KS: Pertuzumab Condition ends here
                 
                 if(ship.Product_gne__c=='TNKase')
                 {   ship.Drug_gne__c=MH.Drug_gne__c;ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                     ship.Vial_Size_gne__c=MH.Vial_Size_gne__c;ship.Number_of_Doses_gne__c=MH.Number_of_Doses_gne__c;
                     ship.Aliquot_gne__c=MH.Aliquot_gne__c;ship.Vial_Qty_gne__c=MH.Vial_Qty_gne__c;ship.Route_of_Admin_gne__c=MH.Route_of_Admin_gne__c;
                 }
                 if(ship.Product_gne__c=='Actemra')
                 {
                        ship.Drug_gne__c=MH.Drug_gne__c;
                        ship.Dosage_mg_gne__c=MH.Dosage_mg_gne__c;
                        ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;
                        ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                        ship.Freqcy_of_Admin_gne__c=MH.Freqcy_of_Admin_gne__c;
                        ship.Drug_Allergies_gne__c=MH.Drug_Allergies_gne__c;
                        ship.NKDA_gne__c=MH.NKDA_gne__c;
                        ship.Route_of_Admin_gne__c=MH.Route_of_Admin_gne__c;
                        ship.Num_of_Refills_gne__c=MH.Num_of_Refills_gne__c;
                        ship.Infuse_Other_gne__c=MH.Infuse_Other_gne__c;
                        ship.GATCF_SMN_Expiration_Date_gne__c=MH.GATCF_SMN_Expiration_Date_gne__c;
                        ship.Quantity_of_80mg_Vials_gne__c=MH.Quantity_of_80mg_Vials_gne__c;
                        ship.Quantity_of_100mg_vials_gne__c=MH.Quantity_of_200mg_Vials_gne__c;
                        ship.Quantity_of_500mg_Vials_gne__c=MH.Quantity_of_400mg_Vials_gne__c;
                 }
                 if(ship.Product_gne__c=='Actemra Subcutaneous')    //Added by Ashutosh on 20-09-2013 for Actemra to update shipment RX section updation after RX section update on MH
                 {
                     
                        if(ship.case_type_gne__c == 'GATCF - Standard Case')
                        {
                             ship.Drug_gne__c                       = MH.Drug_gne__c;
                             ship.Dosage_mg_gne__c                  = MH.Dosage_mg_gne__c;
                             ship.Rx_Date_gne__c                    = MH.Rx_Date_gne__c;
                             ship.Rx_Expiration_gne__c              = MH.Rx_Expiration_gne__c;
                             ship.Freqcy_of_Admin_gne__c            = MH.Frequency_of_Admin_actemra_subq_gne__c;
                             ship.Drug_Allergies_gne__c             = MH.Drug_Allergies_gne__c;
                             ship.NKDA_gne__c                       = MH.NKDA_gne__c;
                             ship.Route_of_Admin_gne__c             = MH.Route_of_Admin_gne__c;
                             ship.Num_of_Refills_gne__c             = MH.Num_of_Refills_gne__c;
                             ship.Dispense_gne__c                   = MH.Dispense_gne__c;
                             ship.GATCF_SMN_Expiration_Date_gne__c    = MH.GATCF_SMN_Expiration_Date_gne__c;
                             
                             ship.Quantity_of_500mg_Vials_gne__c      = MH.Qty_162_mg_actemra_subq_gne__c;
                             ship.Dispense_Other_BRAF_gne__c          = MH.Dispense_Other_BRAF_gne__c;
                             ship.Other_Actemra_SubQ_gne__c           = MH.Other_Administration_Location_gne__c;
                        }
                        else if(ship.case_type_gne__c == 'C&R - Standard Case')
                        {
                            ship.Quantity_of_500mg_Vials_gne__c      = MH.Qty_162_mg_actemra_subq_gne__c;
                            ship.Dispense_gne__c                     = MH.Dispense_15_days_supply_actemra_subq_gne__c;
system.debug ('DSO Starter Rx Date :  ' + MH.Starter_Rx_Date_gne__c);
                            ship.Rx_Date_gne__c                      = MH.Starter_Rx_Date_gne__c;
                            ship.Num_of_Refills_gne__c               = string.valueof(MH.Refill_times_gne__c);
                            ship.Freqcy_of_Admin_gne__c = MH.Starter_Frequency_of_Administration_gne__c;
                            ship.SMN_Effective_Date_gne__c           = MH.Starter_SMN_Effective_Date_gne__c;
                            ship.Vial_Qty_gne__c                     = MH.Vial_Qty_gne__c;
                            ship.Rx_Expiration_gne__c                = MH.Starter_Rx_Expiration_Date_gne__c;
                        }
                   }
                 if(ship.Product_gne__c=='Xeloda'){
                    ship.Rx_Date_gne__c=MH.Rx_Date_gne__c;ship.Days_in_Cycle_500mg_gne__c=MH.Days_in_Cycle_500mg_gne__c;
                    ship.Days_in_Cycle_150mg_gne__c=MH.Days_in_Cycle_150mg_gne__c;ship.Rx_Expiration_gne__c=MH.Rx_Expiration_gne__c;
                   ship.GATCF_SMN_Expiration_Date_gne__c=MH.GATCF_SMN_Expiration_Date_gne__c;ship.Cycles_per_fill_gne__c=MH.Cycles_per_fill_gne__c;
                   ship.CM_500mg_tablets_gne__c=MH.CM_500mg_tablets_gne__c;ship.CM_500mg_times_per_day_gne__c=MH.CM_500mg_times_per_day_gne__c;
                   ship.CM_500mg_of_days_on_gne__c=MH.CM_500mg_of_days_on_gne__c;ship.CM_500mg_of_days_off_gne__c=MH.CM_500mg_of_days_off_gne__c;
                   ship.CM_500mg_Sig_Other_gne__c=MH.CM_500mg_Sig_Other_gne__c;ship.CM_500mg_Total_tablets_per_cycle_gne__c=MH.CM_500mg_Total_tablets_per_cycle_gne__c;
                   ship.CM_150mg_tablets_gne__c=MH.CM_150mg_tablets_gne__c;ship.CM_150mg_times_per_day_gne__c=MH.CM_150mg_times_per_day_gne__c;
                   ship.CM_150mg_of_days_on_gne__c=MH.CM_150mg_of_days_on_gne__c;ship.CM_150mg_of_days_off_gne__c=MH.CM_150mg_of_days_off_gne__c;
                   ship.CM_150mg_Sig_Other_gne__c=MH.CM_150mg_Sig_Other_gne__c;ship.CM_150mg_Total_tablets_per_cycle_gne__c=MH.CM_150mg_Total_tablets_per_cycle_gne__c;
                 }
             }
          }
          } 
          catch(exception e)
         {   ship.adderror('Unexpected error has occured while updating Prescription data from Medical history :' + e.getmessage());
           }
        }
    }
}