//Create Shipment Request Tasks
// KM - 11/23/2009 - Added Auto task for Actemra IMPACT NOW Shipment as well.
// KS - 2/11/2011 - Added taskls for Vismodegib
/*
PK 12/5/2013 PFS-974
	Workflow "Coordinate shipment refill" creates coordinate shipment refill tasks for all other products
	Going forward for new products the tasks should be created using this trigger and not the workflow rule. 
*/
trigger GNE_CM_Create_Shipment_Request_Tasks on Shipment_gne__c (after update) 
{
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode()){
        return;
    }
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    
    Set<Id> caseidset = new Set<Id>();
    Set<Id> brafcaseidset = new Set<Id>();
    Set<Id> cobicaseidset = new Set<Id>();
    Set<Id> boomerangcaseidset = new Set<Id>();
    Set<Id> vismocaseidset = new Set<Id>();
    Map<Id, Case> Case_map = new  Map<Id, Case>(); 
    Map<Id, Case> BRAF_Case_map = new  Map<Id, Case>();
    Map<Id, Case> Cobi_Case_map = new  Map<Id, Case>();
    Map<Id, Case> Boomerang_Case_map = new  Map<Id, Case>();
    Map<Id, Case> Vismo_Case_map = new  Map<Id, Case>();
    Set<Id> Shipment_caseidset = new Set<Id>();
    Set<Id> ShipIdset = new Set<Id>();
    List<Task> tsk_insert = new List<Task>();
    Map<String, Schema.RecordTypeInfo> TaskRecordType = new Map<String, Schema.RecordTypeInfo>();
    TaskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName();
    ID CMTaskRecordTypeId = TaskRecordType.get('CM Task').getRecordTypeId();
    boolean Sent_to_ESB = true;
    List<Shipment_gne__c> AllShipments = new List<Shipment_gne__c>();
    List<Shipment_gne__c> TempShip = new List<Shipment_gne__c>();
    Map<Id, List<Shipment_gne__c>> ShipList = new Map<Id, List<Shipment_gne__c>>();
    string braf_product_name = system.label.GNE_CM_BRAF_Product_Name;
    string cobi_product_name = system.label.GNE_CM_Cotellic_Product_Name;
    string boomerang_product_name = system.label.GNE_CM_Boomerang_Product_Name;
    //KS: VISMO: 11/24/2011
    string Vismo_product_name = system.label.GNE_CM_VISMO_Product_Name;
    
    //AS TARCEVA: 05/18/2012
    string Tarceva_product_name = system.label.GNE_CM_TARCEVA_Product_Name;
    Map<Id, Case> Tarceva_Case_map = new  Map<Id, Case>();
    Set<Id> Tarcevacaseidset = new Set<Id>();
    
    //PK 11/22/2013 Added for Xolair 
    String xolairProductName = system.label.GNE_CM_Xolair_Product_Name;
    Map<Id, Case> xolairCaseMap = new  Map<Id, Case>();
    Set<Id> xolairCaseIdSet = new Set<Id>();
    
    //AS Changes : PFS-747
    Set<Id> actemraSubcutaneousShipId = new Set<Id>(); 
    Map<Id, Case> actemraSubcutaneousCase_Map = new  Map<Id, Case>();
    
    if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig4()) // Global check for static variable to make sure trigger executes only once
    {
        //This trigger will only execute if static variable is not set
        GNE_CM_case_trigger_monitor.setTriggerInProcessTrig4(); // Setting the static variable so that this trigger does not get executed after workflow update
        
        try
        {     for(Shipment_gne__c ship :Trigger.new)
            {   if(ship.Sent_to_ESB_gne__c == true && system.trigger.oldmap.get(ship.Id).Sent_to_ESB_gne__c==false )
                {}
                else 
                Sent_to_ESB = false; 
                
                if (ship.Case_Shipment_Request_gne__c != null)
                {
                    caseidset.add(ship.Case_Shipment_Request_gne__c); 
                }   //end of if    
                else if(ship.Product_gne__c == braf_product_name && ship.Case_Shipment_gne__c!=null) 
                    brafcaseidset.add(ship.Case_Shipment_gne__c);
                else if(ship.Product_gne__c == cobi_product_name && ship.Case_Shipment_gne__c!=null) 
                    cobicaseidset.add(ship.Case_Shipment_gne__c);
                else if(ship.Product_gne__c == boomerang_product_name && ship.Case_Shipment_gne__c!=null) 
                    boomerangcaseidset.add(ship.Case_Shipment_gne__c);
                //KS: 11/24/2011: Added for Vismo
                else if(ship.Product_gne__c == vismo_product_name && ship.Case_Shipment_gne__c!=null)
                    vismocaseidset.add(ship.Case_Shipment_gne__c);
                //KS: VISMO: 11/24/2011: end here
                
                //AS: 05/18/2011: Added for TARCEVA
                else if(ship.Product_gne__c == Tarceva_product_name && ship.Case_Shipment_gne__c!=null)
                    Tarcevacaseidset.add(ship.Case_Shipment_gne__c);
                //AS: TARCEVA: 05/18/2011: end here
                
                /*
                //PK Added for Xolair 11/22/2013
                //Create tasks for Upfront shipments only and only when the shipment is released.
                */
                else if(ship.Product_gne__c == xolairProductName
                		 && ship.Case_Shipment_gne__c!=null
                	 	 && ship.Action_gne__c == 'GATCF Shipment'
                	 	 && ship.Status_gne__c == 'RE - Released'
                	 	 && Trigger.oldMap.get(ship.id).Status_gne__c !='RE - Released'
                	 	 && ship.case_type_gne__c == 'GATCF - Standard Case')
                	{
                		xolairCaseIdSet.add(ship.Case_Shipment_gne__c);
                	}
                
                // KM - 11/23 - added for Actemra Auto tasks
                if(ship.Product_gne__c == 'Actemra' && ship.Action_gne__c == 'IMPACT NOW' && 
                        ship.Case_Shipment_gne__c != null && ship.Status_gne__c == 'RE - Released'
                        && system.trigger.oldmap.get(ship.id).Status_gne__c != 'RE - Released')
                {
                    Shipment_caseidset.add(ship.Case_Shipment_gne__c);
                    ShipIdset.add(ship.Id);
                }
                //AS Changes for Actemra Subcutaneous 9/2/2013
                if(ship.Product_gne__c == 'Actemra Subcutaneous' && ship.Case_Shipment_gne__c!=null)
                {
                    system.debug('JAMESTEST INSIDE ACTQID DECLARE');
                    actemraSubcutaneousShipId.add(ship.Case_Shipment_gne__c);
                }
                
            }   //end of for
            if(Sent_to_ESB == false)
            {
                if(caseidset.size()>0)
                    Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :caseidset]);
                
                if(brafcaseidset.size() >0)
                    BRAF_Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :brafcaseidset]);    

                if(cobicaseidset.size() >0)
                    Cobi_Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :cobicaseidset]);    

                if(boomerangcaseidset.size() >0)
                    Boomerang_Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :boomerangcaseidset]);    
                
                //KS: 2/11/2011: Added for Vismo
                if(vismocaseidset.size() >0)
                    Vismo_Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :vismocaseidset]);                    
                
                //KS: 05/18/2012: Added for TARCEVA
                if(Tarcevacaseidset.size() >0)
                    Tarceva_Case_map = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :Tarcevacaseidset]);                    
                
                //PK 11/22/2013 Added for Xolair
                if(xolairCaseIdSet.size() >0){
                	xolairCaseMap = new Map<Id, Case>([select patient_gne__c, RecordType.Name, Case_Treating_Physician_gne__c, Id, OwnerId from Case where Id IN :xolairCaseIdSet]);
                }
                
                //AS Changes : PFS-747
                if(actemraSubcutaneousShipId.size() > 0)
                    actemraSubcutaneousCase_Map = new Map<Id, Case>([select  RecordType.Name,Medical_History_gne__r.Route_of_Admin_gne__c,Case_Manager__c  from Case where Id IN :actemraSubcutaneousShipId]);
                
                //Logic to create tasks and assign each task to Case Owner
                
                // Loop through the Shipment Requests, creating Tasks as needed
                for (Shipment_gne__c loopShip : Trigger.new) 
                {    
                    //create Shipment Request Sent task as soon as a Shipment Request is released and assign that task to Case owner with closed status   
                    //05/05/2011 - Removed as a part of CMR3 requirement for activity type removal
                      /*if(loopShip.Status_gne__c=='RE - Released' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='RE - Released' && Case_map.containsKey(loopShip.Case_Shipment_Request_gne__c))
                    {system.debug('Check');
                        Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Shipment Request Sent', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Shipment Request Sent', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = system.today(), status='Completed');
                        tsk_insert.add(taskIns);
                        }*/
                    //05/09/2011-SB-Task for BRAF
                    if(loopShip.Product_gne__c == braf_product_name && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date braf_activitydate;
                        braf_activitydate = Date.newInstance(loopShip.Shipped_Date_gne__c.year(), loopShip.Shipped_Date_gne__c.month(), loopShip.Shipped_Date_gne__c.day());
                        braf_activitydate = braf_activitydate.addDays(7);
                        system.debug('DATECHECK::' + braf_activitydate);
                        Task taskIns = new Task (OwnerId = BRAF_Case_map.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = braf_activitydate);
                        tsk_insert.add(taskIns);
                        
                    }
                    //Rama Cotellic shipment updates
                    //Cotellic - For C&R - Task will be created when Shipped
                    if(loopShip.Product_gne__c == cobi_product_name && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date cobi_activitydate;
                        cobi_activitydate = Date.newInstance(loopShip.Shipped_Date_gne__c.year(), loopShip.Shipped_Date_gne__c.month(), loopShip.Shipped_Date_gne__c.day());
                        cobi_activitydate = cobi_activitydate.addDays(7);
                        system.debug('DATECHECK::' + cobi_activitydate);
                        Task taskIns = new Task (OwnerId = Cobi_Case_map.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = cobi_activitydate);
                        tsk_insert.add(taskIns);
                        
                    }    
                    //Cotellic - For GATCF - Task will be created when Released
                    if(loopShip.Product_gne__c == cobi_product_name && loopShip.case_type_gne__c == 'GATCF - Standard Case' && loopShip.Status_gne__c == 'RE - Released' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='RE - Released')
                    {
                        Date cobi_activitydate;
                        if(loopShip.Exhaust_Date_gne__c!=null)
                            cobi_activitydate=loopShip.Exhaust_Date_gne__c-10;
                        else 
                            cobi_activitydate=system.today();
                        system.debug('DATECHECK::' + cobi_activitydate);
                        Task taskIns = new Task (OwnerId = loopShip.OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = cobi_activitydate, Creator_Comments_gne__c='Remind patient to reference Treatment Tracker');
                        tsk_insert.add(taskIns);
                        
                    }                                        
                    //Rama Boomerang shipment updates
                    //Boomerang - For C&R - Task will be created when Shipped
                    if(loopShip.Product_gne__c == boomerang_product_name && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date boomerang_activitydate;
                        boomerang_activitydate = Date.newInstance(loopShip.Shipped_Date_gne__c.year(), loopShip.Shipped_Date_gne__c.month(), loopShip.Shipped_Date_gne__c.day());
                        boomerang_activitydate = boomerang_activitydate.addDays(7);
                        system.debug('DATECHECK::' + boomerang_activitydate);
                        Task taskIns = new Task (OwnerId = Boomerang_Case_map.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = boomerang_activitydate);
                        tsk_insert.add(taskIns);
                        
                    }                    
                    //Boomerang - For GATCF - Task will be created when Released
                    if(loopShip.Product_gne__c == boomerang_product_name && loopShip.case_type_gne__c == 'GATCF - Standard Case' && loopShip.Status_gne__c == 'RE - Released' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='RE - Released')
                    {
                        Date boomerang_activitydate;
                        if(loopShip.Exhaust_Date_gne__c!=null)
                            boomerang_activitydate=loopShip.Exhaust_Date_gne__c-10;
                        else 
                            boomerang_activitydate=system.today();
                        system.debug('DATECHECK::' + boomerang_activitydate);
                        Task taskIns = new Task (OwnerId = loopShip.OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = boomerang_activitydate, Creator_Comments_gne__c='Please coordinate Shipment Refill');
                        tsk_insert.add(taskIns);
                        
                    }                                        
                    //KS: VISMO: 11/24/2011
                    if(loopShip.Product_gne__c == vismo_product_name && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date vismo_activitydate;
                        vismo_activitydate = Date.newInstance(loopShip.Shipped_Date_gne__c.year(), loopShip.Shipped_Date_gne__c.month(), loopShip.Shipped_Date_gne__c.day());
                        vismo_activitydate = vismo_activitydate.addDays(7);
                        system.debug('DATECHECK::' + vismo_activitydate);
                        Task taskIns = new Task (OwnerId = Vismo_Case_map.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = vismo_activitydate);
                        tsk_insert.add(taskIns);
                        
                    }
                    //KS: VISMO: 11/24/2011: end here
                     
                    
                    //AS: TARCEVA: 05/19/2012
                    if(loopShip.Product_gne__c == Tarceva_product_name && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date Tarceva_activitydate;
                        Tarceva_activitydate = Date.newInstance(loopShip.Shipped_Date_gne__c.year(), loopShip.Shipped_Date_gne__c.month(), loopShip.Shipped_Date_gne__c.day());
                        Tarceva_activitydate = Tarceva_activitydate.addDays(7);
                        Task taskIns = new Task (OwnerId = Tarceva_Case_map.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = Tarceva_activitydate);
                        tsk_insert.add(taskIns);
                        
                    }
                    //AS: TARCEVA: 05/19/2012: end here
                    
                    /*
                    PK Added for Xolair 11/22/2013
                    Create these tasks for Upfront shipments only and only when the shipment is released.
                    
                    Follow up task
					1 - if blank ados, Task Due = createdDate + 28
					2a - if (medical_history_gne__c.freq_of_administration = 4), Task Due = (ADOS + 7)
					2b - if (medical_history_gne__c.freq_of_administration = 2), Task Due = (ADOS + 17)
					
					Coordinate Shipment Refill task
					3 - if blank ados, Task Due = createdDate + 28 + 7
					4a - if (medical_history_gne__c.freq_of_administration = 4), Task Due = (ADOS + 14)
					4b - if (medical_history_gne__c.freq_of_administration = 2), Task Due = (ADOS + 24)
                    */
                    if(loopShip.Product_gne__c == xolairProductName
                    	&& !xolairCaseMap.isEmpty())
                    {
                    	
                        Date followupOnInfusionDate,coordinateShipmentRefillDate;
                        if(loopShip.Anticipated_Next_DOS__c!=null){
                        	if(loopShip.Dose_Frequency_in_weeks_gne__c=='Every 4 weeks'){
	                        	followupOnInfusionDate = loopShip.Anticipated_Next_DOS__c.addDays(7);
	                        	coordinateShipmentRefillDate = loopShip.Anticipated_Next_DOS__c.addDays(14);
                        	}else if(loopShip.Dose_Frequency_in_weeks_gne__c=='Every 2 weeks'){
	                        	followupOnInfusionDate = loopShip.Anticipated_Next_DOS__c.addDays(17);
	                        	coordinateShipmentRefillDate = loopShip.Anticipated_Next_DOS__c.addDays(24);
                        	}//end if-else on Dose_Frequency_in_weeks_gne__c
                        }else{
                        	coordinateShipmentRefillDate = System.today().addDays(35);
                        	followupOnInfusionDate = System.today().addDays(28);
                        }//end if-else on Anticipated_Next_DOS__c
                        Task coordinateShipmentRefillTask = new Task (OwnerId = xolairCaseMap.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = coordinateShipmentRefillDate);
                        tsk_insert.add(coordinateShipmentRefillTask);
                        
                        Task followUpOnInfusionTask = new Task (OwnerId = xolairCaseMap.get(loopShip.Case_Shipment_gne__c).OwnerId, Subject = 'Follow up on Infusion/Injection Records', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Follow up on Infusion/Injection Records',Description= (loopShip.Anticipated_Next_DOS__c!=null?loopShip.Anticipated_Next_DOS__c.format():''), Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = followupOnInfusionDate);
                        tsk_insert.add(followUpOnInfusionTask);
                    }
                    
                    //create Review Shipment Status task assigned to Case Owner when shipment status is updated with value "Cancelled", "Returned", or "Withdrwn". --refer to defect ID 7478 in MQC
                    
                    if(loopShip.Status_gne__c!=null && (loopShip.Status_gne__c == 'CL - Cancel' || loopShip.Status_gne__c == 'RT - Return' || loopShip.Status_gne__c == 'WD - Withdrawn') && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!=loopShip.Status_gne__c && Case_map.containsKey(loopShip.Case_Shipment_Request_gne__c))
                    {
                        Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Review Shipment Status', WhatId = loopShip.Id,
                        Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Review Shipment Status', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = system.today());
                        tsk_insert.add(taskIns);
                    }

                    //JH MOVE CODE INTO BLOCK ABOVE
                    //AS Changes : PFS-747 4/9/2013
                    if(loopShip.Product_gne__c == 'Actemra Subcutaneous' && loopShip.case_type_gne__c == 'C&R - Standard Case' && loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null)
                    {
                        Date ActemraSub_activitydate;
                        ActemraSub_activitydate = loopShip.Expected_Ship_Date_gne__c.addDays(5);
                        system.debug('ACTQMAP IS: '+actemraSubcutaneousCase_Map);
                        Task taskIns = new Task (Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,OwnerId =actemraSubcutaneousCase_Map.get(loopShip.Case_Shipment_gne__c).Case_Manager__c,
                        Case_Id_gne__c = loopShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = ActemraSub_activitydate);
                        tsk_insert.add(taskIns);
                    }
                    //AS Changes : PFS-747 End Here 

                    //create a task when shipment info is returned from vendor and Shipment Status=Shipped and Shipped Date is not null and Qty Shipped is not null. 
                    //For Xolair, this task would be created after a first and second shipment request. For Nutropin, trigger this task for all services requested.
                    //SB-10/09/2009, Modified activity types as per Kishore's mail for each services requested values
                    Date activity_date;
                    if(loopShip.Exhaust_Date_gne__c!=null)
                    activity_date=loopShip.Exhaust_Date_gne__c-10;
                    else 
                    activity_date=system.today();
                    
                    if(loopShip.Status_gne__c == 'SH - Shipped' && system.trigger.oldmap.get(loopShip.Id).Status_gne__c!='SH - Shipped' && loopShip.Shipped_Date_gne__c!=null && loopShip.Qty_Shipped_gne__c!=null && Case_map.containsKey(loopShip.Case_Shipment_Request_gne__c))
                    {
                        if(loopShip.Product_gne__c=='Xolair' || loopShip.Product_gne__c=='Nutropin') 
                        {      
                            if(loopShip.Services_Requested_gne__c=='Initial Shipment')
                            {          
                                Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Coordinate 2nd Supply for Continuous Care Program', WhatId = loopShip.Id,
                                Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Coordinate 2nd Supply for Continuous Care Program', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date);
                                tsk_insert.add(taskIns);
                            }
                            else if(loopShip.Services_Requested_gne__c=='2nd Shipment')
                            {
                                Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Coordinate 3rd Supply for Continuous Care Program', WhatId = loopShip.Id,
                                Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Coordinate 3rd Supply for Continuous Care Program', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date);
                                tsk_insert.add(taskIns);
                            }
                            
                            if(loopShip.Product_gne__c=='Nutropin')
                            {
                                if(loopShip.Services_Requested_gne__c=='3rd Shipment')
                                {          
                                    Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Coordinate Shipment Refill', WhatId = loopShip.Id,
                                    Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Coordinate Shipment Refill', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date, Creator_Comments_gne__c='Coordinate Addl Shipment');
                                    tsk_insert.add(taskIns);
                                }
                                else if(loopShip.Services_Requested_gne__c=='Appeal Shipment')
                                {          
                                    Task taskIns = new Task (OwnerId = Case_map.get(loopShip.Case_Shipment_Request_gne__c).OwnerId, Subject = 'Coordinate Appeals Supply for Continuous Care Program', WhatId = loopShip.Id,
                                    Case_Id_gne__c = loopShip.Case_Shipment_Request_gne__c, Activity_Type_gne__c = 'Coordinate Appeals Supply for Continuous Care Program', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date);
                                    tsk_insert.add(taskIns);
                                }
                            }
                        }                                        
                    } 
                }//end of for      
                
                // KM - 11/23 - Added For Actemra Shipments
                if(Shipment_caseidset.size()>0)
                {   
                    AllShipments = [Select Status_gne__c, Released_Date_gne__c, Shipped_Date_gne__c, Case_Shipment_gne__c, OwnerId From Shipment_gne__c 
                    where Released_Date_gne__c != null and Case_Shipment_gne__c IN :Shipment_caseidset
                    and Product_gne__c = 'Actemra' and Action_gne__c = 'IMPACT NOW'
                    and Id NOT IN :ShipIdset];
                    
                    // Making a map of <Case Id, <list of associated shipped Actemra Impact Now shipments>>
                    for(integer t = 0; t <AllShipments.size(); t++)
                    {
                        if(ShipList.containsKey(AllShipments[t].Case_Shipment_gne__c))
                        {
                            TempShip = ShipList.get(AllShipments[t].Case_Shipment_gne__c);
                            ShipList.remove(AllShipments[t].Case_Shipment_gne__c);
                            TempShip.add(AllShipments[t]);
                            ShipList.put(AllShipments[t].Case_Shipment_gne__c, TempShip);
                        } // End of If
                        else
                        {
                            TempShip.clear();
                            TempShip.add(AllShipments[t]);
                            ShipList.put(AllShipments[t].Case_Shipment_gne__c, TempShip);
                        }   // End of Else
                    } // End of for
                    
                    for (Shipment_gne__c NShip: Trigger.new)
                    {
                        Date activity_date;
                        if(NShip.Exhaust_Date_gne__c!=null)
                        activity_date=NShip.Exhaust_Date_gne__c-10;
                        if(!ShipList.containsKey(NShip.Case_Shipment_gne__c))
                        {
                            Task taskIns = new Task (OwnerId = NShip.OwnerId, Subject = 'Coordinate 2nd Supply for Continuous Care Program', WhatId = NShip.Id,
                            Case_Id_gne__c = NShip.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate 2nd Supply for Continuous Care Program', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date);
                            tsk_insert.add(taskIns);
                        }
                    }
                    for (Shipment_gne__c Ship: Trigger.new)
                    {
                        Date activity_date;
                        if(Ship.Exhaust_Date_gne__c!=null)
                        activity_date=Ship.Exhaust_Date_gne__c-10;
                        if(ShipList.containsKey(Ship.Case_Shipment_gne__c))
                        {
                            if(ShipList.get(Ship.Case_Shipment_gne__c).size() == 1)
                            { // task for third refill
                                Task taskIns = new Task (OwnerId = Ship.OwnerId, Subject = 'Coordinate 3rd Supply for Continuous Care Program', WhatId = Ship.Id,
                                Case_Id_gne__c = Ship.Case_Shipment_gne__c, Activity_Type_gne__c = 'Coordinate 3rd Supply for Continuous Care Program', Process_Category_gne__c = 'Managing a Case', RecordTypeId=CMTaskRecordTypeId, ActivityDate = activity_date);
                                tsk_insert.add(taskIns);
                            }
                            ShipList.remove(Ship.Case_Shipment_gne__c);
                        }
                    }
                }                                           
                //insert new tasks     
                if(tsk_insert.size()>0)
                {
                	GNE_CM_Static_Flags.setFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
                	try 
                	{
                Database.insert(tsk_insert, false);
            } 
                	finally 
                	{
                		GNE_CM_Static_Flags.unsetFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
                	}
                }
            } 
        } // end of global try
        catch(exception e)
        {
            for (Shipment_gne__c Ship: Trigger.new)
            {
                Ship.adderror('Processing for the Shipment Request record stopped! Unexpected Error in getting the Shipment Request related information from other objects: ' + e.getMessage());
            }
        }
        
        caseidset.clear();
        Case_map.clear(); 
        tsk_insert.clear();
        AllShipments.clear();
        TempShip.clear();
        ShipList.clear();
    }  //end of if(!GNE_CM_case_trigger_monitor.triggerIsInProcessTrig4())        
    
    if(trigger.isAfter && trigger.isUpdate){
        List<Task> tsk_list=new List<Task>();
        List<Case> caseList=new List<Case>();
        Id TaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
        caseList=[select id,GATCF_Status_gne__c,CreatedById from Case where id=:trigger.new[0].Case_Shipment_gne__c];  
        for(Shipment_gne__c ship: Trigger.new){
            //AS : 05/22/2012 Check CaseList Size
            if(caseList.size() > 0 && caseList != null)
            {
                if(trigger.oldMap.get(ship.id).Status_gne__c != 'RE - Released' && ship.Case_Type_gne__c=='GATCF - Standard Case' && caseList[0].GATCF_Status_gne__c=='Approved - Contingent Enrollment' && ship.Status_gne__c=='RE - Released')
                {   
                    system.debug('Inside If---->');
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = ship.Case_Shipment_gne__c, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: Contingent Shipment Coordinated',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    tsk_list.add(taskInsertEC);
                }
                if(trigger.oldMap.get(ship.id).Status_gne__c != 'RE - Released' && ship.Case_Type_gne__c=='GATCF - Standard Case' && caseList[0].GATCF_Status_gne__c != 'Approved - Contingent Enrollment' && ship.Status_gne__c == 'RE - Released')
                {   
                    system.debug('Inside If---->');
                    Task taskInsertEC = new Task (OwnerId =  UserInfo.getUserId(), 
                                            WhatId = ship.Case_Shipment_gne__c, 
                                            ActivityDate = system.today(), 
                                            Activity_Type_gne__c = 'GATCF Service Update: GATCF Shipment Coordinated',
                                            Process_Category_gne__c = 'Access to Care',
                                            Status = 'Completed',
                                            RecordTypeId = TaskRecTypeId 
                                            );                        
                    tsk_list.add(taskInsertEC);
                }
            }            
        }
        for(Task t:tsk_list){
        	System.debug('---task to insert----'+t);
        }
        
        if(tsk_list != null && tsk_list.size() > 0) {
            
            GNE_CM_Static_Flags.setFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
            try {
            insert tsk_list;
            }finally {
            	GNE_CM_Static_Flags.unsetFlag(GNE_CM_Static_Flags.TASKS_UPSERT_IN_TRIGGER);
}
            
        }
    }
    
}