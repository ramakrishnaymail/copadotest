//PK 2/10/2014 hot fix for CHG000000036864. Added threshold date filter so we only consider shipments created after the threshold date
trigger GNE_CM_Shipment_creation_check on Shipment_gne__c (before insert) {
	// skip this trigger during merge process
	if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
		return;
	}
	
double Upfront_case_ship =0; double Replacement_case_ship =0;
 double Upfront =0; double Available_ship =0; double upfront_flag =0; double upfront_count =0;
 Set<Id> Case_id = new Set<id>(); Map<Id, Case> Case_id_map = new Map<Id, Case>();
 List<double> temp_set = new List<double>();
 double vial_low =0; double return_qty1 =0; double return_qty2 =0; double return_qty3 =0;
 double ship_round =0; double Miligram = 0; double Return1 =0; double Return2 =0; double Return3 =0;
 double calculate_Returned_rep=0; double calculate_Returned_upf=0;
 double Miligram_round =0;double Ship_calc = 0; double Vial1 = 0; double Vial2 = 0; double Vial3 = 0;
 Map<Id, List<double>> case_calc = new Map<Id, List<double>> (); List<Product_vod__c> product_catalog = new List<Product_vod__c>();
 Set<String> product_id = new Set<String>();  Map<String, Double> product_NDC = new Map<String, Double>();
 double Miligram_PT_tot_rep=0; double Miligram_PT_tot_upf=0; double Miligram_CR_rep=0; double Miligram_CR_upf=0;
 double Miligram_DE_rep=0; double Miligram_DE_upf=0; double calculate_AL_rep=0; double calculate_AL_upf=0;
 double calculate_OH_rep=0; double calculate_OH_upf=0; double Quantity1=0; double Quantity2=0; double Quantity3=0;
//KS: Pertuzumab Condition
string Pertuzumab_Product_Name = system.label.GNE_CM_Pertuzumab_Product_Name;
//KS: Pertuzumab Condition ends here

string TDM1_Product_Name = system.label.GNE_CM_TDM1_Product_Name;

List<Profile> p = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
 for(shipment_gne__c ship : trigger.new)
  {
  	try
    {
    	if(ship.Case_shipment_gne__c !=null)
     		Case_id.add(ship.Case_shipment_gne__c);}
    catch(exception e)
    {
    	ship.adderror('Error in creation of Account/Case set');
    }
  }//end for on Trigger.new
  
 try
  {
  	if(case_id.size()>0)
    {
        if(!GNE_CM_Shipment_Parent_Class.case_id_map_inf)
            {
                GNE_CM_Shipment_Parent_Class.setcaseidmap(case_id);
                Case_id_map = GNE_CM_Shipment_Parent_Class.getcaseidmap();
            }
            else 
            Case_id_map = GNE_CM_Shipment_Parent_Class.getcaseidmap();
    }
  }
  catch(exception e) 
  { 
  	for(Shipment_gne__c ship: trigger.new)
    	ship.adderror('Error in SOQL. Aborting process!');
  }
  for(Shipment_gne__c ship: trigger.new)
   {
   	try
    {
	system.debug('PR Trigger: final Quantity_1_gne__c' + ship.Quantity_1_gne__c);	
    if(ship.Case_shipment_gne__c !=null && case_id_map.containskey(ship.Case_shipment_gne__c))
      {
      	if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan RA' ||                 
          case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Avastin' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Actemra'
          || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c ==TDM1_Product_Name)
        {
        	if(ship.Product_Vial_P1_gne__c !=null && ship.NDC_Product_Vial_1_gne__c!=null)
         		product_id.add(ship.NDC_Product_Vial_1_gne__c);
          
          	System.debug('!!!!product_id 1' + product_id);
         	
         	if(ship.Product_Vial_P2_gne__c != null && ship.NDC_Product_Vial_2_gne__c !=null)
         		product_id.add(ship.NDC_Product_Vial_2_gne__c);
          	
          	System.debug('!!!!product_id 2' + product_id);
         	
         	if(ship.Product_Vial_P3_gne__c != null && ship.NDC_Product_Vial_3_gne__c !=null)
         		product_id.add(ship.NDC_Product_Vial_3_gne__c);
         
         	System.debug('!!!!product_id 3' + product_id);
         }
			//PK 12/03/2013 for Xolair PFS-966
          else if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Xolair'){
          	if(ship.NDC_Product_Vial_1_gne__c!=null)
            	product_id.add(ship.NDC_Product_Vial_1_gne__c);	
          }
         else if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Lucentis')
         {
           if(ship.Product_Vial_P1_gne__c !=null && ship.NDC_Product_Vial_1_gne__c!=null)
            	product_id.add(ship.NDC_Product_Vial_1_gne__c);
          }
         //KS: Pertuzumab Condition 
         else if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name)
         {
           if(ship.Product_Vial_P1_gne__c !=null && ship.NDC_Product_Vial_1_gne__c!=null)
           		product_id.add(ship.NDC_Product_Vial_1_gne__c);
          }
        //KS: Pertuzumab Condition ends here  
        }//end check on ship.Case_shipment_gne__c 
      }  
     catch(exception e)
     {
     	ship.adderror('Error encountered while getting product of shipment '+e);
     }
    System.debug('!!!!product_id final' + product_id);    
   }//end for on Trigger.new
    
  try
  {
  	if(product_id.size()>0)
    {
        if(!GNE_CM_Shipment_Parent_Class.prod_catalog_flag)
        {
            GNE_CM_Shipment_Parent_Class.setproductcatalog(product_id);
            product_catalog = GNE_CM_Shipment_Parent_Class.getproductcatalog();
        }
        else 
        	product_catalog = GNE_CM_Shipment_Parent_Class.getproductcatalog();
        
        system.debug('**** product_catalog' + product_catalog);
    }
  }
  catch(exception e)
   {
   	for(Shipment_gne__c ship: trigger.new)
    	ship.adderror('Error while querying product catalog. Aborting process!');
   } 

  for(Shipment_gne__c ship: trigger.new)
   {
   	try
    {
    	if(ship.Case_shipment_gne__c !=null && case_id_map.containskey(ship.Case_shipment_gne__c) && !case_calc.containskey(ship.Case_shipment_gne__c) && product_catalog.size()>0)
     	{
     		upfront_flag = 0; 
     		upfront_count =0; 
     		Available_ship =0; 
     		Upfront =0; 
     		temp_set.clear();
	       if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan RA' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Lucentis' ||
	          case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Avastin' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Actemra'
	          || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c ==TDM1_Product_Name
	          || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Xolair')
	       {
	       	for(integer i=0;i<product_catalog.size();i++)
	         {
	         	if(product_catalog[i].NDC_Number_gne__c !=null && product_catalog[i].Vial_size_gne__c !=null)
	          		product_NDC.put(product_catalog[i].NDC_Number_gne__c, product_catalog[i].Vial_size_gne__c);
	         }//end for
	       }//end check on product names 
       for(Infusion_gne__c ins: Case_id_map.get(ship.Case_shipment_gne__c).Infusions__r)
        {
        	if(ins.Milligrams_gne__c!=null)
	          {
	          	if((ins.Infusion_Type_gne__c == 'Pretreatment' || ins.Infusion_Type_gne__c == 'Replacement') && ins.Infusion_Injection_Status_gne__c=='Processed')
		           {
		           	if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan RA' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Avastin')
		            {
		            	Miligram = ins.Milligrams_gne__c /100; Miligram_round = Math.ceil(Miligram); Miligram = Miligram_round *100;
		            }
		             if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Lucentis')
		             {
		             	Miligram = ins.Milligrams_gne__c /0.5; 
		             	Miligram_round = Math.ceil(Miligram); 
		             	Miligram = Miligram_round *0.5;
		             }
		             
		             //KS:Pertuzumab condition
		             if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name)
		             {
		               Miligram = ins.Milligrams_gne__c /420; 
		               Miligram_round = Math.ceil(Miligram); 
		               Miligram = Miligram_round *420;
		             }
		             //KS:Pertuzumab condition ends here
		              
		       // TDM1
		             if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == TDM1_Product_Name)
		             {
		              Vial1=product_NDC.containsKey(ship.NDC_Product_Vial_1_gne__c) ? product_NDC.get(ship.NDC_Product_Vial_1_gne__c) : 0.0;
		              Vial2=product_NDC.containsKey(ship.NDC_Product_Vial_2_gne__c) ? product_NDC.get(ship.NDC_Product_Vial_2_gne__c) : 0.0;
		              
		              List<Integer> calcqtyies = GNE_CM_CalculateInfusioncounts.calculateVialQuantities((Double)ins.Milligrams_gne__c, Vial1, Vial2);
		              
		              Miligram =Vial1*calcqtyies[0]+Vial2*calcqtyies[1];
		             }
		              
		             if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Actemra')
		             {
		             	Miligram =  ins.Milligrams_gne__c /80; 
		             	Miligram_round = Math.ceil(Miligram); 
		             	Miligram = Miligram_round *80;
		             }//end block for Actemra 
		             //PK 12/03/2013 for Xolair PFS-966
		             if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Xolair'){
		             	System.debug('ship.NDC_Product_Vial_1_gne__c===='+ship.NDC_Product_Vial_1_gne__c);
		             	System.debug('.ins.Milligrams_gne__c===='+ins.Milligrams_gne__c);
		             	System.debug('product_NDC===='+product_NDC);
		             	Vial1=product_NDC.containsKey(ship.NDC_Product_Vial_1_gne__c) ? product_NDC.get(ship.NDC_Product_Vial_1_gne__c) : 0.0;
		             	List<Integer> calcqtyies = GNE_CM_CalculateInfusioncounts.calculateVialQuantitiesSingleVial((Double)ins.Milligrams_gne__c, Vial1);
		             	 Miligram =vial1*calcqtyies[0];
		             }//end block for Xolair
		             if(ins.Infusion_Type_gne__c == 'Pretreatment' && ins.Infusion_Debit_Credit_gne__c == null)
		             	Miligram_PT_tot_upf += Miligram;   
		             else if(ins.Infusion_Type_gne__c == 'Replacement' && ins.Infusion_Debit_Credit_gne__c == null)
		             	Miligram_PT_tot_rep += Miligram;
		         }//end checks on Infusion_Type_gne__c
	             if(ins.Infusion_Type_gne__c == 'Pretreatment')
	             {
	             	if(ins.Infusion_Debit_Credit_gne__c == 'Debit')
	              		Miligram_DE_upf += ins.Milligrams_gne__c;
	              	else if(ins.Infusion_Debit_Credit_gne__c == 'Credit') 
	              			Miligram_CR_upf += ins.Milligrams_gne__c;
	              }//end check for pretreatment
	              if(ins.Infusion_Type_gne__c == 'Replacement')
	              {
	              	if(ins.Infusion_Debit_Credit_gne__c == 'Debit')
	               		Miligram_DE_rep += ins.Milligrams_gne__c;
	               	else if(ins.Infusion_Debit_Credit_gne__c == 'Credit') 
	               			Miligram_CR_rep += ins.Milligrams_gne__c;
	               }//end check for replacement                                         
	           }//end null check for ins.Milligrams_gne__c   
        }//end for on Case_id_map.get(ship.Case_shipment_gne__c).Infusions__r
        if((case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case') || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan RA' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
           || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Avastin' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name !='C&R - Standard Case')
           || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == TDM1_Product_Name && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name !='C&R - Standard Case'))
        {
        	for(Shipment_gne__c ship_cas : case_id_map.get(ship.Case_shipment_gne__c).Shipments__r)
	          { 
		          if(ship_cas.Quantity_1_gne__c == null)
		           		ship_cas.Quantity_1_gne__c=0;
		           if(ship_cas.Quantity_2_gne__c == null)
		           		ship_cas.Quantity_2_gne__c=0;
		           if(ship_cas.NDC_Product_Vial_1_gne__c !=null && ship_cas.NDC_Product_Vial_2_gne__c !=null)
		           {
			           	if(ship_cas.Action_gne__c == 'GATCF Pretreatment'&& product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c)
			               && case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan')
			            {
			            	upfront_flag = 1; upfront_count ++;
			            }
			            if(ship_cas.Action_gne__c == 'GATCF Upfront' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c)
			              && case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan RA')
			            {
			            	upfront_flag = 1; upfront_count ++;
			            } 
			            if((ship_cas.Action_gne__c == 'GATCF Pretreatment' || ship_cas.Action_gne__c == 'Clinical' || ship_cas.Action_gne__c == 'APA Program') && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c)
			               && case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Avastin')
			            {
			            	upfront_flag = 1; upfront_count ++;
			            }   
			            if((ship_cas.Action_gne__c == 'GATCF Pretreatment' || ship_cas.Action_gne__c == 'Clinical' || ship_cas.Action_gne__c == 'APA Program') && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c)
			               && case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == TDM1_Product_Name)
			            {
			            	upfront_flag = 1; upfront_count ++;
			            }   
			            if( ship_cas.Status_gne__c == 'SH - Shipped' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c))
			            {
			            	Return1 = ship_cas.of_Vials_Returned_gne__c == null ? 0 : ship_cas.of_Vials_Returned_gne__c; Return2 = ship_cas.of_Vials_Returned_2_gne__c == null ? 0 : ship_cas.of_Vials_Returned_2_gne__c; 
				            if(ship_cas.Action_gne__c == 'GATCF Pretreatment' || ship_cas.Action_gne__c == 'GATCF Upfront' || ship_cas.Action_gne__c == 'Clinical' || ship_cas.Action_gne__c == 'APA Program')
				            {
				            	Upfront_case_ship += ((ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c)) + (ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)));
				            	calculate_Returned_upf +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + Return2*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c);
				            }
				            else if(ship_cas.Action_gne__c == 'GATCF Replacement (Onc)' || ship_cas.Action_gne__c == 'GATCF Replacement')
				            {
				            	Replacement_case_ship += ((ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c)) + (ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)));
				            	calculate_Returned_rep +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + Return2*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c);
				            } 
			            }//end block for Status_gne__c = 'SH - Shipped'
			            if((ship_cas.Status_gne__c == 'AL - Allocated' || ship_cas.Status_gne__c == 'PG - Pick List Generated' || ship_cas.Status_gne__c == 'VE - Verified' || ship_cas.Status_gne__c == 'RE - Released')
			               && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c))
			            {
			            	if(ship_cas.Action_gne__c == 'GATCF Pretreatment' || ship_cas.Action_gne__c == 'GATCF Upfront' || ship_cas.Action_gne__c == 'Clinical' || ship_cas.Action_gne__c == 'APA Program')
				            	calculate_AL_upf += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c));
				            else if(ship_cas.Action_gne__c == 'GATCF Replacement (Onc)' || ship_cas.Action_gne__c == 'GATCF Replacement')
				             	calculate_AL_rep += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c));
			             }//end block for Status_gne__c = 'AL - Allocated'
			            if(ship_cas.Status_gne__c == 'OH - On Hold' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c))
			            {
			            	if(ship_cas.Action_gne__c == 'GATCF Pretreatment' || ship_cas.Action_gne__c == 'GATCF Upfront' || ship_cas.Action_gne__c == 'Clinical' || ship_cas.Action_gne__c == 'APA Program')
				            	calculate_OH_upf += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c));
				             else if(ship_cas.Action_gne__c == 'GATCF Replacement (Onc)' || ship_cas.Action_gne__c == 'GATCF Replacement')
				             	calculate_OH_rep += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c));
			             }//end block for Status_gne__c = 'OH - On Hold'
		             }//end null check on NDC_Product_Vial_1_gne__c and NDC_Product_Vial_2_gne__c                                     
	          }//end for on case_id_map.get(ship.Case_shipment_gne__c).Shipments__r
     	Upfront = Miligram_PT_tot_upf + Miligram_DE_upf - Miligram_CR_upf +calculate_returned_upf - Upfront_case_ship - Calculate_AL_upf - calculate_OH_upf ;
     	Available_ship = Miligram_PT_tot_rep + Miligram_DE_rep - Miligram_CR_rep +calculate_returned_rep - replacement_case_ship - Calculate_AL_rep - calculate_OH_rep ;                    
    }//end check on product names     
    system.debug('****UPFRONT***'+Upfront); 
    if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Lucentis' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    {
      return_qty1 =0; return_qty2 =0; vial_low =0;  ship_round =0;
      for(Shipment_gne__c ship_cas : case_id_map.get(ship.Case_shipment_gne__c).Shipments__r)
      { 
      	if(ship_cas.Quantity_1_gne__c == null)
        	ship_cas.Quantity_1_gne__c=0;
        if(ship_cas.NDC_Product_Vial_1_gne__c !=null)
        { 
           if(ship_cas.Action_gne__c == 'GATCF Upfront' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
           { 
          	upfront_flag = 1; upfront_count++;
           }  
          if( ship_cas.Status_gne__c == 'SH - Shipped' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
          { 
          	Return1 = ship_cas.of_Vials_Returned_gne__c == null ? 0 : ship_cas.of_Vials_Returned_gne__c; 
            if(ship_cas.Action_gne__c == 'GATCF Upfront')
            {   
            	Upfront_case_ship += (ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c));
                calculate_Returned_upf += Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
            }
            else if(ship_cas.Action_gne__c == 'GATCF Replacement')
            {  
            	Replacement_case_ship += (ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c));
                calculate_Returned_rep += Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);} 
           }
          if((ship_cas.Status_gne__c == 'AL - Allocated' || ship_cas.Status_gne__c == 'PG - Pick List Generated' || ship_cas.Status_gne__c == 'VE - Verified' || ship_cas.Status_gne__c == 'RE - Released')&& product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
           { if(ship_cas.Action_gne__c == 'GATCF Upfront')                               
             calculate_AL_upf += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
             else if(ship_cas.Action_gne__c == 'GATCF Replacement')
             calculate_AL_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
          }                                                              
          if( ship_cas.Status_gne__c == 'OH - On Hold' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
          { if(ship_cas.Action_gne__c == 'GATCF Upfront') 
            calculate_OH_upf += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
            else if(ship_cas.Action_gne__c == 'GATCF Replacement')
            calculate_OH_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
          }
         }
      }
    Upfront = Miligram_PT_tot_upf + Miligram_DE_upf - Miligram_CR_upf +calculate_returned_upf - Upfront_case_ship - Calculate_AL_upf - calculate_OH_upf ;
    Available_ship = Miligram_PT_tot_rep + Miligram_DE_rep - Miligram_CR_rep +calculate_returned_rep - replacement_case_ship - Calculate_AL_rep - calculate_OH_rep ;                    
  }
  
  //KS: Pertuzumab Condition
   if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    {return_qty1 =0; return_qty2 =0; vial_low =0;  ship_round =0;
     for(Shipment_gne__c ship_cas : case_id_map.get(ship.Case_shipment_gne__c).Shipments__r)
      {
        if(ship_cas.Quantity_1_gne__c == null)
        ship_cas.Quantity_1_gne__c=0;
        if(ship_cas.NDC_Product_Vial_1_gne__c !=null)
        {
          if( ship_cas.Status_gne__c == 'SH - Shipped' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
            {
              Return1 = ship_cas.of_Vials_Returned_gne__c == null ? 0 : ship_cas.of_Vials_Returned_gne__c; 
              
              if(ship_cas.Action_gne__c == 'GATCF Replacement')
              {  Replacement_case_ship += (ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c));
                  calculate_Returned_rep += Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
               } 
         }
        if((ship_cas.Status_gne__c == 'AL - Allocated' || ship_cas.Status_gne__c == 'PG - Pick List Generated' || ship_cas.Status_gne__c == 'VE - Verified' || ship_cas.Status_gne__c == 'RE - Released')&& product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
          { 
            if(ship_cas.Action_gne__c == 'GATCF Replacement')
              calculate_AL_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
          }                                                              
        if( ship_cas.Status_gne__c == 'OH - On Hold' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
        {
          if(ship_cas.Action_gne__c == 'GATCF Replacement')
            calculate_OH_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
          }
         }
      }
    //Upfront = Miligram_PT_tot_upf + Miligram_DE_upf - Miligram_CR_upf +calculate_returned_upf - Upfront_case_ship - Calculate_AL_upf - calculate_OH_upf ;
    Available_ship = Miligram_PT_tot_rep + Miligram_DE_rep - Miligram_CR_rep +calculate_returned_rep - replacement_case_ship - Calculate_AL_rep - calculate_OH_rep ;                    
  }
   //KS:Condition ends here
   
  //KM-10/07/09-Added for Actemra
  if (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Actemra' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    { 
      system.debug('inside cond for actemra....');
      for(Shipment_gne__c ship_cas : case_id_map.get(ship.Case_shipment_gne__c).Shipments__r)
        { 
        	if(ship_cas.NDC_Product_Vial_1_gne__c !=null && ship_cas.NDC_Product_Vial_2_gne__c !=null && ship_cas.NDC_Product_Vial_3_gne__c !=null && case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Actemra')
            {
            	ship_cas.Quantity_1_gne__c = ship_cas.Quantity_1_gne__c == null ? 0 : ship_cas.Quantity_1_gne__c; ship_cas.Quantity_2_gne__c = ship_cas.Quantity_2_gne__c == null ? 0 : ship_cas.Quantity_2_gne__c; ship_cas.Quantity_3_gne__c = ship_cas.Quantity_3_gne__c == null ? 0 : ship_cas.Quantity_3_gne__c;
             if(ship_cas.Action_gne__c == 'GATCF Upfront' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_3_gne__c))
              {
              	upfront_flag = 1; upfront_count ++;
              } 
             if( ship_cas.Status_gne__c == 'SH - Shipped' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_3_gne__c))
              { 
              	Return1 = ship_cas.of_Vials_Returned_gne__c == null ? 0 : ship_cas.of_Vials_Returned_gne__c; Return2 = ship_cas.of_Vials_Returned_2_gne__c == null ? 0 : ship_cas.of_Vials_Returned_2_gne__c; Return3 = ship_cas.of_Vials_Returned_3_gne__c == null ? 0 : ship_cas.of_Vials_Returned_3_gne__c;
                if(ship_cas.Action_gne__c == 'GATCF Upfront')
                {
                	Upfront_case_ship += ((ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c)) + (ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c))+ (ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c)));
                 calculate_Returned_upf +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + Return2*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)+ Return3*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c);
             	}
                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
                {
                	Replacement_case_ship += ((ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c)) + (ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)) + (ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c)));
                 	calculate_Returned_rep +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + Return2*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c) + Return3*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c);} 
                }
             if((ship_cas.Status_gne__c == 'AL - Allocated' || ship_cas.Status_gne__c == 'PG - Pick List Generated' || ship_cas.Status_gne__c == 'VE - Verified' || ship_cas.Status_gne__c == 'RE - Released')
                && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_3_gne__c))
              { if(ship_cas.Action_gne__c == 'GATCF Upfront')
                calculate_AL_upf += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c) + ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c));
                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
                calculate_AL_rep += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c) + ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c));
              }
             if(ship_cas.Status_gne__c == 'OH - On Hold'&& product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) && product_NDC.containskey(ship_cas.NDC_Product_Vial_2_gne__c)&& product_NDC.containskey(ship_cas.NDC_Product_Vial_3_gne__c))
              { 
              	if(ship_cas.Action_gne__c == 'GATCF Upfront')
                	calculate_OH_upf += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)+ ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c));
                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
                	calculate_OH_rep += (ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) + ship_cas.Quantity_2_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_2_gne__c)+ ship_cas.Quantity_3_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_3_gne__c));
              }
          }//end null check for NDC_Product_Vial_1_gne__c, NDC_Product_Vial_2_gne__c and NDC_Product_Vial_3_gne__c
        }//end for on case_id_map.get(ship.Case_shipment_gne__c).Shipments__r
        Upfront = Miligram_PT_tot_upf + Miligram_DE_upf - Miligram_CR_upf +calculate_returned_upf - Upfront_case_ship - Calculate_AL_upf - calculate_OH_upf ;
        Available_ship = Miligram_PT_tot_rep + Miligram_DE_rep - Miligram_CR_rep +calculate_returned_rep - replacement_case_ship - Calculate_AL_rep - calculate_OH_rep ;                    
        }//end block for Actemra 

   //PK 12/03/2013 for Xolair PFS-966
  if (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Xolair' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    { 
    	DateTime thresholdDate = GNE_CM_CustomSettingsHelper.self().getCMConfig().Xolair_InfusionCalc_Threshold__c;
      for(Shipment_gne__c ship_cas : case_id_map.get(ship.Case_shipment_gne__c).Shipments__r)
        { 
        	//PK 2/10/2014 hot fix for CHG000000036864. Added threshold date filter so we only consider shipments created after the threshold date
        	if(ship_cas.NDC_Product_Vial_1_gne__c !=null&& case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Xolair' && ship_cas.CreatedDate>=thresholdDate)
            {
            	ship_cas.Quantity_1_gne__c = ship_cas.Quantity_1_gne__c == null ? 0 : ship_cas.Quantity_1_gne__c; 
            	
	             if(ship_cas.Action_gne__c == 'GATCF Shipment' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
	              {
	              	upfront_flag = 1; upfront_count ++;
	              } 
	             if( ship_cas.Status_gne__c == 'SH - Shipped' && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
	              { 
	              	Return1 = ship_cas.of_Vials_Returned_gne__c == null ? 0 : ship_cas.of_Vials_Returned_gne__c; 
	              	
	                if(ship_cas.Action_gne__c == 'GATCF Shipment')
	                {
	                	Upfront_case_ship += ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) ;
	                 	calculate_Returned_upf +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	             	}
	                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
	                {
	                	Replacement_case_ship += ship_cas.Quantity_1_gne__c *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	                 	calculate_Returned_rep +=  Return1 *product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c) ;
	                 } 
	             }//end block for shipment status 'SH-Shipped'
	             if((ship_cas.Status_gne__c == 'AL - Allocated' || ship_cas.Status_gne__c == 'PG - Pick List Generated' || ship_cas.Status_gne__c == 'VE - Verified' || ship_cas.Status_gne__c == 'RE - Released')
	                && product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c) )
	              { 
	              	if(ship_cas.Action_gne__c == 'GATCF Shipment')
	                	calculate_AL_upf += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
	                	calculate_AL_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	              }//end block for shipment status 'AL - Allocated'
	             if(ship_cas.Status_gne__c == 'OH - On Hold'&& product_NDC.containskey(ship_cas.NDC_Product_Vial_1_gne__c))
	              { 
	              	if(ship_cas.Action_gne__c == 'GATCF Shipment')
	                	calculate_OH_upf += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	                else if(ship_cas.Action_gne__c == 'GATCF Replacement')
	                	calculate_OH_rep += ship_cas.Quantity_1_gne__c*product_NDC.get(ship_cas.NDC_Product_Vial_1_gne__c);
	              }//end block for shipment status 'OH - On Hold'
          	}//end null check for NDC_Product_Vial_1_gne__c, NDC_Product_Vial_2_gne__c and NDC_Product_Vial_3_gne__c
        }//end for on case_id_map.get(ship.Case_shipment_gne__c).Shipments__r
        Upfront = Miligram_PT_tot_upf + Miligram_DE_upf - Miligram_CR_upf +calculate_returned_upf - Upfront_case_ship - Calculate_AL_upf - calculate_OH_upf ;
        Available_ship = Miligram_PT_tot_rep + Miligram_DE_rep - Miligram_CR_rep +calculate_returned_rep - replacement_case_ship - Calculate_AL_rep - calculate_OH_rep ;
    }//end block for Xolair       
        temp_set.add(Available_ship); temp_set.add(Upfront); temp_set.add(upfront_count); temp_set.add(upfront_flag);
        System.debug('temp_set==='+temp_set);
        case_calc.put(ship.case_shipment_gne__c, temp_set);        
  }//end null check for ship.Case_shipment_gne__c and product_catalog
}// end of try
  catch(exception e)
   {
   	ship.adderror('Error in calculation of Shipment balances!' +e.getmessage());
   	}
}//end for on Trigger.new

  for(shipment_gne__c ship: trigger.new)
   {
   	try
     { 
     	if(ship.case_shipment_gne__c!=null && case_calc.containskey(ship.case_shipment_gne__c) && case_id_map.containskey(ship.Case_shipment_gne__c) && product_catalog.size()>0)
        { 
        	Vial1=0; Vial2 =0; Vial3 =0; Quantity1 =0;Quantity2=0;Quantity3=0;
          if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Rituxan RA' ||
             case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Lucentis' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Avastin' || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Actemra'
                || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c ==TDM1_Product_Name
                || case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c =='Xolair')
            { 
            	for(integer i=0;i<product_catalog.size();i++)
               	{ 
               		if(product_catalog[i].NDC_Number_gne__c !=null && product_catalog[i].Vial_size_gne__c !=null)
                 		product_NDC.put(product_catalog[i].NDC_Number_gne__c, product_catalog[i].Vial_size_gne__c);
                 	if(ship.NDC_Product_Vial_1_gne__c !=null && product_catalog[i].NDC_Number_gne__c !=null)
                 	{  
                 		if(ship.NDC_Product_Vial_1_gne__c == product_catalog[i].NDC_Number_gne__c && product_catalog[i].Vial_size_gne__c !=null)
                    		Vial1 = product_catalog[i].Vial_size_gne__c;
                    }
             		if(ship.NDC_Product_Vial_2_gne__c !=null && product_catalog[i].NDC_Number_gne__c !=null )
             		{  
             			if(ship.NDC_Product_Vial_2_gne__c == product_catalog[i].NDC_Number_gne__c && product_catalog[i].Vial_size_gne__c !=null)
                			Vial2 = product_catalog[i].Vial_size_gne__c;
                	}
         			if(ship.NDC_Product_Vial_3_gne__c !=null && product_catalog[i].NDC_Number_gne__c !=null )
         			{  
         				if(ship.NDC_Product_Vial_3_gne__c == product_catalog[i].NDC_Number_gne__c && product_catalog[i].Vial_size_gne__c !=null)
            			Vial3 = product_catalog[i].Vial_size_gne__c;
            		}
                }//end for on product_catalog
           }//end check on product names
    //PR
    System.debug('#Vial1 size'+ Vial1 + '#Vial2 size'+ Vial2 + '#Vial3 size' + Vial3);
    //PR 
        if(ship.Quantity_1_gne__c !=null)
        	Quantity1 =  ship.Quantity_1_gne__c;
        if(ship.Quantity_2_gne__c !=null)
        	Quantity2 =  ship.Quantity_2_gne__c;
        if(ship.Quantity_3_gne__c !=null)
        	Quantity3 =  ship.Quantity_3_gne__c;
       if((case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case') || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan RA' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
        || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Avastin' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name !='C&R - Standard Case')
        || (case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == TDM1_Product_Name && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name !='C&R - Standard Case'))
        {
        	if(Vial1 ==0 || Vial2 ==0)
         		ship.adderror('Either Vial size / NDC number for vials of product '+ case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c+' in Product catalog is null/zero or Error in extracting vial size from Product catalog. Please contact Administrator');
         	
         	return_qty1 =0; return_qty2 =0; vial_low =0; ship_round =0; Ship_calc =0; 
         	Available_ship = case_calc.get(ship.case_shipment_gne__c)[0];
         	Ship_calc = Available_ship;
         	Upfront = case_calc.get(ship.case_shipment_gne__c)[1];
	        upfront_count = case_calc.get(ship.case_shipment_gne__c)[2];
	        upfront_flag = case_calc.get(ship.case_shipment_gne__c)[3];
	        if(Ship_calc>0)
	        {  
	        	if(vial1>vial2)
	           		vial_low = vial2;
	            else
	            	vial_low = vial1;
	            	Ship_calc =  Ship_calc / vial_low; Ship_round = Math.ceil(Ship_calc);  Ship_calc = Ship_round * vial_low;
	            while(Ship_calc>0)
	            {   
	            	if(Ship_calc >= Vial2)
	                {   
	                	Ship_calc = Ship_calc-Vial2;return_qty2 = return_qty2 +1;
	                }
	                else if(Ship_calc < Vial2)
	                {
	                	if(Ship_calc >= Vial1)
	                    {   
	                    	Ship_calc = Ship_calc-Vial1; return_qty1 = return_qty1 +1;
	                    }
	                    else if(Ship_calc < Vial1)
	                    {   
	                    	return_qty1 = return_qty1 +1;
	                        break;
	                    }                           
	                }                       
	            }//end while on ship_cal
	        }//end if on ship_cal
	        
	        if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan')
	        {   
	        	if(ship.Action_gne__c == 'GATCF Pretreatment' && Upfront <0 && upfront_flag ==1 && upfront_count >=2)
	            	ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');
	            if(ship.Action_gne__c == 'GATCF Replacement (Onc)' && Available_ship!=0 && (return_qty1*Vial1+ return_qty2*Vial2) < (Quantity1*Vial1+ Quantity2*Vial2))
	            	ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
	        }//end check for Rituxan
	        if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Rituxan RA')
	        {   
	        	if(ship.Action_gne__c == 'GATCF Upfront' && Upfront <0 && upfront_flag ==1 && upfront_count >=2 )
	            	ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');
	            if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && (return_qty1*Vial1+ return_qty2*Vial2) < (Quantity1*Vial1+ Quantity2*Vial2))
	            	ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
	        }//end check for Rituxan RA
	        if((case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Avastin' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name !='C&R - Standard Case'))
	        {   
	          if((ship.Action_gne__c == 'GATCF Pretreatment' || ship.Action_gne__c == 'Clinical' || ship.Action_gne__c == 'APA Program') && Upfront <0 && upfront_flag ==1 && upfront_count >=2 )
	              ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');              
	            if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && (return_qty1*Vial1+ return_qty2*Vial2) < (Quantity1*Vial1+ Quantity2*Vial2))
	              ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
	        }//end check for Avastin                   
    }//end check on product names
    else if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Lucentis' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    { 
    	if(Vial1 ==0)
      		ship.adderror('Either Vial size / NDC number for vials of product '+ case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c+' in Product catalog is null/zero or Error in extracting vial size from Product catalog. Please contact Administrator');
      	
      	return_qty1 =0; return_qty2 =0; vial_low =0; ship_round =0;
      	Available_ship = case_calc.get(ship.case_shipment_gne__c)[0];
	    Ship_calc = Available_ship;
	    if(Ship_calc>0)
	    { 
     	  while(Ship_calc>0)
          { 
          	if(Ship_calc >= Vial1)
             {
             	Ship_calc = Ship_calc - Vial1; return_qty1 = return_qty1 +1;
             }
            else if(Ship_calc < Vial1)
            {
            	return_qty1 = return_qty1 + 1;
             	break;
             }
          }//end while on ship_cal
        }//end if on ship_cal
      Upfront = case_calc.get(ship.case_shipment_gne__c)[1];
      upfront_count = case_calc.get(ship.case_shipment_gne__c)[2];
      upfront_flag = case_calc.get(ship.case_shipment_gne__c)[3];
      if(ship.Action_gne__c == 'GATCF Upfront' && Upfront <0 && upfront_flag ==1 && upfront_count >=2 )
	      ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');
      if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && return_qty1 < Quantity1 )
	      ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
    }//end block for Lucentis
    
    //KS:Pertuzumab Condition
    else if(case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == Pertuzumab_Product_Name && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')
    { 
      if(Vial1 ==0)
      	ship.adderror('Either Vial size / NDC number for vials of product '+ case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c+' in Product catalog is null/zero or Error in extracting vial size from Product catalog. Please contact Administrator');
      
      return_qty1 =0; return_qty2 =0; vial_low =0; ship_round =0;
      Available_ship = case_calc.get(ship.case_shipment_gne__c)[0];
      Ship_calc = Available_ship;
      if(Ship_calc>0)
       { 
       	  while(Ship_calc>0)
          { 
          	if(Ship_calc >= Vial1)
             {
             	Ship_calc = Ship_calc - Vial1; return_qty1 = return_qty1 +1;
             }
            else if(Ship_calc < Vial1)
            {
            	return_qty1 = return_qty1 + 1;
             	break;
             }
          }
        }//end if on ship_cal
      if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && return_qty1 < Quantity1 )
      	ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
    }//end block for Pertuzumab
    //KS:Condition ends here
    
    else if((case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Actemra' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')) 
    { 
    //PR
    System.debug('Vial1 size'+ Vial1 + 'Vial2 size'+ Vial2 + 'Vial3 size' + Vial3);
    //PR   
    if(Vial1 ==0 || Vial2 ==0 || Vial3 == 0)
      ship.adderror('Either Vial size / NDC number for vials of product '+ case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c+' in Product catalog is null/zero or Error in extracting vial size from Product catalog. Please contact Administrator');
      return_qty1 =0; return_qty2 =0; return_qty3 =0; ship_round =0; Ship_calc =0; 
      Available_ship = case_calc.get(ship.case_shipment_gne__c)[0]; Ship_calc = Available_ship;
      Upfront = case_calc.get(ship.case_shipment_gne__c)[1]; upfront_count = case_calc.get(ship.case_shipment_gne__c)[2];
      upfront_flag = case_calc.get(ship.case_shipment_gne__c)[3];
      if(Ship_calc>0)
       {
       	Ship_calc =  Ship_calc / vial1; Ship_round = Math.ceil(Ship_calc); Ship_calc = Ship_round * vial1;
        while(Ship_calc>0)
         { 
         	if(Ship_calc >= Vial3)
           { 
           		Ship_calc = Ship_calc-Vial3; return_qty3 = return_qty3 +1;
           	}
           else
           { 
	           	if(Ship_calc >= Vial2)
	             { 
	             	Ship_calc = Ship_calc-Vial2; return_qty2 = return_qty2 +1;
	             } 
	             else if(Ship_calc < Vial2)
	             { 
	             	if(Ship_calc >= Vial1)
	               	{
	               		Ship_calc = Ship_calc-Vial1; return_qty1 = return_qty1 +1;
	               	}
	               else if(Ship_calc < Vial1)
	               {
	               		return_qty1 = return_qty1 +1;
	                	break;
	                }                           
	             }//end check on Ship_calc<Vial2
            }//end if-else on Ship_calc>=Vial3                     
          }//end while on Ship_calc
       }//end if on Ship_calc
       
    if(ship.Action_gne__c == 'GATCF Upfront' && Upfront <0 && upfront_flag ==1 && upfront_count >=2 )
    	ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');
    if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && (return_qty1*Vial1+ return_qty2*Vial2+ return_qty3*Vial3) < (Quantity1*Vial1+ Quantity2*Vial2+ Quantity3*Vial3))
    	ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
  }//end block for Actemra

  //PK 12/03/2013 for Xolair PFS-966
  else if((case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c == 'Xolair' && case_id_map.get(ship.Case_shipment_gne__c).recordtype.name =='GATCF - Standard Case')) 
    { 
    
    System.debug('Vial1 size1---'+ Vial1 + '---Vial2 size----'+ Vial2 + '----Vial3 size----' + Vial3);
    
    if(Vial1 ==0)
      ship.adderror('Either Vial size / NDC number for vials of product '+ case_id_map.get(ship.Case_shipment_gne__c).Product_gne__c+' in Product catalog is null/zero or Error in extracting vial size from Product catalog. Please contact Administrator');
      
  	return_qty1 =0; return_qty2 =0; return_qty3 =0; ship_round =0; Ship_calc =0; 
  	Available_ship = case_calc.get(ship.case_shipment_gne__c)[0]; 
  	Ship_calc = Available_ship;
  	Upfront = case_calc.get(ship.case_shipment_gne__c)[1]; 
  	upfront_count = case_calc.get(ship.case_shipment_gne__c)[2];
  	upfront_flag = case_calc.get(ship.case_shipment_gne__c)[3];
	if(Ship_calc>0)
    {
    	Ship_calc =  Ship_calc / vial1; 
    	Ship_round = Math.ceil(Ship_calc); 
    	Ship_calc = Ship_round * vial1;
        List<Integer> lst = GNE_CM_CalculateInfusioncounts.calculateVialQuantitiesSingleVial(Ship_calc, vial1);
        return_qty1= lst[0];
    }//end if on Ship_calc
	
	System.debug('ship.Action_gne__c====='+ship.Action_gne__c+'====xolair upfront flag======'+upfront_flag+'====upfront count======'+upfront_count);       
    if(ship.Action_gne__c == 'GATCF Shipment' && Upfront <0 && upfront_flag ==1 && upfront_count >=1 )
    	ship.adderror('Upfront balance is negative and thus this upfront shipment cannot be created');
    if(ship.Action_gne__c == 'GATCF Replacement' && Available_ship!=0 && (return_qty1*Vial1) < (Quantity1*Vial1))
    	ship.adderror('The total mgs of this shipment exceeds Available to ship and thus this replacement shipment cannot be created');
  }//end block for Xolair

 }//end check on ship.Case_shipment_gne__c and product_catalog        
}
	catch(exception e)
	{
		ship.adderror('Error in processing shipment trigger records'+e.getmessage());
	}
 }//end for on Trigger.new
 
}