trigger GNE_CM_alternative_funding on Alternative_Funding_gne__c (before insert, before update) {

    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }

    Id PrevCaseId = null;
    Set<Id> caseidset = new Set<Id>(); 
    Map<Id, Case> Case_map;  
    Set<string> variable = new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'};
    List<Environment_Variables__c> env_var = new List<Environment_Variables__c>();
    Map<String, String> Case_Profiles = new Map<String, String>();
    String ProfileId = Userinfo.getProfileId();
    string Profile_name ='';
   
    for(Alternative_Funding_gne__c af :Trigger.new)
    {
        try
        {                        
            if (af.Case_gne__c != null && af.Case_gne__c != PrevCaseId)
           {
                caseidset.add(af.Case_gne__c);
                PrevCaseId = af.Case_gne__c;
            }   //end of if
        }
        catch(exception e)
        {
            af.addError('An error has occured creating set: ' + e.getmessage());
        }   //end of catch
    }   //end of try
    
     
    try
    {
        Case_map = new Map<Id, Case>([select patient_gne__c, closeddate, status  from Case where Id IN :caseidset]);
        Profile_name = [select name from Profile where Id =:profileId limit 1].Name;     
        env_var = GNE_CM_Environment_variable.get_env_variable(variable);
        for (integer MI = 0; MI<env_var.size(); MI++)
        {   if (env_var[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
                Case_Profiles.put(env_var[MI].Value__c, env_var[MI].Value__c);
        }
    }
    catch(exception e)
    {
       for(Alternative_Funding_gne__c af :Trigger.new)
        {
                af.addError('Critical error has occured ' + e.getmessage());
        }
    }   //end of catch
    for(Alternative_Funding_gne__c af :Trigger.new)
    {
        try
        {
            if(af.Case_gne__c != null && Case_map.containsKey(af.Case_gne__c))
            {                       
                af.Patient_gne__c = Case_map.get(af.Case_gne__c).patient_gne__c;
            }            
           //Do not allow user to create or edit Alternative Funding when associated case has been closed for 48 hours 
            if( Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)) && Case_map.get(af.Case_gne__c).Status.startsWith('Closed') && System.now() >= (Case_map.get(af.Case_gne__c).ClosedDate.addDays(2)))    
            {
                af.adderror('Alternative funding cannot be created/edited once the associated case has been Closed for 48 hours or more.');
            }                                    
        }   //end of try
        
        catch(Exception e)
        {
            af.adderror('Error encountered while aligning patient with Alternative funding');
        }   //end of catch
    } //end of for Alternative_Funding_gne__c
    
    
        Case_Profiles.clear();  
        Case_map.clear();   //to clear the map once trigger records had been processed
        caseidset.clear();  //to clear the set once trigger records had been processed  
                
}   //end of trigger