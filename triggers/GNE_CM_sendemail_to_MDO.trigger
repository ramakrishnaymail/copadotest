trigger GNE_CM_sendemail_to_MDO on alerts_gne__c (before insert, before update) 
{
    Integer zcnt = 0;
    
    // **************************************************************//
    // ******************Code to check 48 hrs validation*************//
    // **************************************************************//
    Set<string> variable = new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'};
    Map<String, String> Case_Profiles = new Map<String, String>();
    String ProfileId = Userinfo.getProfileId();
    Set<Id> idset = new Set<Id>();
    Map<Id, Case> Case_map; 
    List<Environment_Variables__c> env_var = new List<Environment_Variables__c>();
    string Profile_name ='';
    
    for(Alerts_gne__c Alert_Rec : trigger.new)
    {
        if (Alert_Rec.Case_gne__c != null)
            {
                idset.add(Alert_Rec.Case_gne__c);
            }   //end of if
    }
    Case_map = new Map<Id, Case>([select status, closeddate from Case where Id IN :idset]);
    
    Profile_name = [select name from Profile where Id =:profileId limit 1].Name;
    env_var = GNE_CM_Environment_variable.get_env_variable(variable);
    
    for (integer MI = 0; MI<env_var.size(); MI++)
    {   
        if (env_var[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
        Case_Profiles.put(env_var[MI].Value__c, env_var[MI].Value__c);
    }
    
    for(Alerts_gne__c Alert_Rec : trigger.new)
     {
        if(Alert_Rec.Case_gne__c != null && Case_map.containsKey(Alert_Rec.Case_gne__c))
        {   
            if(Case_map.get(Alert_Rec.Case_gne__c).Status.startsWith('Closed') && System.now() >= (Case_map.get(Alert_Rec.Case_gne__c).ClosedDate.addDays(2)) && Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)))   
            {
                Alert_Rec.adderror('Alerts cannot be created/edited once associated case has been Closed for 48 hours or more.');
            }
        }   
     }
     
    /*****
    for (Alerts_gne__c Alert_Rec : trigger.new)
    {
        If (Alert_Rec.Alert_8Hr_Check_Flag_gne__c == False 
        && !GNE_CM_case_trigger_monitor.triggerIsInProcess()) 
        {
            Alert_Rec.Alert_8Hr_Check_Flag_gne__c = True;
        }
    } 
    GNE_CM_case_trigger_monitor.setTriggerInProcess(); 
    *****/
}