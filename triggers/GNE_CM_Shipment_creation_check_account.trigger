trigger GNE_CM_Shipment_creation_check_account on Shipment_gne__c (before insert,before update) 
{
    
    // skip this trigger during merge process
	if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
		return;
	}
	
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    Set<id> ship_id = new set<Id>();
    Database.saveresult[] SR;
    List<Infusion_gne__c> inf_list = new List<Infusion_gne__c>();
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig5()) // Global check for static variable to make sure trigger executes only once
    {
        //This trigger will only execute if static variable is not set
        GNE_CM_case_trigger_monitor.setTriggerInProcessTrig5(); // Setting the static variable so that this trigger does not get executed after workflow update
        
        /*******Cmne:SD-Changes done as per offshore request 340******/
        BusinessHours stdBusinessHours = [select id , Name, TuesdayStartTime, MondayStartTime ,WednesdayStartTime, ThursdayStartTime,FridayStartTime, TuesdayEndTime from businesshours where Name  = 'GNE_CM_SHIPMENTS'];
        System.debug('********id********' + stdBusinessHours + stdBusinessHours.TuesdayStartTime );
        List<Task> tsk_insert = new List<Task>();
        boolean  taskflag = false;
        Datetime DueDatetime;
        Date DueDate;
        Date ActivityDueDate;
        string Starttime;
        string Starttime_input;
        Map<String, Schema.RecordTypeInfo> TaskRecordType = new Map<String, Schema.RecordTypeInfo>();
        TaskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName();  
        ID CMTaskRecordTypeId = TaskRecordType.get('CM Task').getRecordTypeId();
        System.debug('********a1********' + CMTaskRecordTypeId  );
        
       // Clearing out shipment ids from infusions once the shipment status is updated to CL - Cancel
       if(system.trigger.isupdate)
       {
            for(shipment_gne__c ship:trigger.new)
            {
                try
                {
                    if(ship.Sent_to_ESB_gne__c == false)
                    {
                    if(ship.Status_gne__c != null && ship.Status_gne__c == 'CL - Cancel' && system.trigger.oldmap.get(ship.id).Status_gne__c != 'CL - Cancel')
                    ship_id.add(ship.id);
                    }
                }
                 catch(exception e)
                {
                    ship.adderror('Error in adding shipment ids to set'+e.getmessage());
                }
            }
            try
            {
            if(ship_id.size()>0)
                inf_list = [select id, shipment_gne__c from infusion_gne__c where shipment_gne__c in: ship_id];
            }
            catch(exception e)
            {
                for(shipment_gne__c ship:trigger.new)
                ship.adderror('Error in getting Infusion records for this shipment'+e.getmessage());
            }
            try
            {
                if(inf_list.size()>0)
                {
                    for(integer i=0;i<inf_list.size();i++)
                    inf_list[i].shipment_gne__c = null;
                    
                    SR = database.update(inf_list,false);
                    
                    for(Database.SaveResult lsr:SR)
                    {
                        if(!lsr.issuccess())
                        {  
                            string ErrorMessage = '';
                            for(integer i = 0; i<lsr.getErrors().size(); i++)
                            {
                                ErrorMessage = ErrorMessage + ' | ' + lsr.getErrors()[i].getMessage();
                            }
                            for(shipment_gne__c ship: trigger.new)
                            ship.adderror('Error in updating infusions for cancelled shipments: ' +ErrorMessage);
                        }
                    } 
                }
            }
            catch(exception e)
            {
                for(shipment_gne__c ship:trigger.new)
                ship.adderror('Error in process of updating infusions for cancelled shipments: '+e.getmessage());
            }
       }    //end of trigger.isupdate
       /*******Cmne:SD-Changes done as per offshore request 340******/
       if(system.trigger.isupdate)
        {
           
           for(Shipment_gne__c  ship : Trigger.new) 
           {    
            //Saxenam: Ignoring shipment request to create auto tasks.          
               if( ship.Case_Shipment_Request_gne__c ==null)  
                {                          
                    System.debug('ship.Shipped_From_Site_gne__c: ' + ship.Shipped_From_Site_gne__c);
                    System.debug('ship.Status_gne__c: ' + ship.Status_gne__c);
                  if(ship.Shipped_From_Site_gne__c == 'NOVAFACTOR' &&  ship.Status_gne__c == 'RE - Released'  && system.trigger.oldmap.get(ship.id).Status_gne__c != ship.Status_gne__c )
                  {
                  
                     datetime dt =  datetime.valueof(ship.Expected_Ship_Date_gne__c +  + '07:00:01');
                      DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 24 * 60 * 60 * 1000L);
                      date myDate = date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day());
                     date weekStart = myDate.toStartofWeek();
                    integer numberDays = weekStart.daysBetween(myDate );
                    If(numberDays == 1)
                    Starttime = String.valueOf(stdBusinessHours.MondayStartTime); 
                    If(numberDays == 2)
                    Starttime = String.valueOf(stdBusinessHours.TuesdayStartTime); 
                     If(numberDays == 3)
                    Starttime = String.valueOf(stdBusinessHours.WednesdayStartTime);
                     If(numberDays == 4)
                    Starttime = String.valueOf(stdBusinessHours.ThursdayStartTime);
                     If(numberDays == 5)
                    Starttime = String.valueOf(stdBusinessHours.FridayStartTime);
                    Starttime_input =  Starttime.substring(0,9);
                    
                       ship.Shipment_Delay_Date__c = datetime.valueof((String.valueof(DueDateTime)).substring(0,10) + ' ' + Starttime_input);
                       
                  }
                   if(ship.Shipped_From_Site_gne__c == 'RxCrossroads' &&  ship.Status_gne__c == 'RE - Released' && system.trigger.oldmap.get(ship.id).Status_gne__c != ship.Status_gne__c )
                  {
                      datetime dt =  ship.Released_Date_gne__c;
                      //Modified by swetak : PMorg Req #2914 to make it 5.5 hours instead of 4.5 hours
                      //DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 270  * 60 * 1000L);
                      DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 330  * 60 * 1000L);
                      System.debug('DueDatetime: ' + DueDatetime);
                      date myDate = date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day());
                      date weekStart = myDate.toStartofWeek();
                      integer numberDays = weekStart.daysBetween(myDate );
                      system.debug('*** NUMBER DAYS: ' + numberDays);
                      If(numberDays == 1)
                    Starttime = String.valueOf(stdBusinessHours.MondayStartTime); 
                    If(numberDays == 2)
                    Starttime = String.valueOf(stdBusinessHours.TuesdayStartTime); 
                     If(numberDays == 3)
                    Starttime = String.valueOf(stdBusinessHours.WednesdayStartTime);
                     If(numberDays == 4)
                    Starttime = String.valueOf(stdBusinessHours.ThursdayStartTime);
                     If(numberDays == 5)
                    Starttime = String.valueOf(stdBusinessHours.FridayStartTime);
                     Starttime_input =  Starttime.substring(0,9);
                     system.debug('**** START TIME FROM BH: ' + Starttime);
                     system.debug('*** START TIME: ' + Starttime_input);
                    
                 if(date.newinstance(ship.Released_Date_gne__c.year(), ship.Released_Date_gne__c.month(), ship.Released_Date_gne__c.day()) != date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day()))
                      {
                           system.debug('*** INSIDE IF: ');              
                           //ship.Shipment_Delay_Date__c = datetime.valueof(date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day()) + Starttime_input);
                           ship.Shipment_Delay_Date__c = datetime.valueof((String.valueof(DueDateTime)).substring(0,10) + ' ' +Starttime_input);
                       }
                      else
                      {
                            ship.Shipment_Delay_Date__c = DueDatetime; 
                            system.debug('*** INSIDE ELSE IF: ');               
                       }
                       system.debug('*** FINAL DELAY DATE TIME: ' + ship.Shipment_Delay_Date__c);
                    }
                 if(ship.Shipped_From_Site_gne__c == 'Genentech' &&  ship.Status_gne__c == 'RE - Released' && system.trigger.oldmap.get(ship.id).Status_gne__c != ship.Status_gne__c)
                  {
                              datetime dt =  ship.Released_Date_gne__c;
                       //Modified by swetak : PMorg Req #2914 to make it 2.5 hours instead of 1.5 hours
                      //DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 90  * 60 * 1000L);
                      DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 150  * 60 * 1000L);
                      date myDate = date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day());
                      date weekStart = myDate.toStartofWeek();
                     integer numberDays = weekStart.daysBetween(myDate );
                     If(numberDays == 1)
                     Starttime = String.valueOf(stdBusinessHours.MondayStartTime); 
                     If(numberDays == 2)
                     Starttime = String.valueOf(stdBusinessHours.TuesdayStartTime); 
                     If(numberDays == 3)
                     Starttime = String.valueOf(stdBusinessHours.WednesdayStartTime);
                     If(numberDays == 4)
                     Starttime = String.valueOf(stdBusinessHours.ThursdayStartTime);
                     If(numberDays == 5)
                     Starttime = String.valueOf(stdBusinessHours.FridayStartTime);
                     Starttime_input =  Starttime.substring(0,9);
        
                      if(date.newinstance(ship.Released_Date_gne__c.year(), ship.Released_Date_gne__c.month(), ship.Released_Date_gne__c.day()) != date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day()))
                          ship.Shipment_Delay_Date__c = datetime.valueof((String.valueof(DueDateTime)).substring(0,10) + ' ' + Starttime_input);              
                      else
                            ship.Shipment_Delay_Date__c = DueDatetime;               
                       
                      
                  }
                   if(ship.Shipped_From_Site_gne__c == 'RxCrossroads' &&  ship.Status_gne__c == 'RC - Received' && system.trigger.oldmap.get(ship.id).Status_gne__c != ship.Status_gne__c )
                  {
                
        
                     datetime dt =  datetime.valueof(ship.Expected_Ship_Date_gne__c + '07:00:01');
                     //Modified by swetak : PMorg Req #2914 to make it 24 hours instead of 12 hours
                      //DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 12* 60  * 60 * 1000L);
                      DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 24* 60  * 60 * 1000L);
                      date myDate = date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day());
                      date weekStart = myDate.toStartofWeek();
                     integer numberDays = weekStart.daysBetween(myDate );
                     If(numberDays == 1)
                     Starttime = String.valueOf(stdBusinessHours.MondayStartTime); 
                     If(numberDays == 2)
                     Starttime = String.valueOf(stdBusinessHours.TuesdayStartTime); 
                     If(numberDays == 3)
                     Starttime = String.valueOf(stdBusinessHours.WednesdayStartTime);
                     If(numberDays == 4)
                     Starttime = String.valueOf(stdBusinessHours.ThursdayStartTime);
                     If(numberDays == 5)
                     Starttime = String.valueOf(stdBusinessHours.FridayStartTime);
                     Starttime_input =  Starttime.substring(0,9);
        
                      ship.Shipment_Delay_Date__c = datetime.valueof((String.valueof(DueDateTime)).substring(0,10) + ' ' + Starttime_input);
         
                  }
                  if(ship.Shipped_From_Site_gne__c == 'Genentech' &&  ship.Status_gne__c == 'AL - Allocated' && system.trigger.oldmap.get(ship.id).Status_gne__c != ship.Status_gne__c )
                  {
        
                     datetime dt =  datetime.valueof(ship.Expected_Ship_Date_gne__c + '07:00:01');
                     //Modified by swetak : PMorg Req #2914 to make it 36 hours instead of 12 hours
                      //DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 12* 60  * 60 * 1000L);
                      DueDatetime = BusinessHours.addGmt(stdBusinessHours.id,dt , 36* 60  * 60 * 1000L);
                      date myDate = date.newinstance(DueDateTime.year(), DueDateTime.month(), DueDateTime.day());
                      date weekStart = myDate.toStartofWeek();
                     integer numberDays = weekStart.daysBetween(myDate );
                     If(numberDays == 1)
                     Starttime = String.valueOf(stdBusinessHours.MondayStartTime); 
                     If(numberDays == 2)
                     Starttime = String.valueOf(stdBusinessHours.TuesdayStartTime); 
                     If(numberDays == 3)
                     Starttime = String.valueOf(stdBusinessHours.WednesdayStartTime);
                     If(numberDays == 4)
                     Starttime = String.valueOf(stdBusinessHours.ThursdayStartTime);
                     If(numberDays == 5)
                     Starttime = String.valueOf(stdBusinessHours.FridayStartTime);
                     Starttime_input =  Starttime.substring(0,9);
                     ship.Shipment_Delay_Date__c = datetime.valueof((String.valueof(DueDateTime)).substring(0,10) + ' ' + Starttime_input);
        
                      
                  }
               }  //End of ship.Case_Shipment_Request_gne__c ==null            
             }  //end of Shipment_gne__c  ship : Trigger.new         
         }//end of trigger.isupdate
    }   //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig5())

}