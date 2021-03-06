trigger AGS_ReportingFrequency_MinNumUpdate on AGS_Reporting_Frequency_gne__c (after update) { 

    try
    {
        Map<double, AGS_Reporting_Configuration_Version__c> rvmap=new Map<double, AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvlist=new List<AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvupdatelist=new List<AGS_Reporting_Configuration_Version__c>();
        // List<String> Reportcodes=new List<String>();
        List<double> versionIDcodes=new List<double>();
        
        List<String> fieldNames = new List<String>();
             
        for(AGS_Reporting_Frequency_gne__c sc: trigger.new)
        {
            versionIDcodes.add(sc.Version_ID_gne__c);
        }
        
        system.debug('versionIDcodes ' +versionIDcodes);
        
        rvlist =[Select Id,Report_Code_gne__c,VERSION_MINOR_NUM_gne__c,Version_ID_gne__c from AGS_Reporting_Configuration_Version__c where Version_ID_gne__c in :versionIDcodes];
        for(AGS_Reporting_Configuration_Version__c rv:rvlist)
        {
            rvmap.put(rv.Version_ID_gne__c,rv);    
        }
        system.debug('rvmap  '+rvmap);
        //for(AGS_Spend_Classification__c sc: trigger.new)
        
        AGS_SendEmail_ChangeInReporting ags_SendEmail = new AGS_SendEmail_ChangeInReporting();
        
        for (Integer i=0;i<trigger.size;i++)
        {  
            if(trigger.old[i].REPORTING_FREQUENCY_TYPE_gne__c !=trigger.new[i].REPORTING_FREQUENCY_TYPE_gne__c )        
            { 
                AGS_Reporting_Configuration_Version__c rv=rvmap.get(trigger.new[i].Version_ID_gne__c);
                
                if(rv!=null)
                {
                    Integer rvint=Integer.Valueof(rv.VERSION_MINOR_NUM_gne__c);
                    rvint=rvint+1;
                    rv.VERSION_MINOR_NUM_gne__c=String.valueof(rvint);
                    // rv.Version_ID_gne__c=rv.Version_ID_gne__c+1;
                    rvupdatelist.add(rv);
                    
                    fieldNames.add('Allocation_Comment_gne__c');
                    fieldNames.add('Allocation_Method_Description_gne__c');
                        
                    ags_SendEmail.getAffectedRecords(trigger.old[i], trigger.new[i], fieldNames, rvint);
                }
            }
        }
        
        system.debug('rvupdatelist ' +rvupdatelist);
        update rvupdatelist;
    }
    catch( Exception e)
    {
    }
    

}