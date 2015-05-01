//Name of trigger : GNE_CM_Update_Appeal_ClosedDate
//Created by : Ravinder Singh(GDC)
//Last Modified on :04/16/2008

trigger GNE_CM_Update_Appeal_ClosedDate on Case (before update) 
{
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode()){
        return;
    }

   //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
   
    Set<Id> caseidset = new Set<Id>();
    Id prevCaseId = null ;
    List<Appeal_gne__c> apps =new List<Appeal_gne__c>(); 
    List<Alerts_gne__c> alerts_list =new List<Alerts_gne__c>();
     for (Case Cs : Trigger.New)
        {
            if (Cs.Status.startsWith('Closed') && prevCaseId!= Cs.Id && !System.trigger.oldmap.get(Cs.Id).Status.startsWith('Closed'))
                    {
                        caseidset.add(Cs.Id);
                        prevCaseId = Cs.Id;                 
                    }   //end of if Cs.Status is Closed
        }   //end of for 
    
    if(caseidset.size()>0) 
    {  
    apps = new List<Appeal_gne__c>([SELECT id, Name, Date_Case_Closed_to_Appeals_gne__c, Case_Appeal_gne__c, Initial_Referral_to_Appeals_gne__c FROM Appeal_gne__c WHERE Case_Appeal_gne__c in :caseidset]); 
    alerts_list = new List<Alerts_gne__c>([SELECT id, status_gne__c from alerts_gne__c where case_gne__c IN: caseidset and status_gne__c <> 'Closed']);
    }
    
    for (integer i=0; i<apps.size(); i++)
        {           
            //modified for Offshore Requests....requested by David So
            Date date_case_closed;
            Datetime get_case_closed_date;
            
            if(apps.get(i).Date_Case_Closed_to_Appeals_gne__c != null)
            {
                get_case_closed_date = apps.get(i).Date_Case_Closed_to_Appeals_gne__c;
                date_case_closed = date.newinstance(get_case_closed_date.year(), get_case_closed_date.month(), get_case_closed_date.day());
            }
             
              if(apps.get(i).Date_Case_Closed_to_Appeals_gne__c == null)
                 {
                   Trigger.newMap.get(apps.get(i).Case_Appeal_gne__c).adderror('Date Case Closed to Appeals cannot be null for Appeal: '+apps.get(i).Name +'. Please make the required changes to Appeal before closing case.'); 
                 }
              else if(apps.get(i).Date_Case_Closed_to_Appeals_gne__c > System.now())
                 {
                   Trigger.newMap.get(apps.get(i).Case_Appeal_gne__c).adderror('Date Case Closed to Appeals cannot be greater than todays date for Appeal: '+apps.get(i).Name +'. Please make the required changes to Appeal before closing case.'); 
                 }
              else if(apps.get(i).Initial_Referral_to_Appeals_gne__c > date_case_closed)
                 {
                 Trigger.newMap.get(apps.get(i).Case_Appeal_gne__c).adderror('Date Case Closed to Appeals cannot be earlier than Initial Referral to Appeals for Appeal: '+apps.get(i).Name +'. Please make the required changes to Appeal before closing case.');
                 }

        }
    
    for(integer j=0;j<alerts_list.size();j++)
    {
        alerts_list[j].status_gne__c = 'Closed';
    }
    
    if(apps.size()>0)    
    update apps;
    
    if(alerts_list.size()>0)    
    update alerts_list;
    
    caseidset.clear();  //to clear the set
    
}   //end of trigger