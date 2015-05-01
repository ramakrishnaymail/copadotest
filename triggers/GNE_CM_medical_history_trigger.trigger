// Developed By: GDC
// Last Updated: 11/03/2008
//Last Modified on 3/3/2009 - Quantity stamping for Tarceva should be done only when all 3 qty fields are null
// KM - 09/30/09 - Actemra - Modified for adding the calculation of Quantity fields for Actemra based on Dosage
// Added line # 58 - 62 and 123 - 188
// KM - 05/04/10 - Pegasys - Modified for adding the calculation of Rx Expiration & Rx Refill Expiration Date
// adamb - 8/19/10 - T-435 - Fix to allow optimal dosage of Actemra
//Shwetab - 4/13/2011 - Added Rx Expiration calculation logic for BRAF
//KS - 10/17/2011 - Added Rx Expiration calculation logic for VISMODEGIB
trigger GNE_CM_medical_history_trigger on Medical_History_gne__c (before insert, before update) 
{
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    String Status;
    Map<Integer, Integer> Sizes=new Map<Integer, Integer>{1=> 150, 2=> 100, 3=> 25};
    Integer remaining_val;double remaining_val_act1;double remaining_val_act2;Integer wasted_val;Integer x150_val;Integer x100_val;  
    Integer x25_val;Integer x400_val=0;Integer x200_val=0;Integer x80_val=0;Integer Dispense_month=0;Integer Starter_freq_admin=0;double subq_freq_admin=0;
    Set<ID> setID=new Set<ID>();
    Id prev_rt_id;Set<ID> updateID=new Set<ID>();Map<id,Case> Case_map;
    List<case> case_id=new List<case>();
    Map<Id, Medical_History_gne__c> Med_hist=new Map<Id, Medical_History_gne__c>();
    List<String> result=new List<String>();double qtyvals=0;
    List<GroupMember> lstuserid=new List<GroupMember> ();
    Set<ID> userid_set=new Set<ID>();
    string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
    //PR: commented to deploy pegasys line indication changes.
    //KS: VISMO: 11/24/2011
    string vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    Group Clinical_id;Id currentuserid;
    integer Starter_Frequency;
    String cobi_product_name = system.label.GNE_CM_Cotellic_Product_Name;
    String boomerang_product_name = system.label.GNE_CM_Boomerang_Product_Name;
    try
       {    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1()) // Global check for static variable to make sure trigger executes only once
            {
                //This trigger will only execute if static variable is not set
                GNE_CM_case_trigger_monitor.setTriggerInProcessTrig1(); // Setting the static variable so that this trigger does not get executed after workflow update
                //******* Changes as per req-340*****//
                currentuserid=UserInfo.getUserId();
                lstuserid=[Select UserOrGroupId from GroupMember where Group.Name='GNE-CM-Clinical-Appeals-Specialist'];
                if(lstuserid!=null)
                {
                
                  for(integer l=0; l < lstuserid.size(); l++)
                    {
                          userid_set.add(lstuserid[l].UserOrGroupId ); 
                    }
                 }
                //****** PORTAL SECTION BEGINS HERE ******//
                for (Medical_History_gne__c Medical_Rec : trigger.new)
                {
                    If (Medical_Rec.GATCFSMN_Expiration_Flag_gne__c == False) 
                    {   
                        Medical_Rec.GATCFSMN_Expiration_Flag_gne__c = True;
                        If (system.trigger.isupdate && Medical_Rec.GATCF_SMN_Expiration_Date_gne__c != trigger.OldMap.get(Medical_Rec.Id).GATCF_SMN_Expiration_Date_gne__c)
                        {   
                            //********************************************************************************************************//
                            system.debug ('**************** SENSING CHANGE IN GATCF SMN Expiration Date ****************');//
                            //********************************************************************************************************//
                        }
                        else if (system.trigger.isinsert)
                        {
                            Medical_Rec.GATCFSMN_Expiration_Flag_gne__c = True;
                        }
                    }
                    if (Medical_Rec.RX_Expiration_Flag_gne__c == False) 
                    {   
                        Medical_Rec.RX_Expiration_Flag_gne__c = True;
                        If (system.trigger.isupdate && Medical_Rec.RX_Expiration_gne__c != trigger.OldMap.get(Medical_Rec.Id).RX_Expiration_gne__c)
                        {   
                            //********************************************************************************************************//
                            system.debug ('**************** SENSING CHANGE IN RX Expiration Date ****************');//
                            //********************************************************************************************************//
                        }
                        else if (system.trigger.isinsert)
                        {   
                            Medical_Rec.RX_Expiration_Flag_gne__c = True;
                        }
                    }
                } 
                //**** PORTAL SECTION ENDS HERE****//
                //**************** Get listing of recordtypes ***************//
                //**************** Get listing of medical history maps ******//
                Status='Get listing of medical history maps';
                
                for (Medical_History_gne__c medical_RTs : trigger.new)
                {     if (medical_RTs.RecordTypeId!=null && prev_rt_id!=medical_RTs.RecordTypeId)
                        {setID.add(medical_RTs.RecordTypeId);}
                        if (system.trigger.isupdate)
                        {
                            Med_hist.put(medical_RTs.Id, medical_RTs);
                            system.debug('Medical value......'+Med_hist);
                        }               
                }
                //******* Perform calculations for Tarceva *******//
                Status='Get Recordtypes for selective logic implementation';  
                Map<Id, RecordType> mrt=new Map<Id, RecordType>([Select Id, Name from RecordType where ID IN :setID]);
                Status='Loop through Trigger.New to calculate Tarceva dosage'; 
                Integer i=0; 
                try
                {   
                    for (i=0; i < trigger.new.size(); i++)
                    {     
                      //Stamp MH record type on MH Product field
                      trigger.new[i].Product_gne__c = mrt.get(trigger.new[i].RecordTypeId).Name;

                      //dso: Start -- Actemra SubQ changes
                      if (mrt.get(trigger.new[i].RecordTypeId).Name=='Actemra Subcutaneous') 
                      {
                        if (trigger.new[i].Dispense_gne__c == '1 Month')
                            Dispense_month = 1;
                        else if (trigger.new[i].Dispense_gne__c == '2 Month')
                            Dispense_month = 2;
                        else if (trigger.new[i].Dispense_gne__c == '3 Month')
                            Dispense_month = 3;
                                        
                        if (trigger.new[i].Starter_Frequency_of_Administration_gne__c == 'Once a week')
                            Starter_freq_admin = 2;
                        else if (trigger.new[i].Starter_Frequency_of_Administration_gne__c == 'Once every 2 weeks')
                            Starter_freq_admin = 1;

                        if (trigger.new[i].Frequency_of_Admin_actemra_subq_gne__c == 'Once a week')
                            subq_freq_admin = 4;
                        else if (trigger.new[i].Frequency_of_Admin_actemra_subq_gne__c == 'Once every 2 weeks')
                            subq_freq_admin = 2;

                        for (integer x=0; x < trigger.new.size(); x++)
                        { 
                            if (trigger.new[i].Frequency_of_Admin_actemra_subq_gne__c == 'Other' && trigger.new[i].Other_Administration_Location_gne__c == null)
                            {
                                trigger.new[x].adderror('Other is required if Frequency of Administration is Other');
                            }                             
                            if (trigger.new[i].Dispense_gne__c == 'Other' && trigger.new[i].Dispense_Other_BRAF_gne__c == null)
                            {
                                trigger.new[x].adderror('Dispense Other is required if Dispense is Other');
                            }  
                            if(trigger.new[i].Frequency_of_Admin_actemra_subq_gne__c != 'Other' && trigger.new[i].Dispense_gne__c != 'Other')     
                            {                      
                               trigger.new[i].Qty_162_mg_actemra_subq_gne__c = null;
                            }
                            if (subq_freq_admin > 0 && (trigger.new[i].Dispense_gne__c != 'Other' || trigger.new[i].Dispense_gne__c == null))
                            {
                                trigger.new[i].Qty_162_mg_actemra_subq_gne__c = subq_freq_admin * Dispense_month;
                            }                                               
                            trigger.new[i].Vial_Qty_gne__c = null;
                            if (Starter_freq_admin > 0)
                            {
                                trigger.new[i].Vial_Qty_gne__c = Starter_freq_admin;
                            }                                               
                        }
                    } // end of Actemra SubQ logic

                        //******Changes as per req-340*******//
                     if(system.trigger.isupdate) 
                      {
                        if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&!userid_set.contains(currentuserid) && System.trigger.oldMap.get(trigger.new[i].id).Clinical_Nurse_Approved__c!=trigger.new[i].Clinical_Nurse_Approved__c )   
                             {         
                                        
                                trigger.new[i].adderror('User does not have  privileges to update Clinical Nurse Approved flag');
                             }
                       if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&( System.trigger.oldMap.get(trigger.new[i].id).ICD9_Code_1_gne__c!=trigger.new[i].ICD9_Code_1_gne__c  || System.trigger.oldMap.get(trigger.new[i].id).ICD9_Code_2_gne__c!=trigger.new[i].ICD9_Code_2_gne__c ||  System.trigger.oldMap.get(trigger.new[i].id).ICD9_Code_3_gne__c!=trigger.new[i].ICD9_Code_3_gne__c))              
                            {
                                
                                   trigger.new[i].Clinical_Nurse_Approved__c=FALSE;
                            }
                       if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&( System.trigger.oldMap.get(trigger.new[i].id).Sig_Mg_SubQ_gne__c!=trigger.new[i].Sig_Mg_SubQ_gne__c &&  trigger.new[i].Sig_Mg_SubQ_gne__c > 1))              
                           {
                              trigger.new[i].Clinical_Nurse_Approved__c=FALSE;
                           } 
                       }
                     if(system.trigger.isinsert)   
                     {
                     if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&!userid_set.contains(currentuserid) && trigger.new[i].Clinical_Nurse_Approved__c==True)   
                             {         
                                          
                                trigger.new[i].adderror('User does not have privileges to update Clinical Nurse Approved flag');
                             }
                      if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&(  trigger.new[i].ICD9_Code_1_gne__c!=null ||  trigger.new[i].ICD9_Code_2_gne__c!=null ||   trigger.new[i].ICD9_Code_3_gne__c!=null))              
                            {
                                 trigger.new[i].Clinical_Nurse_Approved__c=FALSE;
                            }
                       if (mrt.get(trigger.new[i].RecordTypeId).Name=='Nutropin' &&(  trigger.new[i].Sig_Mg_SubQ_gne__c!=null&&  trigger.new[i].Sig_Mg_SubQ_gne__c > 1))              
                           {
                              trigger.new[i].Clinical_Nurse_Approved__c=FALSE;
                           } 
                       }
        
                        if (mrt.get(trigger.new[i].RecordTypeId).Name=='Tarceva')
                        {   // KM - 09/30/09 - Actemra: Added the following If loop for the bulk load of MH records when first MH is Actemra and then Tarceva.
                            if(sizes.size() > 0)
                            {
                                sizes.clear();
                                Sizes.put(1, 150); Sizes.put(2,100); sizes.put(3,25);
                            } // end of if
                            if (trigger.new[i].Dosage_mg_gne__c!=null )        
                            {   
                                qtyvals=(trigger.new[i].X150_mg_Qty_gne__c==null? 0 : trigger.new[i].X150_mg_Qty_gne__c) + (trigger.new[i].X100_mg_Qty_gne__c==null? 0 : trigger.new[i].X100_mg_Qty_gne__c) + (trigger.new[i].X25_mg_Qty_gne__c==null? 0 : trigger.new[i].X25_mg_Qty_gne__c);                 
                                                      
                                if( trigger.new[i].Dosage_mg_gne__c!=0 && qtyvals==0)
                                {
                                    trigger.new[i].X150_mg_Qty_gne__c=0;
                                    trigger.new[i].X100_mg_Qty_gne__c=0;
                                    trigger.new[i].X25_mg_Qty_gne__c=0;
                                    Status='Calc for value > 150';
                                    
                                    if (Math.round(trigger.new[i].Dosage_mg_gne__c) >=Sizes.get(1))  //Start 1
                                    {
                                        remaining_val=math.mod(Math.round(trigger.new[i].Dosage_mg_gne__c), Sizes.get(1));
                                        x150_val=Math.round(trigger.new[i].Dosage_mg_gne__c) / Sizes.get(1); 
                                        trigger.new[i].X150_mg_Qty_gne__c=x150_val;
                                
                                        if (remaining_val >=Sizes.get(2))
                                        {
                                            x100_val=remaining_val / Sizes.get(2);
                                            trigger.new[i].X100_mg_Qty_gne__c=x100_val;
                                            remaining_val=math.mod(remaining_val, Sizes.get(2));
                                    
                                            if (remaining_val >=Sizes.get(3))
                                            {
                                                x25_val=remaining_val / Sizes.get(3);
                                                trigger.new[i].X25_mg_Qty_gne__c=x25_val;
                                            }
                                        }
                                        else if (remaining_val >=Sizes.get(3))
                                        {
                                            x25_val=remaining_val / Sizes.get(3);
                                            trigger.new[i].X25_mg_Qty_gne__c=x25_val;
                                        }
                                    } //End 1
                            
                                    else if (Math.round(trigger.new[i].Dosage_mg_gne__c) >=Sizes.get(2))
                                    {
                                        Status='Calc for value > 100';
                                        remaining_val=math.mod(Math.round(trigger.new[i].Dosage_mg_gne__c), Sizes.get(2));
                                        x100_val=Math.round(trigger.new[i].Dosage_mg_gne__c) / Sizes.get(2);
                                        trigger.new[i].X100_mg_Qty_gne__c=x100_val;
                                
                                        if (remaining_val >=Sizes.get(3))
                                        {
                                            x25_val=remaining_val / Sizes.get(3);
                                            trigger.new[i].X25_mg_Qty_gne__c=x25_val;
                                        }
                                    }
                                    
                                    else if (Math.round(trigger.new[i].Dosage_mg_gne__c) >=Sizes.get(3))
                                    {
                                        system.debug('----------------Before Exception');
                                        Status='Calc for value > 25';
                                        system.debug('----------------After Exception');
                                        x25_val=Math.round(trigger.new[i].Dosage_mg_gne__c) / Sizes.get(3);
                                        trigger.new[i].X25_mg_Qty_gne__c=x25_val;
                                        system.debug('---------------->trigger.new[i].X25_mg_Qty_gne__c'+trigger.new[i].X25_mg_Qty_gne__c);
                                    }
                                    
                                   
                                }
                            }
                            //AS: TARCEVA 06/04/2012
                            qtyvals = 0;
                            Map<String, Double> Freq_Of_Admin_Map = new Map<String, Double>{'QD'=> 1.0, 'BID'=>2.0, 'TID'=>3.0, 'QID'=>4.0};
                            integer Starter_Dispense = 0;
                            double Freq_Admin = 0.0;
                            if(trigger.new[i].Starter_Frequency_of_Administration_gne__c != null)
                                Freq_Admin = Freq_Of_Admin_Map.get(trigger.new[i].Starter_Frequency_of_Administration_gne__c);
                            if(trigger.new[i].Starter_Dispense_gne__c != null)
                                Starter_Dispense = integer.valueOf(trigger.new[i].Starter_Dispense_gne__c);
                            qtyvals=(trigger.new[i].X150mg_Total_Number_of_Tablets_gne__c==null? 0 : trigger.new[i].X150mg_Total_Number_of_Tablets_gne__c) + (trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c==null? 0 : trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c) + (trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c==null? 0 : trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c);
                            if(trigger.new[i].Starter_Dosage_gne__c != 'Other' && trigger.new[i].Starter_Dosage_gne__c != '--None--' && trigger.new[i].Starter_Dosage_gne__c != '')
                            {
                                if(trigger.new[i].Starter_Dosage_gne__c == '150' && qtyvals == 0)
                                    trigger.new[i].X150mg_Total_Number_of_Tablets_gne__c = (150*Freq_Admin*Starter_Dispense)/150;
                                else if(trigger.new[i].Starter_Dosage_gne__c == '100' && qtyvals == 0)
                                    trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c = (100*Freq_Admin*Starter_Dispense)/100;   
                            }
                            else if(trigger.new[i].Starter_Dosage_gne__c == 'Other' && trigger.new[i].Starter_Dispense_gne__c != null && trigger.new[i].Starter_Frequency_of_Administration_gne__c != null)
                            {
                                if(trigger.new[i].Starter_Other_gne__c != null && qtyvals == 0)
                                {
                                    trigger.new[i].X150mg_Total_Number_of_Tablets_gne__c=0;
                                    trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c=0;
                                    trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c=0;
                                    Status='Calc for value > 150';
                                    x150_val = x100_val = x25_val = 0;
                                    
                                    if (Math.round(trigger.new[i].Starter_Other_gne__c) >= Sizes.get(1))  //Start 1
                                    {
                                        remaining_val = math.mod(Math.round(trigger.new[i].Starter_Other_gne__c), Sizes.get(1));
                                        x150_val = Math.round(trigger.new[i].Starter_Other_gne__c) / Sizes.get(1);
                                        trigger.new[i].X150mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*(x150_val);
                                
                                        if (remaining_val >= Sizes.get(2))
                                        {
                                            x100_val = remaining_val / Sizes.get(2);
                                            trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*( x100_val);
                                            remaining_val = math.mod(remaining_val, Sizes.get(2));
                                    
                                            if (remaining_val >= Sizes.get(3))
                                            {
                                                x25_val = remaining_val / Sizes.get(3);
                                                trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*(x25_val);
                                            }
                                        }
                                        else if (remaining_val > = Sizes.get(3))
                                        {
                                            x25_val=remaining_val / Sizes.get(3);
                                            trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*(x25_val);    
                                        }
                                    } //End 1
                            
                                    else if (Math.round(trigger.new[i].Starter_Other_gne__c) >= Sizes.get(2))
                                    {
                                        Status='Calc for value > 100';
                                        remaining_val = math.mod(Math.round(trigger.new[i].Starter_Other_gne__c), Sizes.get(2));
                                        x100_val = Math.round(trigger.new[i].Starter_Other_gne__c) / Sizes.get(2);
                                        trigger.new[i].X100mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*( x100_val);
                                
                                        if (remaining_val >=Sizes.get(3))
                                        {
                                            x25_val=remaining_val / Sizes.get(3);
                                            trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*(x25_val);
                                        }
                                    }
                                    
                                    else if (Math.round(trigger.new[i].Starter_Other_gne__c) >= Sizes.get(3))
                                    {
                                        Status='Calc for value > 25';
                                        x25_val=Math.round(trigger.new[i].Starter_Other_gne__c) / Sizes.get(3);
                                        trigger.new[i].X25mg_Total_Number_of_Tablets_gne__c = (Freq_Admin*Starter_Dispense)*(x25_val);
                                    }
                                    
                                }
                            }
                            //End AS: TARCEVA
                        }
                        
                        // KM - 3/30/09 - Actemra - Added for calculation of Quantity fields for Actemra
                        else if (mrt.get(trigger.new[i].RecordTypeId).Name=='Actemra')
                        {
                            Status='Loop through Trigger.New to calculate Actemra dosage';  
                            Sizes.clear();
                            system.debug('Sizes ' + Sizes);
                            Sizes.put(1, 400); Sizes.put(2,200); sizes.put(3,80);
                            //Sizes.put{1=> 400, 2=> 200, 3=> 80});
                            if (trigger.new[i].Dosage_mg_gne__c!=null )        
                            {   
                                qtyvals=(trigger.new[i].Quantity_of_80mg_Vials_gne__c==null? 0 : trigger.new[i].Quantity_of_80mg_Vials_gne__c) + (trigger.new[i].Quantity_of_200mg_Vials_gne__c==null? 0 : trigger.new[i].Quantity_of_200mg_Vials_gne__c) + (trigger.new[i].Quantity_of_400mg_Vials_gne__c==null? 0 : trigger.new[i].Quantity_of_400mg_Vials_gne__c);      
                                if( trigger.new[i].Dosage_mg_gne__c!=0 && qtyvals==0)
                                {
                                    trigger.new[i].Quantity_of_80mg_Vials_gne__c=0;
                                    trigger.new[i].Quantity_of_200mg_Vials_gne__c=0;
                                    trigger.new[i].Quantity_of_400mg_Vials_gne__c=0;
                                    //adamb - 8/19/10 - T-435 - Fix to allow optimal dosage of Actemra 
                                    x80_val = 0;
                                    x200_val = 0;
                                    x400_val = 0;
                                    
                                    x80_val = (trigger.new[i].Dosage_mg_gne__c/Sizes.get(3)).intValue();
                                    if ((Sizes.get(3)*x80_val - trigger.new[i].Dosage_mg_gne__c) != 0 )
                                    {
                                        x80_val = x80_val + 1;
                                        remaining_val_act1 = x80_val*Sizes.get(3)-trigger.new[i].Dosage_mg_gne__c;
                                        if(x80_val >= 3)
                                        {
                                            remaining_val_act2 = ((x80_val-3)*Sizes.get(3) + Sizes.get(2))-trigger.new[i].Dosage_mg_gne__c;
                                            if (remaining_val_act2 >= 0 && remaining_val_act2<remaining_val_act1)
                                            {
                                                x80_val = x80_val-3;
                                                x200_val = 1;
                                            }
                                        }
                                    }
                                    if(x80_val >= 5)
                                    {
                                        x400_val = (x80_val/5.0).intValue();
                                        if (x400_val > 0 )
                                        {
                                            x80_val = x80_val-x400_val*5;
                                        }
                                    }
                                    trigger.new[i].Quantity_of_80mg_Vials_gne__c=x80_val;
                                    trigger.new[i].Quantity_of_200mg_Vials_gne__c=x200_val;
                                    trigger.new[i].Quantity_of_400mg_Vials_gne__c=x400_val;
                                } // End of if(trigger.new[i].Dosage_mg_gne__c!=0 && qtyvals==0)
                            } // end of Dosage!=null
                        } // End of Else if Actemra
                        else if (mrt.get(trigger.new[i].RecordTypeId).Name=='TNKase' &&  trigger.new[i].Vial_Size_gne__c!= null)
                        {
                            Status='Calculating Dosage :: TNKase';
                            String vial_size=trigger.new[i].Vial_Size_gne__c;
                            Pattern pt=Pattern.compile('m*g');
                            Matcher mat=pt.matcher(vial_size.Trim());
                            if (mat.replaceAll('')!=null && trigger.new[i].Vial_Qty_gne__c!=null)
                            {
                                String mat_vial_size=mat.replaceAll('');
                                trigger.new[i].Dosage_mg_gne__c=Double.ValueOf(mat_vial_size.Trim()) * trigger.new[i].Vial_Qty_gne__c;
                            }
                        }
                    else if (mrt.get(trigger.new[i].RecordTypeId).Name=='Activase' && trigger.new[i].Vial_Size_gne__c!=null && trigger.new[i].Dosage_mg_gne__c==null)
                        {
                            Status='Calculating Dosage :: Activase';
                            String vial_size=trigger.new[i].Vial_Size_gne__c;
                            Pattern pt=Pattern.compile('m*g');
                            Matcher mat=pt.matcher(vial_size.Trim());
                            String mat_vial_size=mat.replaceAll('');
                            if (mat_vial_size.Trim()=='50')
                            {
                                trigger.new[i].Dosage_mg_gne__c=Double.ValueOf(mat_vial_size.Trim());
                            }
                            else if (mat_vial_size.Trim()=='100')
                            {
                                trigger.new[i].Dosage_mg_gne__c=Double.ValueOf(mat_vial_size.Trim());
                            }
                            else if (mat_vial_size.Trim()=='2')
                            {
                                trigger.new[i].Dosage_mg_gne__c=Double.ValueOf(mat_vial_size.Trim());
                            }
                        }
                        
                        // DP - 01/27/10 - Xeloda - Added for calculation of Quantity fields for Actemra
                        else if (mrt.get(trigger.new[i].RecordTypeId).Name=='Xeloda')
                        {
                            Status='Loop through Trigger.New to calculate Xeloda dosage';  
                            Sizes.clear();
                            
                            if(trigger.new[i].CM_150mg_Total_tablets_per_cycle_gne__c==null || trigger.new[i].CM_150mg_Total_tablets_per_cycle_gne__c==0){
                                
                                Integer tablem150mg   =(trigger.new[i].CM_150mg_tablets_gne__c==null ? 0 : Integer.valueOf(trigger.new[i].CM_150mg_tablets_gne__c));
                                Integer timesPerDay150mg  =(trigger.new[i].CM_150mg_times_per_day_gne__c==null ? 0 : Integer.valueOf(trigger.new[i].CM_150mg_times_per_day_gne__c));
                                Integer daysOn150mg       =(trigger.new[i].CM_150mg_of_days_on_gne__c==null ? 0 : trigger.new[i].CM_150mg_of_days_on_gne__c.intValue());
                                
                                trigger.new[i].CM_150mg_Total_tablets_per_cycle_gne__c=tablem150mg * timesPerDay150mg * daysOn150mg;
                            }
                            
                            if(trigger.new[i].CM_500mg_Total_tablets_per_cycle_gne__c==null || trigger.new[i].CM_500mg_Total_tablets_per_cycle_gne__c==0){
                                
                                Integer tablem500mg   =(trigger.new[i].CM_500mg_tablets_gne__c==null ? 0 : Integer.valueOf(trigger.new[i].CM_500mg_tablets_gne__c));
                                Integer timesPerDay500mg  =(trigger.new[i].CM_500mg_times_per_day_gne__c==null ? 0 : Integer.valueOf(trigger.new[i].CM_500mg_times_per_day_gne__c));
                                Integer daysOn500mg       =(trigger.new[i].CM_500mg_of_days_on_gne__c==null ? 0 : trigger.new[i].CM_500mg_of_days_on_gne__c.intValue());
                                
                                trigger.new[i].CM_500mg_Total_tablets_per_cycle_gne__c=tablem500mg * timesPerDay500mg * daysOn500mg;
                            }
                            
                        }
                        
                        // DP - 05/04/10 - Pegasys - Added for calculation of Rx Expiration & Rx Refill Expiration Date and to add validation
                        else if (mrt.get(trigger.new[i].RecordTypeId).Name=='Pegasys')
                        {
                            Status='Loop through Trigger.New to calculate Pegasys dosage';  
                            Sizes.clear();
                            
                           if(trigger.new[i].Dose_mg_kg_wk_gne__c!=null && trigger.new[i].Dose_mg_kg_wk_gne__c > 0 && trigger.new[i].Rx_Date_gne__c!=null)
                            {  
                             if(trigger.new[i].Rx_Expiration_gne__c ==null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c))
                                   trigger.new[i].Rx_Expiration_gne__c=trigger.new[i].Rx_Date_gne__c.addYears(1);
                            }
                                
                           try{
                                if(trigger.new[i].RefillX_PRN_gne__c!=null && trigger.new[i].RefillX_PRN_gne__c!='')
                                    Integer t=Integer.valueOf(trigger.new[i].RefillX_PRN_gne__c);
                                if(trigger.new[i].Rx_Date_gne__c!=null && trigger.new[i].Dispense_gne__c!=null && trigger.new[i].RefillX_PRN_gne__c!=null && trigger.new[i].RefillX_PRN_gne__c!='')
                                {   if(trigger.new[i].Rx_Refill_Expiration_Date1_gne__c==null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c)
                                    || (System.trigger.isupdate && trigger.new[i].Dispense_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_gne__c) 
                                    || (System.trigger.isupdate && trigger.new[i].RefillX_PRN_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).RefillX_PRN_gne__c))
                                        
                                        trigger.new[i].Rx_Refill_Expiration_Date1_gne__c=trigger.new[i].Rx_Date_gne__c.addDays(Integer.valueOf(trigger.new[i].Dispense_gne__c.subString(0, 1)) * 28 *(Integer.valueOf(trigger.new[i].RefillX_PRN_gne__c)+ 1));
                                }
                            }catch(Exception exc){
                                trigger.new[i].RefillX_PRN_gne__c.addError('Please enter a valid number.');
                            }
                            
                            if(trigger.new[i].Dose_mg_kg_wk_Pegasys_1ml_gne__c  !=null && trigger.new[i].Dose_mg_kg_wk_Pegasys_1ml_gne__c    > 0 && trigger.new[i].Rx_Date_gne__c!=null)
                            {   if(trigger.new[i].Rx_Expiration_Pegasys_1ml_gne__c == null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c))
                                    trigger.new[i].Rx_Expiration_Pegasys_1ml_gne__c=trigger.new[i].Rx_Date_gne__c.addYears(1);
                            }
                            
                            try{
                                if(trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c!=null && trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c!='')
                                    Integer t=Integer.valueOf(trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c);
                                if(trigger.new[i].Rx_Date_gne__c!=null && trigger.new[i].Dispense_Pegasys_1ml_gne__c!=null && trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c!=null && trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c!='')
                                {   if(trigger.new[i].Rx_Refill_Expiration_Date2_gne__c == null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c)
                                    || (System.trigger.isupdate && trigger.new[i].Dispense_Pegasys_1ml_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_Pegasys_1ml_gne__c) 
                                    || (System.trigger.isupdate && trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).RefillX_PRN_Pegasys_1ml_gne__c))
                                        
                                        trigger.new[i].Rx_Refill_Expiration_Date2_gne__c=trigger.new[i].Rx_Date_gne__c.addDays(Integer.valueOf(trigger.new[i].Dispense_Pegasys_1ml_gne__c.subString(0, 1)) * 28 *(Integer.valueOf(trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c) + 1));
                                }
                            }catch(Exception exc){
                                trigger.new[i].RefillX_PRN_Pegasys_1ml_gne__c.addError('Please enter a valid number.');
                            }
                            
                            if(trigger.new[i].Dose_mg_kg_wk_Copegus_gne__c  !=null && trigger.new[i].Dose_mg_kg_wk_Copegus_gne__c > 0 && trigger.new[i].Rx_Date_gne__c!=null)
                            {   if(trigger.new[i].Rx_Expiration_Copegus_gne__c == null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c))
                                trigger.new[i].Rx_Expiration_Copegus_gne__c=trigger.new[i].Rx_Date_gne__c.addYears(1);
                            }
                            
                            try{
                                if(trigger.new[i].RefillX_PRN_Copegus_gne__c!=null && trigger.new[i].RefillX_PRN_Copegus_gne__c!='')
                                    Integer t=Integer.valueOf(trigger.new[i].RefillX_PRN_Copegus_gne__c);
                                if(trigger.new[i].Rx_Date_gne__c!= null && trigger.new[i].Dispense_Copegus_gne__c!=null && trigger.new[i].RefillX_PRN_Copegus_gne__c!=null && trigger.new[i].RefillX_PRN_Copegus_gne__c!='')
                                {   if(trigger.new[i].Rx_Refill_Expiration_Date3_gne__c == null || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c)
                                    || (System.trigger.isupdate && trigger.new[i].Dispense_Copegus_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_Copegus_gne__c) 
                                    || (System.trigger.isupdate && trigger.new[i].RefillX_PRN_Copegus_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).RefillX_PRN_Copegus_gne__c))
                                        
                                        trigger.new[i].Rx_Refill_Expiration_Date3_gne__c=trigger.new[i].Rx_Date_gne__c.addDays(Integer.valueOf(trigger.new[i].Dispense_Copegus_gne__c.subString(0, 1)) * 28 * (Integer.valueOf(trigger.new[i].RefillX_PRN_Copegus_gne__c)+ 1));
                                }
                            }catch(Exception exc){
                                trigger.new[i].RefillX_PRN_Copegus_gne__c.addError('Please enter a valid number.');
                            }
                            
                            if(trigger.new[i].Administration_Location_gne__c!=null && trigger.new[i].Administration_Location_gne__c.contains('Other') && trigger.new[i].Other_Administration_Location_gne__c==null)
                                trigger.new[i].Other_Administration_Location_gne__c.addError('Please enter value.');
                                
                            if(trigger.new[i].Who_will_administer_gne__c!=null && trigger.new[i].Who_will_administer_gne__c.contains('Other') && trigger.new[i].Other_Who_Will_Administer_gne__c==null)
                                trigger.new[i].Other_Who_Will_Administer_gne__c.addError('Please enter value.');
                            
                            if(trigger.new[i].Shipping_Location_gne__c!=null && trigger.new[i].Shipping_Location_gne__c.contains('Other (location)') && trigger.new[i].Other_Shipping_Location_gne__c==null)
                                trigger.new[i].Other_Shipping_Location_gne__c.addError('Please enter value.');  
                        }
                        // KS: VISMO: 11/24/2011: Added for VISMO in If condition
                        else if(mrt.get(trigger.new[i].RecordTypeId).Name==braf_product_name || mrt.get(trigger.new[i].RecordTypeId).Name== vismo_product_name || mrt.get(trigger.new[i].RecordTypeId).Name == cobi_product_name)
                        {
                            system.debug('inside mh trigger');
                            //if(trigger.new[i].Rx_Date_gne__c != null)
                            //trigger.new[i].Rx_Expiration_gne__c=trigger.new[i].Rx_Date_gne__c.addYears(1);
                            
                            //Calculation of Starter Rx Exp date and SMN Expt Date
                            if(mrt.get(trigger.new[i].RecordTypeId).Name == braf_product_name || mrt.get(trigger.new[i].RecordTypeId).Name == cobi_product_name)
                            {
                                if((trigger.new[i].Starter_SMN_Expiration_Date_gne__c==null && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null) || (System.trigger.isupdate && trigger.new[i].Starter_SMN_Effective_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Starter_SMN_Effective_Date_gne__c && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null))
                                trigger.new[i].Starter_SMN_Expiration_Date_gne__c = trigger.new[i].Starter_SMN_Effective_Date_gne__c.addYears(1);                       
                                if((trigger.new[i].Starter_Rx_Expiration_Date_gne__c==null && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null) || (System.trigger.isupdate && trigger.new[i].Starter_SMN_Effective_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Starter_SMN_Effective_Date_gne__c && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null))
                                trigger.new[i].Starter_Rx_Expiration_Date_gne__c = trigger.new[i].Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }
                            else if(mrt.get(trigger.new[i].RecordTypeId).Name == vismo_product_name)
                            {
                                if((trigger.new[i].Starter_Rx_Expiration_Date_gne__c==null && trigger.new[i].Rx_Date_gne__c != null) || (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c && trigger.new[i].Rx_Date_gne__c != null))
                                trigger.new[i].Starter_Rx_Expiration_Date_gne__c = trigger.new[i].Rx_Date_gne__c.addYears(1);
                                
                                //AS: Erivedge 05/23/2012
                                if((trigger.new[i].Starter_SMN_Expiration_Date_gne__c==null && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null) || (System.trigger.isupdate && trigger.new[i].Starter_SMN_Effective_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Starter_SMN_Effective_Date_gne__c && trigger.new[i].Starter_SMN_Effective_Date_gne__c != null))
                                trigger.new[i].Starter_SMN_Expiration_Date_gne__c=trigger.new[i].Starter_SMN_Effective_Date_gne__c.addYears(1);
                                //AS: Conditions End Here
                            }
                            
                            if(trigger.new[i].Starter_Rx_Expiration_Date_gne__c < = trigger.new[i].Starter_SMN_Effective_Date_gne__c)
                            trigger.new[i].Starter_Rx_Expiration_Date_gne__c.addError('Starter RX Expiration Date should be greater than Starter SMN Effective Date');
                            
                            //Calculation of Rx Refill Expiration Date
                            Integer Dispense_val;
                            if(trigger.new[i].Dispense_gne__c!= null && trigger.new[i].Dispense_gne__c != 'Other')
                            {
                                //Dispense_val=Integer.valueOf(trigger.new[i].Dispense_gne__c); //PS: 08/17/2012 Commented
                                 Dispense_val=Integer.valueOf(GNE_CM_MPS_Utils.getDispenseErivedge(trigger.new[i].Dispense_gne__c));//PS: 08/17/2012 Added                                                          
                            }
                            else if(trigger.new[i].Dispense_gne__c == 'Other' && trigger.new[i].Dispense_other_BRAF_gne__c != null)
                            {
                                Dispense_val = Integer.valueOf(trigger.new[i].Dispense_other_BRAF_gne__c);
                            }
                            
                            if(Dispense_val != null && trigger.new[i].Refill_s_BRAF_gne__c != null && trigger.new[i].Rx_Date_gne__c != null)
                            {   

                                if(trigger.new[i].Rx_Refill_Expiration_Date1_gne__c == null || (System.trigger.isupdate && (trigger.new[i].Dispense_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_gne__c || (trigger.new[i].Dispense_gne__c =='Other' && trigger.new[i].Dispense_other_BRAF_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_other_BRAF_gne__c)))
                                    || (System.trigger.isupdate && trigger.new[i].Refill_s_BRAF_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Refill_s_BRAF_gne__c) ||
                                    (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c)) 
                                {
                                        
                                    trigger.new[i].Rx_Refill_Expiration_Date1_gne__c = trigger.new[i].Rx_Date_gne__c.addDays(Dispense_val * (Integer.valueOf(trigger.new[i].Refill_s_BRAF_gne__c)+ 1));
                                }
                            }

                            //Cobi Rx Refill Expiration Date
                            if(mrt.get(trigger.new[i].RecordTypeId).Name == cobi_product_name && trigger.new[i].Refill_s_BRAF_gne__c != null && trigger.new[i].Rx_Date_gne__c != null) 
                            {
                                if(trigger.new[i].Dispense_gne__c =='Other') 
                                {
                                    trigger.new[i].Rx_Refill_Expiration_Date1_gne__c = trigger.new[i].Rx_Date_gne__c.addDays((Integer)((trigger.new[i].Dispense_Other_Cotellic_Days__c * Integer.valueOf(trigger.new[i].Refill_s_BRAF_gne__c)) + trigger.new[i].Dispense_Other_Cotellic_Days__c));
                                } 
                                else if(Dispense_val != null)
                                {
                                    trigger.new[i].Rx_Refill_Expiration_Date1_gne__c = trigger.new[i].Rx_Date_gne__c.addDays(Dispense_val * (Integer.valueOf(trigger.new[i].Refill_s_BRAF_gne__c)+ 1));
                                }
                            }
                                
                            // KS: Rx Refill Expiration Date Calculation for Vismo
                            if(Dispense_val != null && trigger.new[i].Refill_s_BRAF_gne__c != null && trigger.new[i].Rx_Date_gne__c != null)
                            {   
                                if(trigger.new[i].Rx_Refill_Expiration_Date1_gne__c == null || (System.trigger.isupdate && (trigger.new[i].Dispense_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_gne__c || (trigger.new[i].Dispense_gne__c =='Other' && trigger.new[i].Dispense_other_BRAF_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Dispense_other_BRAF_gne__c)))
                                || (System.trigger.isupdate && trigger.new[i].Refill_s_BRAF_gne__c!=System.Trigger.oldMap.get(trigger.new[i].Id).Refill_s_BRAF_gne__c) ||
                                (System.trigger.isupdate && trigger.new[i].Rx_Date_gne__c != System.Trigger.oldMap.get(trigger.new[i].Id).Rx_Date_gne__c))
                                    
                                trigger.new[i].Rx_Refill_Expiration_Date1_gne__c = trigger.new[i].Rx_Date_gne__c.addDays((Dispense_val * Integer.valueOf(trigger.new[i].Refill_s_BRAF_gne__c)) + Dispense_val);
                            }
                            //KS: Rx Refill Expiration Date Calculation for Vismo ends here
                           
                        }
                        //start Boomerang logic
                         else if(mrt.get(trigger.new[i].RecordTypeId).Name==Boomerang_product_name)
                        
                        {
                        	
                        //AB: all validations for product Boomerang consolidated in this section
                         if(trigger.new[i].Dispense_gne__c!= null && trigger.new[i].Dispense_gne__c == 'Other' && trigger.new[i].Dispense_other_BRAF_gne__c==null)
                          	trigger.new[i].Dispense_other_BRAF_gne__c.adderror('Dispense Other is required if Dispense equals Other');
                         	
                         	
                         if(trigger.new[i].Initial_Titration__c!= null && trigger.new[i].Initial_Titration__c == 'Other' && trigger.new[i].Sig_Other__c==null)
                          	trigger.new[i].Sig_Other__c.adderror('Sig (Other) is required if Initial Titration equals Other');
                         	
                         
                         if(((trigger.new[i].Initial_Titration__c!= null && trigger.new[i].Initial_Titration__c == 'Other') || 
                         	(trigger.new[i].dispense_gne__c!= null && trigger.new[i].dispense_gne__c == 'Other'))
                         	&& trigger.new[i].Number_Of_other_Tablets__c==null)
                          	trigger.new[i].Number_Of_other_Tablets__c.adderror('Number Of Other Tablets is required if Initial Titration or Dispense equals Other');
                          	
                         
                         if(trigger.new[i].Dispense_maintenance__c!= null && trigger.new[i].Dispense_maintenance__c == 'Other' && trigger.new[i].Dispense_Other_maintenance__c==null)
                          	trigger.new[i].Dispense_Other_maintenance__c.adderror('Dispense Other is required if Dispense equals Other');                         	
                         
                         
                         if(trigger.new[i].maintenance__c!= null && trigger.new[i].maintenance__c == 'Other' && trigger.new[i].Sig_Other_maintenance__c==null)
                          	trigger.new[i].Sig_Other_maintenance__c.adderror('Sig (Other) is required if Maintenance equals Other'); 
                          	 	
                         if(((trigger.new[i].maintenance__c!= null && trigger.new[i].maintenance__c == 'Other') ||
                          	(trigger.new[i].Dispense_maintenance__c!= null && trigger.new[i].Dispense_maintenance__c == 'Other'))
                        	 && trigger.new[i].Number_of_Other_tablets_maint__c==null)
                          	trigger.new[i].Number_of_Other_tablets_maint__c.adderror('Number Of Other Tablets is required if Maintenance or Dispense equals Other');   
                         
                         
                         if(trigger.new[i].Dispense_Other_maintenance__c!= null && trigger.new[i].Dispense_Other_maintenance__c > 0 && trigger.new[i].Dispense_Maintenance__c!='Other')
                          	trigger.new[i].Dispense_Other_maintenance__c.adderror('To enter a value here set the Dispense field value to Other');   
                          
                         if(trigger.new[i].Starter_Prescription_Type__c!= null && (trigger.new[i].Starter_Dispense_gne__c==null))
                          	trigger.new[i].Starter_Dispense_gne__c.adderror('Please enter value for Starter Dispense');   
                         
                          if(trigger.new[i].Starter_Prescription_Type__c!= null && (trigger.new[i].Starter_Dosage_gne__c==null))
                          	trigger.new[i].Starter_Dosage_gne__c.adderror('Please enter value for Starter Dosage');   
                         
                          if(trigger.new[i].Starter_Prescription_Type__c!= null && (trigger.new[i].Starter_Frequency_of_Administration_gne__c==null))
                          	trigger.new[i].Starter_Frequency_of_Administration_gne__c.adderror('Please enter value for Starter Frequency of Administration'); 
                          	
                          //ab:validation added to replace 'Dspense_not_other' vaidation rule currently switched off because of SFA '$Setup.GNE_SFA2_User_App_Context_gne__c.SFA2_Mode_gne__c' switch	
                           if(trigger.new[i].Dispense_Other_BRAF_gne__c!= null && trigger.new[i].Dispense_Other_BRAF_gne__c > 0 && trigger.new[i].Dispense_gne__c!='Other')
                          	trigger.new[i].Dispense_Other_BRAF_gne__c.adderror('To enter a value here set the Dispense field value to Other');  	  
                                                   
                         //end Boomerang validations
                         
                         //default values                 
                         
                         if(trigger.new[i].Starter_Rx_Date_gne__c != null && trigger.new[i].Starter_Rx_Expiration_Date_gne__c==null )
                                trigger.new[i].Starter_Rx_Expiration_Date_gne__c = trigger.new[i].Starter_Rx_Date_gne__c.addYears(1);
                                                
                          	
                         //Boomerang computations
                          if(trigger.new[i].Initial_titration__c!= null && trigger.new[i].Initial_titration__c == 'Labeled Dosing' 
                          	&& trigger.new[i].Dispense_gne__c != 'Other'){      	
                          	trigger.new[i].Sig_Other__c = null; 
                          	trigger.new[i].Number_Of_other_Tablets__c = null;                          	                                         	
                          } 
                          
                           if(trigger.new[i].Maintenance__c!= null && trigger.new[i].Maintenance__c == 'Labeled Dosing'
                           	 && trigger.new[i].Dispense_maintenance__c != 'Other'){                 
                          	trigger.new[i].SIG_Other_maintenance__c = null; 
                          	trigger.new[i].Number_of_Other_Tablets_maint__c = null;                          	                                         	
                          } 
                          
                         
                        }
                        //end Boomerang logic
                    } 
                }
                catch (exception e)
                {
                    trigger.new[i].adderror('Critical error has occured while calculating :: ' + 'Pointer : ' + Status + ' ' + e.getmessage());
                }
         
                //***********************************************************//
                //**************** Transfer data to shipment ********//
                //***********************************************************//  
                // Count of Shipments associated with the MH record.
                integer k=[Select count() From Shipment_gne__c s where s.Case_Shipment_gne__r.Medical_History_gne__c IN :Med_hist.keyset()];
                // The following if loop ensures that the Shipment class is not called when
                // there are no shipments associated with the Medical History record. 
                if ((k > 0) && system.trigger.isupdate) 
                {
                   /************ D E B U G ************/
                   system.debug ('Transfer data to shipment');
                   /************ D E B U G ************/
                   Status='Transfer data to shipment';
                   result=GNE_CM_Shipment_rx_Data_Calc_Stamp.resultset(Med_hist);
                   Status='Check process result for transfer of data to shipment. Size : ' + result.size();
                   for (integer iCtr=0; iCtr < result.size(); iCtr++) 
                    {   
                        if (result[iCtr].startswith('0000'))
                        {
                            for(integer j=0; j < Trigger.new.size(); j++)
                            {
                                Trigger.new[j].addError('An error has occured while updating Presription Data in Shipment: ' + result[iCtr].substring(4));
                            }
                        }                   
                    }//End of Result For   
                } // end of if k>0
            }   //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig1())
            
            // GDC - 8/10/2011 - Populating Rx Date & Rx Expiration Date on new MH rec.
            try
            {
                for(Medical_History_gne__c mh: trigger.new)
                {
                    if(trigger.isinsert)
                    {
                        system.debug('mh value....1.........' + mh);
                        
                        
                       //PR : Removed for pegasys since Rx Date should not be populated on insert of Medical History 
                       // mh.Rx_Date_gne__c = system.now().date();
                        if(mh.Product_gne__c == 'Tarceva')
                        {         
                            //AS: 06/04/2012 Added the condition to populate the date field
                            if(mh.Starter_SMN_Effective_Date_gne__c != null && mh.Starter_SMN_Expiration_Date_gne__c == null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }
                            if(mh.Starter_Rx_Date_gne__c != null && mh.Starter_Rx_Expiration_Date_gne__c == null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c= mh.Starter_Rx_Date_gne__c.addYears(1);
                            }
                            if(mh.Starter_Rx_Expiration_Date_gne__c == null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c= mh.Starter_Begin_Date_gne__c.addYears(1);
                                //KS:commented out the below line due to confusion
                            }
                            
                            if(mh.Starter_Frequency_of_Administration_gne__c == 'QD')
                            {
                                Starter_Frequency = 1;
                            }
                            else if(mh.Starter_Frequency_of_Administration_gne__c == 'BID')
                            {
                                Starter_Frequency = 2;
                            }
                            else if(mh.Starter_Frequency_of_Administration_gne__c == 'TID')
                            {
                                Starter_Frequency = 3;
                            }
                            else if(mh.Starter_Frequency_of_Administration_gne__c == 'QID')
                            {
                                Starter_Frequency = 4;
                            }
                            system.debug('mh.BRAF_Dosage_gne__c * mh.Starter_Dispense_gne__c * Starter_Frequency / mh.Starter_Dosage_gne__c----->' + mh.BRAF_Dosage_gne__c + ':::' + mh.Starter_Dispense_gne__c + ':::' + Starter_Frequency + ':::' + mh.Starter_Dosage_gne__c);
                            /*mh.X25mg_Total_Number_of_Tablets_gne__c = (mh.BRAF_Dosage_gne__c * mh.Starter_Dispense_gne__c * Starter_Frequency) /mh.Starter_Dosage_gne__c;
                            mh.X100mg_Total_Number_of_Tablets_gne__c =(mh.BRAF_Dosage_gne__c * mh.Starter_Dispense_gne__c * Starter_Frequency) /mh.Starter_Dosage_gne__c;
                            mh.X150mg_Total_Number_of_Tablets_gne__c = (mh.BRAF_Dosage_gne__c * mh.Starter_Dispense_gne__c * Starter_Frequency) /mh.Starter_Dosage_gne__c;*/
                        }
                        if(mh.Rx_Expiration_gne__c == null && mh.Rx_Date_gne__c != null)
                        {
                            mh.Rx_Expiration_gne__c = mh.Rx_Date_gne__c.addYears(1);
                            system.debug('mh.Rx_Date_gne__c ::::: mh.Rx_Expiration_gne__c' + mh.Rx_Date_gne__c + '........' + mh.Rx_Expiration_gne__c);
                        }
                        if(mh.Product_gne__c == 'Lucentis')
                        {
                            if(mh.Rx_Expiration_gne__c == null && mh.Rx_Effective_Date_gne__c != null)
                            {
                                mh.Rx_Expiration_gne__c = mh.Rx_Effective_Date_gne__c.addYears(1);
                            }
                        }
                        //01/31/2015 PFS-2071 
                        if(mh.Product_gne__c == 'Cotellic')
                        {
                            //if(mh.Starter_SMN_Effective_Date_gne__c != null && mh.Starter_SMN_Expiration_Date_gne__c == null)
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }       
                        }
                        //02/03/2015 PFS-2075 && hpalm 1012 - logic for Zelboraf
                        if(mh.Product_gne__c == 'Zelboraf')
                        {
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }                            
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }       
                        }
                        //03/02/2015 PFS-2099 - Prevent user from creating Xeloda Medical records. 
                        if(trigger.isBefore){
                        	
                        	if(GNE_CM_MPS_Utils.isNonMHProduct(mh.Product_gne__c) || GNE_CM_MPS_Utils.isNonMHProduct(mh.Drug_gne__c)) 
                        	{
                        		mh.addError('You can\'t create a Xeloda Medical record(s).');
                        	}
                        }
                        
                    }
                    if(trigger.isupdate)
                    {
                        system.debug('inside update..........'+mh.Product_gne__c);
                        if(mh.Rx_Expiration_gne__c != null && mh.Rx_Date_gne__c != null)
                        {
                            system.debug('both not null...');
                            system.debug('trigger.new[0].Rx_Expiration_gne__c.......' + mh.Rx_Expiration_gne__c);
                            //wilczekk: what's the purpose of the below line?
                            mh.Rx_Expiration_gne__c = mh.Rx_Expiration_gne__c;
                            system.debug('mh.Rx_Expiration_gne__c.........' + mh.Rx_Expiration_gne__c);
                        }
                        else if(mh.Rx_Date_gne__c != null)
                        {
                            system.debug('exp is null');
                            mh.Rx_Expiration_gne__c = mh.Rx_Date_gne__c.addYears(1);
                        }
                        //01/31/2015 PFS-2071 and hpalm 1012 - logic for Cotellic
                        if(mh.Product_gne__c == 'Cotellic')
                        {
                            //if(mh.Starter_SMN_Effective_Date_gne__c != null && mh.Starter_SMN_Expiration_Date_gne__c == null)
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }   
                        }
                        //02/03/2015 PFS-2075 && hpalm 1012 - logic for Zelboraf
                        if(mh.Product_gne__c == 'Zelboraf')
                        {
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }                            
                            if(mh.Starter_SMN_Effective_Date_gne__c != null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }     
                        }
                        if(mh.Product_gne__c == 'Tarceva')
                        {         
                             system.debug('****************');
                             //AS: 06/04/2012 Added the condition to populate the date field
                            if(mh.Starter_SMN_Effective_Date_gne__c != null && mh.Starter_SMN_Expiration_Date_gne__c == null)
                            {
                                mh.Starter_SMN_Expiration_Date_gne__c = mh.Starter_SMN_Effective_Date_gne__c.addYears(1);
                            }
                            if(mh.Starter_Rx_Date_gne__c != null && mh.Starter_Rx_Expiration_Date_gne__c == null)
                            {
                                mh.Starter_Rx_Expiration_Date_gne__c= mh.Starter_Rx_Date_gne__c.addYears(1);
                            }
                             
                             mh.Starter_Rx_Expiration_Date_gne__c= mh.Starter_Begin_Date_gne__c.addYears(1);
                        }
                        
                        if(mh.Product_gne__c == 'Lucentis')
                        {
                            system.debug('inside lucentis');
                            system.debug('mh.Rx_Expiration_gne__c.......' + mh.Rx_Expiration_gne__c);
                            system.debug('mh.Rx_Effective_Date_gne__c........ ' + mh.Rx_Effective_Date_gne__c);
                            system.debug('trigger.new[0].Rx_Effective_Date_gne__c...........' + mh.Rx_Effective_Date_gne__c);
                            if(mh.Rx_Expiration_gne__c != null && mh.Rx_Effective_Date_gne__c != null)
                            {
                                system.debug('both not null...');
                                //wilczekk: what's the purpose of the below line?
                                mh.Rx_Expiration_gne__c = mh.Rx_Expiration_gne__c;
                                system.debug('mh.Rx_Expiration_gne__c..........' + mh.Rx_Expiration_gne__c);
                            }
                            else if(mh.Rx_Expiration_gne__c != null)
                            {
                                system.debug('exp is null');
                                mh.Rx_Expiration_gne__c = mh.Rx_Effective_Date_gne__c.addYears(1);
                            }
                        }
                    }
                    //Rama PFS-2075 MH changes for Cobi
                    if(mh.Product_gne__c == 'Cotellic') {
                        if(mh.Dispense_gne__c == 'Other') {
                            String errorMessage = '';
                            if(mh.Dispense_Other_Cotellic_Days__c == null || mh.Dispense_Other_Cotellic_Days__c == 0.0) {
                                errorMessage += 'Dispense Other (Days) cannot be Blank if Other is selected for Dispense. ';
                            }

                            if(mh.Dispense_Other_20mg_Tablet__c == null || mh.Dispense_Other_20mg_Tablet__c == 0.0) {
                                errorMessage += 'Dispense Other 20mg Tablet cannot be Blank if Other is selected for Dispense. ';
                            }

                            if(mh.Sig_Other__c == null || mh.Sig_Other__c.trim().equals('')) {
                                errorMessage += 'Sig (Other) cannot be Blank if Other is selected for Dispense.';
                            }
                            if(errorMessage != '') {
                                mh.addError(errorMessage);
                            }
                        } else {
                        	//bug 1247 - to use validation rule on field it cannot be forced to be null
                            //mh.Dispense_Other_Cotellic_Days__c = null;
                            //mh.Dispense_Other_20mg_Tablet__c = null;
                            //PFS 2116 there is a condition in gdoc to mapping PER to MH "IF Dosage = Other, THEN  Dosage Other = Sig (Other)"
                            //mh.Sig_Other__c = null;
                        }
                    }                   

                }
            }
            catch(exception e)
            {
                system.debug('Error..........' + e.getMessage());
            }
            // code ends here
       }
        catch (exception e)
        {
            for (Medical_History_gne__c medical : trigger.new)
            {
                medical.addError('Unexpected error has occured at [' + Status + ']' +  e.getmessage());
            }           
        } 
       
}