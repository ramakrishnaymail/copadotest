trigger GNE_CM_case_owner_populate on Case (before insert) 
{
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode()){
        return;
    }
    
    List<Case> case_list = new List<Case>();
    Set<Id> caseid=new Set<Id>();
    List<case> case_update = new List<case>();
    case case_upd = new case();
    
    try
    {
        /*for(Case cas: Trigger.new)
        {   
            caseid.add(cas.Id);
        } 
        case_list=[Select Id, OwnerId, Case_Manager__c, Foundation_Specialist_gne__c from Case where Id IN :caseid];
        
        for(integer i=0;i<case_list.size();i++)
        {
            if(case_list[i].Case_Manager__c!=null && case_list[i].OwnerId!=case_list[i].Case_Manager__c)
            {
                case_upd = case_list[i];
                case_upd.OwnerId = case_upd.Case_Manager__c;
                case_upd.After_Trigger_Flag_gne__c=true;
                case_update.add(case_upd);
            }
            else if(case_list[i].Foundation_Specialist_gne__c!=null && case_list[i].OwnerId!=case_list[i].Foundation_Specialist_gne__c)
            {
                case_upd = case_list[i];
                case_upd.OwnerId = case_upd.Foundation_Specialist_gne__c;
                case_upd.After_Trigger_Flag_gne__c=true;
                case_update.add(case_upd);
            }        
                  
        }
        try
        {   
            if(case_update.size()>0)    
                Database.update(case_update, false);
        }
        catch(DMLException ex)
        {
            for(Case casex :Trigger.new)
                casex.adderror('Error in Case manager assignment to case owner' +ex.getMessage());
           
        }*/
        for(Case cas: Trigger.new)
        {
            if(cas.Case_Manager__c!=null && cas.OwnerId != cas.Case_Manager__c)
            {
                //case_upd = case_list[i];
                cas.OwnerId = cas.Case_Manager__c;
                //cas.After_Trigger_Flag_gne__c=true;
                //case_update.add(case_upd);
            }
            else if(cas.Foundation_Specialist_gne__c != null && cas.OwnerId != cas.Foundation_Specialist_gne__c)
            {
                //case_upd = case_list[i];
                cas.OwnerId = cas.Foundation_Specialist_gne__c;
                //cas.After_Trigger_Flag_gne__c=true;
                //case_update.add(case_upd);
            }
        }
    }//end of try
    catch(exception e)
    {
       for(Case casx :Trigger.new)
       casx.adderror('Error in Case manager assignment to case owner' +e.getMessage());
    }
}