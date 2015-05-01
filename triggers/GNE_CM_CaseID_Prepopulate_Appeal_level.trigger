/*------------      Name of trigger : GNE_CM_CaseID_Prepopulate_Appeal_level----------*/
/*------------      Created by : Ravinder Singh(GDC)                    --------------*/
/*------------      Last Modified on :05/15/2008                        ---------------*/

trigger GNE_CM_CaseID_Prepopulate_Appeal_level on Appeal_Level_gne__c (before insert,before update) 
{
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    
    Set<Id> appidset = new Set<Id>();
    Id prevAppealId = null ;
    Map<Id,Appeal_gne__c> Appeal_map;
        
    for(Appeal_Level_gne__c a :Trigger.new)
        { 
            try
                {
                    if (a.Appeal_ID_gne__c!=null && prevAppealId != a.Appeal_ID_gne__c )
                        {
                            appidset.add(a.Appeal_ID_gne__c);
                            prevAppealId = a.Appeal_ID_gne__c;
                        }   //end of if
                }   //end of try
            catch(exception e)
                {
                    a.adderror('Error encountered in creation of Appeal list for Appeal level' + e.getmessage());
                }   //end of catch          
        }   //end of for
        try
            {
                Appeal_map =new Map<Id, Appeal_gne__c>([select Patient_Appeal_gne__c,Product_Appeal_gne__c,Benefit_Investigation_gne__c,Case_Appeal_gne__c from Appeal_gne__c where Id in :appidset]);
            }   //end of try
        catch(exception e)
            {
                System.debug('Error encountered in SOQL' + e.getmessage());
            }   //end of catch
    
        for(Appeal_Level_gne__c a :Trigger.new)
            { 
                try
                    {
                        if (a.Appeal_ID_gne__c!=null && Appeal_map.containsKey(a.Appeal_ID_gne__c))
                            {
                                a.Benefit_Investigation_gne__c=Appeal_map.get(a.Appeal_ID_gne__c).Benefit_Investigation_gne__c;
                                a.Case_gne__c=Appeal_map.get(a.Appeal_ID_gne__c).Case_Appeal_gne__c;
                                a.Product_Appeal_level_gne__c=Appeal_map.get(a.Appeal_ID_gne__c).Product_Appeal_gne__c;
                                a.Patient_Appeal_level_gne__c = Appeal_map.get(a.Appeal_ID_gne__c).Patient_Appeal_gne__c;
                            }
                    }   //end of try
                    
                catch(Exception e)
                    {
                        a.adderror('Error encountered while filling information from Appeal to Appeal level' + e.getmessage());
                    } //end of catch
            }   //end of for    
    
    Appeal_map.clear(); //to clear the map once trigger records had been processed
    appidset.clear();   //to clear the set once trigger records had been processed  
    
} //end of trigger