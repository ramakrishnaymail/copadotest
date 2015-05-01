trigger GNE_CM_Fax_Metric_TAT on Fax_Reporting_Metrics_gne__c (before insert,before update) {


     Map<Id, DateTime> TAT_Start_Date = new Map<Id, DateTime>();
     Map<Id, DateTime> TAT_End_Date = new Map<Id, DateTime>(); 
     Map<Id,Map<String, Decimal>> TaskBusinessValuesMap = new Map<Id,Map<String, Decimal>>(); 
     Map<String, Decimal> TaskBusinessValues = new  Map<String, Decimal>(); 
     GNE_CM_Businesshours_Calc bhoursobj = new GNE_CM_Businesshours_Calc();
     
   if( (Trigger.isBefore)) { 
        
    for(Fax_Reporting_Metrics_gne__c faxRep : Trigger.New){     
    TAT_Start_Date.put(faxRep.Activity_ID_gne__c, faxRep.TAT_Start_Date_gne__c);
    TAT_End_Date.put(faxRep.Activity_ID_gne__c, Datetime.now());            
    }   
    
    if(TAT_Start_Date != null && TAT_Start_Date.Size() > 0 && TAT_End_Date != null && TAT_End_Date.Size() > 0)
            {

               TaskBusinessValuesMap = bhoursobj.CalculateBusinessHoursMapsinMinutes(TAT_Start_Date, TAT_End_Date); 
                
            }
            
    

    for(Fax_Reporting_Metrics_gne__c newfaxRep : Trigger.New){  
    
    try
    {    
        TaskBusinessValues = TaskBusinessValuesMap.get(newfaxRep.Activity_ID_gne__c);   
        
            
        newfaxRep.TAT_End_Date_gne__c = DateTime.now();
        newfaxRep.TAT_In_Mins_gne__c = TaskBusinessValues.get('TotalNofBmins');
        newfaxRep.TAT_In_Hours_gne__c = TaskBusinessValues.get('TotalNofBHours');
        newfaxRep.Staff_Credited_gne__c = UserInfo.getName(); 
    }
    catch(exception ex)
    {
        newfaxRep.adderror('An error occured while Inserting Fax Reporting Record ' + ex.getMessage());
    }
      
    }
  } 
}