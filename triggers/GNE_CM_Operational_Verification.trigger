// AJ 7/26/2013 : Created for Operational Verification  
trigger GNE_CM_Operational_Verification on Case (before insert , after insert)
{
    System.debug('[RK] Entered trigger');
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode())
    {
        return;
    }
    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_Operational_Verification'))
    {
        return;
    }        
    if (trigger.isBefore)
    {
        System.debug('[RK] Is Before');
        Set<String> Inf_OV_productSet = new Set<String>();
        Set<String> Fin_OV_productSet = new Set<String>();
        Set<String> Ins_OV_productSet = new Set<String>();
        Integer Financial_n;
        Integer Insurance_n;
        Integer Infusion_n;
        Id gatcfRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('GATCF - Standard Case').getRecordTypeId();

        /* All Environments Env Var*/
        /*
        List<Environment_Variables__c> envList= new List<Environment_Variables__c>();
        List<String> envNameList = new List<String> { 'Product List for Infusion OV', 'Product List for Financial OV', 'Product List for Insurance OV' };
        envList = [select id, key__c , value__c from Environment_Variables__c where key__c in: envNameList];
        */
        String environment = GNE_CM_MPS_CustomSettingsHelper.self().getMPSConfig().get(GNE_CM_MPS_CustomSettingsHelper.CM_MPS_CONFIG).Environment_Name__c;
        
        Map<String, String> productListForOv = new Map<String, String>();
  		for(GNE_CM_Product_List_for_Financial_OV__c envVar : GNE_CM_Product_List_for_Financial_OV__c.getAll().values())
  		{
			if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all')
			{
		    	productListForOv.put('GNE_CM_Product_List_for_Financial_OV__c', envVar.Value__c);
		    }
		}
		
		for(GNE_CM_Product_List_for_Infusion_OV__c envVar : GNE_CM_Product_List_for_Infusion_OV__c.getAll().values())
		{
			if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all')
			{
		    	productListForOv.put('GNE_CM_Product_List_for_Infusion_OV__c', envVar.Value__c);
		    }
		}
		
		for(GNE_CM_Product_List_for_Insurance_OV__c envVar : GNE_CM_Product_List_for_Insurance_OV__c.getAll().values())
		{
			if(envVar.Environment__c == environment || envVar.Environment__c.toLowerCase() == 'all')
			{
		    	productListForOv.put('GNE_CM_Product_List_for_Insurance_OV__c', envVar.Value__c);
		    }
		}
        
        /* Establish the current interval (n for each criteria) and the current count for each criteria on the config object
         * -Most recent config record, in case of duplicates
         */
        List<Operational_Verification_gne__c> ovList = [
            SELECT 
                id, 
                name, 
                FIN_Count_gne__c, 
                INF_Count_gne__c, 
                INS_Count_gne__c, 
                /* These are the n values */
                OV_Interval_FIN_gne__c,
                OV_Interval_INF_gne__c,
                OV_Interval_INS_gne__c
            FROM
                Operational_Verification_gne__c
            ORDER BY
                CreatedDate DESC                
            LIMIT 1
        ];
        
        /* NPE check for our config object */
        if(ovList == null || (ovList != null && ovList.size() == 0))
        {
            ovList = new List<Operational_Verification_gne__c>();
            Operational_Verification_gne__c ovRecord = new Operational_Verification_gne__c();
            ovRecord.FIN_Count_gne__c = 0;
            ovRecord.INF_Count_gne__c = 0;
            ovRecord.INS_Count_gne__c = 0; 
            ovRecord.OV_Interval_FIN_gne__c = 25;
            ovRecord.OV_Interval_INF_gne__c = 25;
            ovRecord.OV_Interval_INS_gne__c =25 ;
            ovList.add(ovRecord);                
            insert ovList;
       }  
       
       /* Establish Products affected by OV in Environment Variables */
       /* 
       for(Environment_Variables__c env : envList) {
            if(env.key__c == 'Product List for Infusion OV')
            {
                Inf_OV_productSet = new Set<String>(env.value__c.split(','));
            }
            if(env.key__c == 'Product List for Financial OV')
            {
                Fin_OV_productSet = new Set<String>(env.value__c.split(','));
            }
            if(env.key__c == 'Product List for Insurance OV')
            {
                Ins_OV_productSet = new Set<String>(env.value__c.split(','));
            }
       }
       */
        
        if(productListForOv.containsKey('GNE_CM_Product_List_for_Infusion_OV__c'))
        {
        	Inf_OV_productSet = new Set<String>(productListForOv.get('GNE_CM_Product_List_for_Infusion_OV__c').split(','));
        }
        
        if(productListForOv.containsKey('GNE_CM_Product_List_for_Financial_OV__c'))
        {
        	Fin_OV_productSet = new Set<String>(productListForOv.get('GNE_CM_Product_List_for_Financial_OV__c').split(','));
        }
        
        if(productListForOv.containsKey('GNE_CM_Product_List_for_Insurance_OV__c'))
        {
        	Ins_OV_productSet = new Set<String>(productListForOv.get('GNE_CM_Product_List_for_Insurance_OV__c').split(','));
        }
         
        /* Cast n values from our configuration object */
        Financial_n = (ovList[0].OV_Interval_FIN_gne__c).intValue();
        Insurance_n = (ovList[0].OV_Interval_INS_gne__c).intValue();
        Infusion_n = (ovList[0].OV_Interval_INF_gne__c).intValue();
        /* Begin OV Mechanism */
        for (Case cas :Trigger.new)
        {        
            system.debug('cas.RecordType.Name----->'+cas.RecordType.Name);
            system.debug('cas.RecordTypeId----->'+cas.RecordTypeId);               
            if (cas.RecordTypeId == gatcfRecordTypeId && cas.case_referral_reason_gne__c != null && cas.Product_gne__c!=null)
                {
                    /* Begin Financial Checking and record keeping */
                    if(Fin_OV_productSet.contains(cas.Product_gne__c))
                    {
                        if(ovList[0].FIN_Count_gne__c < (Financial_n-1))
                        {
                            ovList[0].FIN_Count_gne__c++;
                        }
                        // Zero indexed count
                        else if(ovList[0].FIN_Count_gne__c == (Financial_n-1))
                        {
                            cas.Is_Marked_for_FIN_OV_gne__c = true;                       
                            ovList[0].FIN_Count_gne__c = 0;
                        }
                    }
                    /* Begin Insurance Checking and record keeping */
                    if(Ins_OV_productSet.contains(cas.Product_gne__c) && (cas.case_referral_reason_gne__c == 'GATCF Referral - Insurance Denied' || cas.case_referral_reason_gne__c == 'Restart Therapy' || cas.case_referral_reason_gne__c =='Reverification'))
                    {
                        if(ovList[0].INS_Count_gne__c < (Insurance_n-1))
                        {
                            ovList[0].INS_Count_gne__c++;
                        }
                        // Zero indexed count
                        else if(ovList[0].INS_Count_gne__c == (Insurance_n-1))
                        {
                            cas.Is_Marked_for_INS_OV_gne__c = true;
                            ovList[0].INS_Count_gne__c = 0;
                        }
                    }
                    
                }
            /* Begin Infusion/Injection Checking and record keeping */  
            if(cas.RecordTypeId == gatcfRecordTypeId && cas.Product_gne__c!=null)
            {
                if(Inf_OV_productSet.contains(cas.Product_gne__c))
                {
                    if(ovList[0].INF_Count_gne__c < (Infusion_n-1))
                    {
                        ovList[0].INF_Count_gne__c++;
                    }
                    // Zero indexed count
                    else if(ovList[0].INF_Count_gne__c == (Infusion_n-1))
                    {
                        cas.Is_Marked_for_INF_OV_gne__c = true;
                        ovList[0].INF_Count_gne__c = 0;
                    }
                }
            }   
        }
        
        System.debug('[RK] Updating======'+ovList[0]);
        try {
           update ovList[0];
        } catch(DmlException ex) {
           //Log the Error so we are not obstructing the Creation of the case itself
            system.debug('Error occured while updating Opertational Verification record: ' + ex.getStackTraceString());
            GNE_CM_MPS_Utils.createAndLogErrors(new List<Database.SaveResult>(), 'Error occured while updating Opertational Verification record', new List<String>{GlobalUtils.getExceptionDescription(ex)}, 'Case', 'GNE_CM_Operational_Verification',null);
        }
        System.debug('[RK] Updated');
    }     
    
    if(trigger.isAfter)
    {                        
        List<Task> tskList = new List<Task>();
        Id cmTaskRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('CM Task').getRecordTypeId();
        
        for(Case cas : trigger.new) {
            Datetime dt = cas.CreatedDate;
            Date dueDate = date.newinstance(dt.year(), dt.month(), dt.day());
            if(cas.Is_Marked_for_FIN_OV_gne__c == true){
                Task t = new Task(
                    RecordTypeId = cmTaskRecordTypeId, 
                    Subject = 'Verification Needed - Financial', 
                    whatid = cas.id,  
                    Status = 'Not Started', 
                    Priority = 'Normal' , 
                    ActivityDate = dueDate.addDays(45), 
                    Activity_Type_gne__c = 'Verification Needed - Financial', 
                    Process_Category_gne__c = 'Access to Care',
                    OwnerId = cas.Foundation_Specialist_gne__c, 
                    Case_ID_gne__c=cas.id
                );
                tskList.add(t);
            }
            if(cas.Is_Marked_for_INS_OV_gne__c == true){
                Task t = new Task(
                    RecordTypeId = cmTaskRecordTypeId, 
                    Subject = 'Verification Needed - Insurance', 
                    whatid = cas.id ,  
                    Status = 'Not Started', 
                    Priority = 'Normal' , 
                    ActivityDate = dueDate.addDays(45), 
                    Activity_Type_gne__c = 'Verification Needed - Insurance', 
                    Process_Category_gne__c = 'Access to Care',
                    OwnerId = cas.Foundation_Specialist_gne__c, 
                    Case_ID_gne__c=cas.id
                );
                tskList.add(t);
            }
            if(cas.Is_Marked_for_INF_OV_gne__c == true){
                Task t = new Task(
                    RecordTypeId = cmTaskRecordTypeId,
                    Subject = 'Verification Needed - Infusion/Injection',
                    whatid = cas.id ,  
                    Status = 'Not Started', 
                    Priority = 'Normal' , 
                    ActivityDate = dueDate.addMonths(12), 
                    Activity_Type_gne__c = 'Verification Needed - Infusion/Injection', 
                    Process_Category_gne__c = 'Access to Care', 
                    OwnerId = cas.Foundation_Specialist_gne__c, 
                    Case_ID_gne__c=cas.id
                );
                tskList.add(t);
            }
        }
        System.debug('[RK] Inserting');                     
        insert tskList;
        System.debug('[RK] Inserted');
    }
}