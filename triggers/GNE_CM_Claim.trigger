//Name of trigger : GNE_CM_Claim
//Created by : Ravinder Singh(GDC)
//Last Modified on :10/17/2008 (Shweta Bhardwaj)

trigger GNE_CM_Claim on Claim_gne__c (before insert, before update) 
{

   //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
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
        for(Claim_gne__c claim :Trigger.new)
        {                        
            if (claim.Case_gne__c != null && claim.Case_gne__c != PrevCaseId)
               {
                    caseidset.add(claim.Case_gne__c);
                    PrevCaseId = claim.Case_gne__c;
                }   //end of if
        }   //end of try

        Case_map = new Map<Id, Case>([select patient_gne__c, status, closeddate  from Case where Id IN :caseidset]);
    }
    
    catch(exception e)
    {
        for (Integer i = 0; i == Trigger.new.size(); i++)
            {
                Trigger.new[i].addError('Critical error has occured ' + e.getmessage());
            }
    }   //end of catch
    
    for(Claim_gne__c claim :Trigger.new)
    {
        try
        {
             if(claim.Case_gne__c != null && Case_map.containsKey(claim.Case_gne__c))
                {                       
                    claim.Patient_claim_gne__c = Case_map.get(claim.Case_gne__c).patient_gne__c;
            //Do not allow user to edit/create Claim when case has been closed for 48 hours or more
                    if(Case_map.get(claim.Case_gne__c).Status.startsWith('Closed') && System.now() >= (Case_map.get(claim.Case_gne__c).ClosedDate.addDays(2)) && Case_Profiles != null && !(Case_Profiles.containsKey(profile_name)))   
                    {
                        claim.adderror('Claim cannot be created/edited once associated case has been Closed for 48 hours or more.');
                    }    
               }   //end of if                                                
        }   //end of try
        catch(Exception e)
        {
            claim.adderror('Error encountered while aligning patient with Claim');
        }   //end of catch
    } //end of for Claim_gne__c
    
    
        Case_Profiles.clear();  
        Case_map.clear();   //to clear the map once trigger records had been processed
        caseidset.clear();  //to clear the set once trigger records had been processed  
                
}   //end of trigger