//Name of trigger : GNE_CM_Infusion_patient_prepopulate 
//Created by : Ravinder Singh(GDC)
//Last Modified on :13/03/2008 (Kapila Monga: Added the Locked by Migration check.)
// Last Modified on : 10/06/09 (Kapila Monga: Actemra: Changes for Actemra product, Added Actemra to condition in if loop)
//PK PFS-966 12/17/2013 Added Xolair to the products filter to populate Inf_case.

trigger GNE_CM_Infusion_patient_prepopulate on Infusion_gne__c (before insert, before update)
{
    Id PrevShipId = null;
    Set<Id> shipmentidset = new Set<Id>();
    Set<Id> oldshipmentidset = new Set<Id>();
    double Count; 
    Map<Id, Shipment_gne__c> Shipment_map = new Map<Id, Shipment_gne__c>();
    Map<Id, Shipment_gne__c> Shipment_old_map = new Map<Id, Shipment_gne__c>();   
    Map<Id, Case> case_map = new Map<Id, Case>();
    Set<Id> caseidset = new Set<Id>();
    Id PrevCaseId=null;
    Set<id> Inf_case = new Set<Id>();
    Set<id> case_done = new set<id>();
    List<case> case_upd = new List<Case>();
    Database.saveresult[] SR;
    Set<id> Inf_total = new Set<Id>();
    set<ID> Caseid = new Set<ID>();
    set<ID> Accountid = new Set<ID>();
    Map<Id, Account> account_map;
    Set<id> cas_count = new set<id>();
    List<Infusion_gne__c> Inf_dup = new List<Infusion_gne__c>();
    Set<id> Inf_total_case = new Set<id>();
    Map<Id, Case> case_total_map = new Map<Id, Case>();
    string Profile_name ='';
    Set<string> variable = new Set<string>{'Infusion_Update_Profiles','AllObjects_CaseClosed_48hrs_chk_Profiles'};
    Map<String,String> env_var = new Map<String,String>();
    Map<String,String> env_var_closed = new Map<String,String>();
    List<Environment_Variables__c> query = new List<Environment_Variables__c>();
    query = GNE_CM_Environment_variable.get_env_variable(variable);
    Map<Id,double> case_total = new Map<Id,double>();
    Map<Id,Case> cas_tot = new Map<Id,Case>();
    
    //GA101
    string GA101_Product_Name = system.label.GNE_CM_GA101_Product_Name;
    if(query.size()>0)
    {
        for(integer i=0;i<query.size();i++)
        {
            if(query[i].Key__c == 'Infusion_Update_Profiles')
            env_var.put(query[i].Value__c,query[i].Value__c);
            if(query[i].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
            env_var_closed.put(query[i].Value__c,query[i].Value__c);
        }
    }
       
    String ProfileId = Userinfo.getProfileId();
    if(profileId !=null)
    {
        Profile_name = [select name from Profile where Id =:profileId limit 1].Name;
    }  
    
     
    for(Infusion_gne__c inf :Trigger.new)
        { 
            try
                {
                    if(trigger.isupdate && system.trigger.oldmap.get(inf.Id).Shipment_gne__c !=null)
                    {
                         oldshipmentidset.add(system.trigger.oldmap.get(inf.Id).Shipment_gne__c);
                    }
                    if (inf.Case_gne__c != null && inf.Case_gne__c != PrevCaseId)
                        {
                            caseidset.add(inf.Case_gne__c);
                            PrevCaseId = inf.Case_gne__c;
                        }   //end of if             
                                            
                    if (inf.Shipment_gne__c != null && inf.Shipment_gne__c != PrevShipId)
                        {
                            shipmentidset.add(inf.Shipment_gne__c);
                            PrevShipId = inf.Shipment_gne__c;
                        }   //end of if
                }   //end of try
            catch(exception e)
                {
                    inf.adderror('Error encountered in creation of shipment list for infusion' + e.getmessage());
                }   //end of catch
            
        }   //end of for
    try
        {
            Shipment_map =new Map<Id, Shipment_gne__c>([select Product_gne__c, Status_gne__c,Case_Shipment_gne__c, Case_Shipment_gne__r.status,Case_Shipment_gne__r.recordtype.name, Case_Shipment_gne__r.medical_history_gne__r.Date_of_First_Treatment_gne__c, Case_Shipment_gne__r.closeddate,RA_gne__c,Return_Date_gne__c, Patient_gne__c, Account_gne__c, Case_Shipment_gne__r.product_gne__c from Shipment_gne__c where (Id IN :shipmentidset OR Id IN: oldshipmentidset) ]);            
            case_map=new Map<Id, Case>([Select Roll_Up_Infuisons_To_gne__c, Practice_gne__c,Product_gne__c, patient_gne__c, status, closeddate, Case_Treating_Physician_gne__c, Facility_gne__c,recordtype.name,Infusions_Total_gne__c,medical_history_gne__c,medical_history_gne__r.Date_of_First_Treatment_gne__c,(select milligrams_gne__c,Infusion_Date_gne__c from Infusions__r) from case where id in :caseidset ]);
        }
    catch(exception e)
        {
            for(integer i=0;i<trigger.new.size();i++) 
                {
                    trigger.new[i].adderror('Error in generating map of associated shipments. Aborting the process.');
                }
        }   //end of catch
        
   for(Infusion_gne__c inf :Trigger.new)
    {
        try
            {
                if(trigger.isinsert)
                {
                    if(inf.shipment_gne__c != null && Shipment_map.containskey(inf.shipment_gne__c))
                    {
                        if(Shipment_map.get(inf.shipment_gne__c).Status_gne__c == 'RE - Released')
                        {
                            if(env_var.containskey(Profile_name))
                            {
                                // do nothing 
                            }
                            else
                            {
                                inf.adderror('Infusion cannot be created if Shipment status is Released');
                            }
                        }
                    }
                }
                if(trigger.isupdate)
                {
                    if(system.trigger.oldmap.get(inf.Id).Shipment_gne__c !=null 
                    && Shipment_map.containskey(system.trigger.oldmap.get(inf.Id).Shipment_gne__c)
                    && oldshipmentidset.contains(system.trigger.oldmap.get(inf.Id).Shipment_gne__c))
                    {
                        if(Shipment_map.get(system.trigger.oldmap.get(inf.Id).Shipment_gne__c).Status_gne__c == 'RE - Released')
                        {
                            if(env_var.containskey(Profile_name))
                            {
                                // do nothing 
                            }
                            else
                            {
                                inf.adderror('Infusion assigned to Shipment having status Released cannot be updated');
                            }
                        }
                    }
                    // KM - 3/13/2009 - The following check ensures that the Infusion records locked through migration are not editable from UI.
                    if(inf.Locked_by_migration_gne__c == true)
                    inf.adderror('Infusion records locked through migration cannot be edited.');
                }
                        
                if(inf.Case_gne__c!=null && case_map.containsKey(inf.Case_gne__c))  
                    {
                        inf.Patient_infusion_gne__c = case_map.get(inf.Case_gne__c).patient_gne__c;  
                       
                        if(case_map.get(inf.Case_gne__c).Product_gne__c=='Herceptin')
                        {
                            if(trigger.isinsert) // to align Account to Infusion while inserting Infusions only and not during updating
                                {                      
                                    if (case_map.get(inf.Case_gne__c).Roll_Up_Infuisons_To_gne__c=='Physician' && case_map.get(inf.Case_gne__c).Case_Treating_Physician_gne__c!=null)
                                        {
                                            inf.Account_gne__c=case_map.get(inf.Case_gne__c).Case_Treating_Physician_gne__c;   
                                         }
                                    else if (case_map.get(inf.Case_gne__c).Roll_Up_Infuisons_To_gne__c=='Clinic/Practice' && case_map.get(inf.Case_gne__c).Practice_gne__c!=null)
                                        {
                                            inf.Account_gne__c=case_map.get(inf.Case_gne__c).Practice_gne__c;   
                                         } 
                                    else if (case_map.get(inf.Case_gne__c).Roll_Up_Infuisons_To_gne__c=='Hospital' && case_map.get(inf.Case_gne__c).Facility_gne__c!=null)
                                        {
                                            inf.Account_gne__c=case_map.get(inf.Case_gne__c).Facility_gne__c;   
                                         } 
                                }
                         }
                         if((case_map.get(inf.case_gne__c).recordtype.name == 'C&R - Continuous Care Case' || case_map.get(inf.case_gne__c).recordtype.name == 'C&R - Standard Case') //krzyszwi CM T-385
                            && case_map.get(inf.case_gne__c).product_gne__c == 'Avastin'
                            && case_map.get(inf.case_gne__c).medical_history_gne__c != null)
                            {
                                if(case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c !=null)
                                {
                                    Count =0;
                                    if(!cas_count.contains(inf.case_gne__c))
                                    {
                                        for(Infusion_gne__c inf_calc: case_map.get(inf.case_gne__c).Infusions__r)
                                        {
                                            if(inf_calc.milligrams_gne__c !=null 
                                                && inf_calc.Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                            {
                                                Count += inf_calc.milligrams_gne__c;
                                            }
                                        }
                                        cas_count.add(inf.case_gne__c);
                                    }                                   
                                    if(trigger.isinsert)
                                    {   
                                        if(inf.milligrams_gne__c!=null 
                                        && inf.Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                        Count += inf.milligrams_gne__c;                                     
                                        if(Count !=0)
                                        {
                                            if(!case_total.containskey(inf.case_gne__c))
                                            case_total.put(inf.case_gne__c,count);
                                            else
                                            {
                                                double temp = case_total.get(inf.case_gne__c);
                                                case_total.remove(inf.case_gne__c);
                                                temp = temp +count;
                                                case_total.put(inf.case_gne__c,temp);
                                            }
                                            cas_tot.put(inf.case_gne__c,case_map.get(inf.case_gne__c));
                                        }
                                    }
                                    if(trigger.isupdate)
                                    {
                                        if(inf.Infusion_Date_gne__c != system.trigger.oldmap.get(inf.Id).Infusion_Date_gne__c)
                                        {
                                            if(inf.Infusion_Date_gne__c == null
                                                && system.trigger.oldmap.get(inf.Id).Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                            Count -= inf.milligrams_gne__c;
                                            else if(inf.Infusion_Date_gne__c < case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c
                                                && inf.milligrams_gne__c !=null)
                                            Count -= inf.milligrams_gne__c;
                                            else if(inf.Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c
                                                && inf.milligrams_gne__c !=null
                                                && system.trigger.oldmap.get(inf.Id).Infusion_Date_gne__c < case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c )
                                            Count += inf.milligrams_gne__c;
                                            else if(inf.Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c
                                                && inf.milligrams_gne__c !=null
                                                && system.trigger.oldmap.get(inf.Id).Infusion_Date_gne__c ==null )
                                            Count += inf.milligrams_gne__c;
                                        }
                                        else if(inf.milligrams_gne__c != system.trigger.oldmap.get(inf.Id).milligrams_gne__c)
                                        {
                                            if(inf.milligrams_gne__c==null)
                                                Count -= system.trigger.oldmap.get(inf.Id).milligrams_gne__c;
                                            else if(inf.milligrams_gne__c!=null 
                                            && inf.Infusion_Date_gne__c >= case_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                            {
                                                if(system.trigger.oldmap.get(inf.Id).milligrams_gne__c !=null)
                                                Count += (inf.milligrams_gne__c - system.trigger.oldmap.get(inf.Id).milligrams_gne__c);
                                                else
                                                Count += inf.milligrams_gne__c;
                                            }
                                        }
                                        Case cas_update = new Case();
                                        cas_update = case_map.get(inf.case_gne__c);                                     
                                        if(cas_update.Infusions_Total_gne__c != string.valueOf(Count))
                                        {
                                            if(!case_total.containskey(inf.case_gne__c))
                                            case_total.put(inf.case_gne__c,count);
                                            else
                                            {
                                                double temp = case_total.get(inf.case_gne__c);
                                                case_total.remove(inf.case_gne__c);
                                                temp = temp +count;
                                                case_total.put(inf.case_gne__c,temp);
                                            }
                                            cas_tot.put(inf.case_gne__c,case_map.get(inf.case_gne__c));                                         
                                        }
                                    }
                                }
                            }
                                                        
                    }
                else if(inf.Shipment_gne__c != null && Shipment_map.containsKey(inf.Shipment_gne__c))
                    {  
                        if(Shipment_map.get(inf.Shipment_gne__c).Account_gne__c !=null)
                        {
                            inf.Account_gne__c = Shipment_map.get(inf.Shipment_gne__c).Account_gne__c;
                        }
                        else if(Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__c!=null)
                            {
                                inf.Patient_infusion_gne__c    = Shipment_map.get(inf.Shipment_gne__c).Patient_gne__c;
                                inf.Case_gne__c  = Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__c;
                            }   
                       if(inf.case_gne__c !=null
                       && (Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.recordtype.name == 'C&R - Continuous Care Case' || Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.recordtype.name == 'C&R - Standard Case') //krzyszwi CM T-385
                       && Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.product_gne__c == 'Avastin'
                       && Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.medical_history_gne__c!=null)
                       {
                        if(Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.medical_history_gne__r.Date_of_First_Treatment_gne__c !=null)
                              Inf_total_case.add(inf.case_gne__c);
                       } 
                        
                    } 
                              
                //Do not allow user to create/edit Infusion when case has been closed for 48 hours
                if(!env_var_closed.containskey(Profile_name))
                {
                    if(inf.Case_gne__c!=null && case_map.containsKey(inf.Case_gne__c))  
                    {
                         if(case_map.get(inf.Case_gne__c).Status.startsWith('Closed') && System.now() >= (case_map.get(inf.Case_gne__c).ClosedDate.addDays(2)))  
                         inf.adderror('Infusion cannot be created/edited once associated case has been Closed for 48 hours or more.');                  
                    }
                    else if(inf.Shipment_gne__c != null && Shipment_map.containsKey(inf.Shipment_gne__c) && Shipment_map.get(inf.Shipment_gne__c).Case_shipment_gne__c != null)
                    {
                         if(Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.Status.startsWith('Closed') && System.now() >= (Shipment_map.get(inf.Shipment_gne__c).Case_Shipment_gne__r.ClosedDate.addDays(2)))    
                         inf.adderror('Infusion cannot be created/edited once case associated with Shipment has been Closed for 48 hours or more.');                  
                    } 
                }
                //end of Closed Case check
                
                //PK PFS-966 12/17/2013 Added Xolair to the products filter to populate Inf_case. 
                if(inf.Account_gne__c ==null && inf.Case_gne__c != null)
                {
                    if(inf.Shipment_gne__c == null)
                    {
                        if(case_map.get(inf.Case_gne__c).product_gne__c == 'Rituxan' 
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Rituxan RA'
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Avastin' 
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Lucentis'
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Actemra'
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Xolair'
                            || case_map.get(inf.Case_gne__c).product_gne__c == system.label.GNE_CM_TDM1_Product_Name
                            || case_map.get(inf.Case_gne__c).product_gne__c == GA101_Product_Name
                            )
                        Inf_case.add(inf.Case_gne__c);
                    }
                    else
                    {
                        if(shipment_map.get(inf.Shipment_gne__c).product_gne__c == 'Rituxan' 
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == 'Rituxan RA'
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == 'Avastin' 
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == 'Lucentis'
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == 'Actemra'
                            || case_map.get(inf.Case_gne__c).product_gne__c == 'Xolair'
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == system.label.GNE_CM_TDM1_Product_Name
                            || shipment_map.get(inf.Shipment_gne__c).product_gne__c == GA101_Product_Name
                            )
                        Inf_case.add(shipment_map.get(inf.Shipment_gne__c).case_shipment_gne__c);
                    }
                }
                
                
            //}
            }
        catch(Exception e)
            {
                inf.adderror('Error encountered while filling case and patient information in Infusion '+e);
            }   //end of catch
    } //end of for
    try
    {
        if(Inf_case.size()>0)
              { 
                  Inf_dup = [select Id, Expected_Date_of_Treatment_gne__c, Case_gne__c from Infusion_gne__c where Case_gne__c in :Inf_case and Case_gne__c !=null];                  
              }
    }
    catch(Exception e)
    {
        for(integer i=0;i<trigger.new.size();i++) 
        {
            trigger.new[i].adderror('Error encountered while querying Infusions '+e);
        }
       
    }   //end of catch
    if(trigger.isinsert || trigger.isupdate)
        {            
            for(Infusion_gne__c inf : Trigger.new)
                {
                    try
                        {
                            if(system.trigger.isinsert) 
                            {
                            if(inf.Account_gne__c ==null && inf.Case_gne__c != null)
                                {  
                                	system.debug('--------------------Inf_dup'+Inf_dup);                                 
                                    if(inf.Expected_Date_of_Treatment_gne__c !=null && Inf_dup.size()>0)                                   
                                        {
                                            for(integer i=0;i<Inf_dup.size();i++)
                                            {
                                                if(Inf_dup[i].Case_gne__c !=null && Inf_dup[i].Expected_Date_of_Treatment_gne__c !=null)
                                                {
                                                    if(Inf_dup[i].Case_gne__c == inf.Case_gne__c
                                                        && Inf_dup[i].Expected_Date_of_Treatment_gne__c == inf.Expected_Date_of_Treatment_gne__c)                                                       
                                                    inf.adderror('Same Expected treatment date exist in database for the Case');
                                                }
                                            }
                                           
                                        }
                                }                                                                            
                                
                            }
                            if(system.trigger.isupdate)
                            {
                                if(inf.Account_gne__c ==null && inf.Case_gne__c != null)
                                {
                                        if(inf.Expected_Date_of_Treatment_gne__c !=null 
                                            && system.trigger.oldmap.get(inf.Id).Expected_Date_of_Treatment_gne__c !=inf.Expected_Date_of_Treatment_gne__c
                                            && Inf_dup.size()>0) 
                                                                              
                                        {
                                            for(integer i=0;i<Inf_dup.size();i++)
                                            {
                                                if(Inf_dup[i].Case_gne__c !=null && Inf_dup[i].Expected_Date_of_Treatment_gne__c !=null)
                                                {
                                                if(Inf_dup[i].Case_gne__c == inf.Case_gne__c
                                                    && Inf_dup[i].Expected_Date_of_Treatment_gne__c == inf.Expected_Date_of_Treatment_gne__c)                                                   
                                                    inf.adderror('Same Expected treatment date exist in database for the Case');
                                                }
                                            }
                                         }                                                                               
                                }
                            }
                            
                        }
                    catch(exception e)
                        {
                            inf.adderror('Error encountered in checking Expected date of treatment '+e.getmessage());
                        }
                }
        }
        try
        { 
            // This SOQL will only be executed if Infusion is created from Shipment that belong to C&R Continuos Care Avastin Case 
            // and associated Medical history has non-null Date of first treatment          
            if(Inf_total_case.size()>0)
            {
                case_total_map = case_map=new Map<Id, Case>([Select Product_gne__c, recordtype.name,Infusions_Total_gne__c,medical_history_gne__c,medical_history_gne__r.Date_of_First_Treatment_gne__c,(select milligrams_gne__c,Infusion_Date_gne__c from Infusions__r) from case where id in :Inf_total_case ]);
            }
        }
        catch(exception e)
        {
            for(integer i=0;i<trigger.new.size();i++) 
                {
                    trigger.new[i].adderror('Error in generating map of associated cases. Please contact administrator');
                }
            //System.debug('Error encountered in SOQL' + e.getmessage());
        }   //end of catch
        
        for(Infusion_gne__c inf: trigger.new)
        {
            try
            {
                if(inf.case_gne__c !=null && case_total_map.containskey(inf.case_gne__c) && inf.shipment_gne__c!=null)
                {
                    if((case_total_map.get(inf.case_gne__c).recordtype.name == 'C&R - Continuous Care Case' || case_total_map.get(inf.case_gne__c).recordtype.name == 'C&R - Standard Case') //krzyszwi CM T-385
                        && case_total_map.get(inf.case_gne__c).product_gne__c == 'Avastin'
                        && case_total_map.get(inf.case_gne__c).medical_history_gne__c != null)
                        {
                            if(case_total_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c !=null)
                            {
                                Count =0;
                                if(!cas_count.contains(inf.case_gne__c))
                                {
                                    for(Infusion_gne__c inf_calc: case_total_map.get(inf.case_gne__c).Infusions__r)
                                    {
                                        if(inf_calc.milligrams_gne__c !=null 
                                            && inf_calc.Infusion_Date_gne__c >= case_total_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                        {
                                            Count += inf_calc.milligrams_gne__c;
                                        }
                                    }
                                    cas_count.add(inf.case_gne__c);
                                }
                                if(trigger.isinsert)
                                {
                                    if(inf.milligrams_gne__c!=null 
                                    && inf.Infusion_Date_gne__c >= case_total_map.get(inf.case_gne__c).medical_history_gne__r.Date_of_First_Treatment_gne__c)
                                    Count += inf.milligrams_gne__c;
                                    
                                    if(Count !=0)
                                    {
                                        if(!case_total.containskey(inf.case_gne__c))
                                        case_total.put(inf.case_gne__c,count);
                                        else
                                        {
                                            double temp = case_total.get(inf.case_gne__c);
                                            case_total.remove(inf.case_gne__c);
                                            temp = temp +count;
                                            case_total.put(inf.case_gne__c,temp);
                                        }
                                        cas_tot.put(inf.case_gne__c, case_total_map.get(inf.case_gne__c));                                      
                                    }
                                }                               
                                    
                            }
                        }
                }
            }
            catch(exception e)
            {
                inf.adderror('Error encountered in checking Infusions total '+e.getmessage());
            }   
        }
        for(infusion_gne__c inf: trigger.new)
        {
            if(inf.case_gne__c !=null && case_total.containskey(inf.case_gne__c) && cas_tot.containskey(inf.case_gne__c))
            {
                if(!case_done.contains(inf.case_gne__c))
                {
                    Case cas_update = new Case();
                    cas_update= cas_tot.get(inf.case_gne__c);
                    cas_update.Infusions_Total_gne__c = string.valueOf(case_total.get(inf.case_gne__c));
                    case_upd.add(cas_update);
                    case_done.add(inf.case_gne__c);
                }
            }
        }
        if(case_upd.size()>0)
        {
            SR = database.update(case_upd,false);        
            for(Database.saveresult lsr: SR)
            {
                if(!lsr.issuccess())
                {
                    for(integer i=0;i<trigger.new.size();i++) 
                    {
                        trigger.new[i].adderror('Error in updating Infusions total field on Case : ' + lsr.getErrors()[0].getmessage());
                    }
                }
            }
        }        
      
        Shipment_map.clear();   //to clear the map once trigger records had been processed
        shipmentidset.clear();  //to clear the set once trigger records had been processed  
        Inf_case.clear();    //to clear the set once trigger records had been processed       
        
                 
}   //end of trigger