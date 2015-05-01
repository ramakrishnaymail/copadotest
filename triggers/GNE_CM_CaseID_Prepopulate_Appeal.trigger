/*------------      Name of trigger : GNE_CM_CaseID_Prepopulate_Appeal   --------------*/
/*------------      Created by : GDC                                     --------------*/
/*------------      Last Modified on :15/01/2009                       ---------------*/

trigger GNE_CM_CaseID_Prepopulate_Appeal on Appeal_gne__c (before insert, before update) 
{
   //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    Set<Id> biidset = new Set<Id>();
    Id prevBIId = null ;
    Map<Id, Benefit_Investigation_gne__c> BI_map;  
    string Profile_name ='';
    //Set<string> variable = new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'};
    //List<Environment_Variables__c> envVar = new List<Environment_Variables__c>();
    String ProfileId = Userinfo.getProfileId();
    Map<String, String> Case_Profiles = new Map<String, String>();
    for(Appeal_gne__c a :Trigger.new)
    {
        try
        {   
            if (a.Benefit_Investigation_gne__c!=null && prevBIId != a.Benefit_Investigation_gne__c )
            {
                biidset.add(a.Benefit_Investigation_gne__c);
                prevBIId = a.Benefit_Investigation_gne__c;
            }   //end of if
        }   //end of try
        catch(exception e)
        {
            a.adderror('Error encountered in creation of BI list for Appeal' + e.getmessage());
        }   //end of catch          
    } //end of for  

    try
    {
        Profile_name = [select name from Profile where Id =:profileId limit 1].Name;     
	    String env = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;
	    for(String value : GNE_CM_CustomSettings_Utils.getValues(GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c.getall().values(), env))
		{
			Case_Profiles.put(value, value);
		}
	    
	    /*
	    Map<String, GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c> allObjectsCaseClosedMap = GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c.getAll();                       
	    for(GNE_CM_AllObj_CaseClosed_48hrs_chk_Prof__c envVar : allObjectsCaseClosedMap.values()){
	       if(envVar.Environment__c == env || envVar.Environment__c.toLowerCase() == 'all'){
	    	   Case_Profiles.put(envVar.Value__c, envVar.Value__c);          	
	       }
	    }       
	    */      
        /*
        envVar = GNE_CM_Environment_variable.get_envVariable(variable);
        for (integer MI = 0; MI<envVar.size(); MI++)
        {   if (envVar[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
                Case_Profiles.put(envVar[MI].Value__c, envVar[MI].Value__c);
        }
        */
        BI_map = new Map<Id, Benefit_Investigation_gne__c>([select Patient_BI_gne__c,Case_BI_gne__c, Case_BI_gne__r.Status, Case_BI_gne__r.ClosedDate, Denial_Reason_gne__c,BI_BI_Status_gne__c,Product_BI_gne__c from Benefit_Investigation_gne__c where Id in :biidset]);
    }
    catch(exception e)
    {
        for(Appeal_gne__c aa :Trigger.new)
        aa.adderror('Error encountered while creating BI Map: ' + e.getmessage());
    }   //end of catch
    
    for(Appeal_gne__c a :Trigger.new)
    {   
        try
        {
            if (a.Benefit_Investigation_gne__c!=null && BI_map.containsKey(a.Benefit_Investigation_gne__c))
            {
                a.Case_Appeal_gne__c=BI_map.get(a.Benefit_Investigation_gne__c).Case_BI_gne__c;
                //a.BI_Status_gne__c=BI_map.get(a.Benefit_Investigation_gne__c).BI_BI_Status_gne__c;
                a.Product_Appeal_gne__c= BI_map.get(a.Benefit_Investigation_gne__c).Product_BI_gne__c;
                //a.Denial_Reason_gne__c=BI_map.get(a.Benefit_Investigation_gne__c).Denial_Reason_gne__c;
                a.Patient_Appeal_gne__c  = BI_map.get(a.Benefit_Investigation_gne__c).Patient_BI_gne__c;
                //Do not allow user to create/edit Appeal when case has been locked for 48 hours or more
                if(BI_map.get(a.Benefit_Investigation_gne__c).Case_BI_gne__c!=null)
                {
                    if(Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)) && BI_map.get(a.Benefit_Investigation_gne__c).Case_BI_gne__r.Status.startsWith('Closed') && System.now() >= (BI_map.get(a.Benefit_Investigation_gne__c).Case_BI_gne__r.ClosedDate.addDays(2)))   
                    {
                        a.adderror('Appeals cannot be created/edited when case associated with selected BI has been Closed for 48 hours or more.');
                    }
                }
                
            }
        }
            
        catch(Exception e)
        {
            a.adderror('Error encountered while filling information from BI to Appeal' + e.getmessage());
        }   //end of catch
    }   //end of for
    Case_Profiles.clear();    
    BI_map.clear();     //to clear the map once trigger records had been processed
    biidset.clear();    //to clear the set once trigger records had been processed   

}   //end of trigger