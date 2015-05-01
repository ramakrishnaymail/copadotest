/*******************************************************************************
Name : GNE_CM_DOS_Stamping_ApplLvl
Created on: 11/17/2008
Created By: GDC
The trigger was created to refresh the value of #DOS field as Appeal level
when a DOS record is deleted.
*******************************************************************************/
trigger GNE_CM_DOS_Stamping_ApplLvl on Date_of_Service_gne__c (after delete) 
{
    Id PrevAppealLevelId = null;
    Set<Id> appidset = new Set<Id>(); 
    Map<Id, Appeal_Level_gne__c> Appeal_Level_map;
    List<Appeal_Level_gne__c> Appeal_Level = new List<Appeal_Level_gne__c>();
    Appeal_Level_gne__c AppLvl;
    String AppLvlFound;
    
    try
    {    
        for(Date_of_Service_gne__c a :Trigger.old)
        {
            if (a.Appeal_Level_gne__c != null && a.Appeal_Level_gne__c != PrevAppealLevelId)
            {
                appidset.add(a.Appeal_Level_gne__c);
                PrevAppealLevelId = a.Appeal_Level_gne__c;
            }   //end of if
        }   //end of for   
        
        Appeal_Level_map = new Map<Id, Appeal_Level_gne__c>([select Id, DOS_gne__c from Appeal_Level_gne__c where Id in : appidset]);
        for(Date_of_Service_gne__c d :Trigger.old)
        {   
            if (d.Appeal_Level_gne__c!=null)
            {             
                if(Appeal_Level_map.containsKey(d.Appeal_Level_gne__c))
                {
                    AppLvl = new Appeal_Level_gne__c();
                    AppLvl  = Appeal_Level_map.get(d.Appeal_Level_gne__c);
                    AppLvl.DOS_gne__c = AppLvl.DOS_gne__c - 1;
                    Appeal_Level_map.remove(d.Appeal_Level_gne__c);
                    Appeal_Level_map.put(AppLvl.Id, AppLvl);
                    
                    AppLvlFound = 'N';
                    for(integer k=0; k<Appeal_Level.size(); k++)
                    {
                        if(Appeal_Level[k].Id == d.Appeal_Level_gne__c)
                        {
                            AppLvlFound = 'Y';
                            Appeal_Level[k] = Appeal_Level_map.get(d.Appeal_Level_gne__c);
                        }
                    }
                    if (AppLvlFound!= 'Y')
                        Appeal_Level.add(AppLvl);
                }
            }   //end of if d.Appeal_Level_gne__c is not null 
        } //end of for  
        update(Appeal_Level); 
        Appeal_Level_map.clear(); 
        Appeal_Level.clear();  //to clear the map once trigger records had been processed
        appidset.clear();   //to clear the set once trigger records had been processed 
    }// end of try
    catch(Exception e)
    {
        for(Date_of_Service_gne__c d :Trigger.old)
        { 
            d.adderror('Error encountered while updating associated Appeal Level:' + e.getmessage());
        } // end of for
    }   //end of catch
}