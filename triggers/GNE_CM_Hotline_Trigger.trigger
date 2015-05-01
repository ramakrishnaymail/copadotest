//Name of trigger : GNE_CM_Hotline_Trigger
//Created by : GDC 10/17/2008
//Restrict user from creating/editing Hotline when related case has
//been closed for 48 hours

trigger GNE_CM_Hotline_Trigger on Hotline_gne__c (before insert, before update) {
    
    Id PrevCaseId = null;
    Set<Id> caseidset = new Set<Id>(); 
    Map<Id, Case> Case_map; 
    //get environment variable value for Profile GNE-SYS-AutomatedJob
    Set<string> variable = new Set<string>{'AllObjects_CaseClosed_48hrs_chk_Profiles'};
    List<Environment_Variables__c> env_var = new List<Environment_Variables__c>();
    Map<String, String> Case_Profiles = new Map<String, String>();
    String ProfileId = Userinfo.getProfileId();
    string Profile_name ='';
    
    try
    {
        Profile_name = [select name from Profile where Id =:profileId limit 1].Name;
        env_var = GNE_CM_Environment_variable.get_env_variable(variable);
        for (integer MI = 0; MI<env_var.size(); MI++)
        {   if (env_var[MI].Key__c == 'AllObjects_CaseClosed_48hrs_chk_Profiles')
                Case_Profiles.put(env_var[MI].Value__c, env_var[MI].Value__c);
        }
    }
    catch(exception e)
    {
        for(Hotline_gne__c hotl :Trigger.new)
        hotl.adderror('Error encountered while getting Profile Name: ' + e.getmessage());
    }   //end of catch
    
    for(Hotline_gne__c hotline :Trigger.new)
    { 
        try
        {                           
            if (hotline.Related_Case_gne__c != null && hotline.Related_Case_gne__c != PrevCaseId)
                {
                    caseidset.add(hotline.Related_Case_gne__c);
                    PrevCaseId = hotline.Related_Case_gne__c;
                }   //end of if
        }   //end of try
        catch(exception e)
        {
            hotline.adderror('Error encountered in creation of Case list for Hotline' + e.getmessage());
        }   //end of catch
        
    }   //end of for
    try
    {
        Case_map =new Map<Id, Case>([select Status, ClosedDate from Case where Id IN :caseidset]);
    }
    catch(exception e)
    {
        for(Hotline_gne__c hot :Trigger.new)
            hot.adderror('Error encountered while creating Case Map ' + e.getmessage());
    
    }   //end of catch
    
    for(Hotline_gne__c hotline :Trigger.new)
    {
        try
        {
            if(hotline.Related_Case_gne__c != null && Case_map.containsKey(hotline.Related_Case_gne__c))
            {
                if(Case_map.get(hotline.Related_Case_gne__c).Status.startsWith('Closed') && System.now() >= (Case_map.get(hotline.Related_Case_gne__c).ClosedDate.addDays(2)) && Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)))   
                 {
                    hotline.adderror('Hotline cannot be created/edited once related case has been Closed for 48 hours or more.');
                 }
            }   
        }//end of try
        
        catch(Exception e)
        {
            hotline.adderror('Error encountered while checking status of related case in Hotline');
        }   //end of catch
    } //end of for 
    Case_Profiles.clear();  
    Case_map.clear();   //to clear the map once trigger records had been processed

}//end of trigger