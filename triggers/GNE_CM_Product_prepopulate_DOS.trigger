/*------------      Name of trigger : GNE_CM_Product_prepopulate_DOS   --------------*/
/*------------      Created by : Ravinder Singh(GDC)                    --------------*/
/*------------      Last Modified on :05/15/2008                        ---------------*/
/*------------      Last Modified: 11/17/2008: Kapila Monga : Stamping of #DOS field on Appeal level.
************************************************************************************/

trigger GNE_CM_Product_prepopulate_DOS on Date_of_Service_gne__c (before insert, before update) 
{
   
   //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
   
   
    Id PrevAppealLevelId = null;
    Set<Id> appidset = new Set<Id>(); 
    Map<Id, Appeal_Level_gne__c> Appeal_Level_map;
    
    // For # of DOS Stamping
    List<Date_of_Service_gne__c> DOSRecords = new List<Date_of_Service_gne__c>();
    List<Appeal_Level_gne__c> Appeal_Level = new List<Appeal_Level_gne__c>();
    Appeal_Level_gne__c AppLvl;
    Integer NumOfDos;
    String AppLvlFound;
    
    try
    {    
        for(Date_of_Service_gne__c a :Trigger.new)
        {
            if (a.Appeal_Level_gne__c != null && a.Appeal_Level_gne__c != PrevAppealLevelId)
            {
                appidset.add(a.Appeal_Level_gne__c);
                PrevAppealLevelId = a.Appeal_Level_gne__c;
            }   //end of if
        }   //end of for   
        Appeal_Level_map = new Map<Id, Appeal_Level_gne__c>([select DOS_gne__c, Patient_Appeal_level_gne__c,Case_gne__c,Product_Appeal_level_gne__c from Appeal_Level_gne__c where Id in : appidset]);
        
        // For #DOS stamping
        DOSRecords = [select Id, Appeal_Level_gne__c from Date_of_Service_gne__c where Appeal_Level_gne__c in :appidset];
    
        for(Date_of_Service_gne__c d :Trigger.new)
        {   
            NumOfDOS = 0;
            if (d.Appeal_Level_gne__c!=null)
            {
                if(d.Appeal_Level_gne__c != null && Appeal_Level_map.containsKey(d.Appeal_Level_gne__c))    
                {
                    d.Product_gne__c=Appeal_Level_map.get(d.Appeal_Level_gne__c).Product_Appeal_level_gne__c;
                    d.Case_gne__c=Appeal_Level_map.get(d.Appeal_Level_gne__c).Case_gne__c;
                    d.Patient_DOS_gne__c = Appeal_Level_map.get(d.Appeal_Level_gne__c).Patient_Appeal_level_gne__c;
                 }   //end of else Appeal_Level_map.containsKey
                 
                 for(integer i=0; i< DOSRecords.size(); i++)
                 {
                    if(DOSRecords[i].Appeal_Level_gne__c == d.Appeal_Level_gne__c)
                        NumOfDOS = NumOfDos+1;
                 }
                
                if(Appeal_Level_map.containsKey(d.Appeal_Level_gne__c))
                {
                    AppLvlFound = 'N';
                    AppLvl = new Appeal_Level_gne__c();
                    AppLvl = Appeal_Level_map.get(d.Appeal_Level_gne__c);
                    if(Trigger.isInsert)
                        AppLvl.DOS_gne__c = NumOfDOS + 1;
                    else
                        AppLvl.DOS_gne__c = NumOfDOS;
                    for(integer k=0; k<Appeal_Level.size(); k++)
                    {
                        if(Appeal_Level[k].Id == d.Appeal_Level_gne__c)
                        {
                            AppLvlFound = 'Y';
                            Appeal_Level[k].DOS_gne__c = Appeal_Level[k].DOS_gne__c + 1;
                        }
                    }
                    if (AppLvlFound!= 'Y')
                        Appeal_Level.add(AppLvl);
                }
            }   //end of if d.Appeal_Level_gne__c is not null 
        } //end of for  
        update(Appeal_Level); 
        Appeal_Level_map.clear();   //to clear the map once trigger records had been processed
        appidset.clear();   //to clear the set once trigger records had been processed 
    }// end of try
    catch(Exception e)
    {
        for(Date_of_Service_gne__c d :Trigger.new)
        { 
            d.adderror('Error encountered:' + e.getmessage());
        } // end of for
    }   //end of catch
}   //end of trigger