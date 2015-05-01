trigger AGS_RRCH_MinNumUpdate on AGS_Relabel_Recipient_Classification_gne__c (after update) {

    try
    {
        Map<double, AGS_Reporting_Configuration_Version__c> rvmap=new Map<double, AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvlist=new List<AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvupdatelist=new List<AGS_Reporting_Configuration_Version__c>();
        // List<String> Reportcodes=new List<String>();
        List<double> versionIDcodes=new List<double>();
        
        List<String> fieldNames = new List<String>();
          
        for(AGS_Relabel_Recipient_Classification_gne__c sc: trigger.new)
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
        
        AGS_SendEmail_ChangeInReporting ags_SendEmail = new AGS_SendEmail_ChangeInReporting();
          
        for (Integer i=0;i<trigger.size;i++) //Base_Category_Name_gne__c
        {  
            if(trigger.old[i].Label_Category_or_Credential_gne__c!=trigger.new[i].Label_Category_or_Credential_gne__c||
                trigger.old[i].Label_or_Relabel_gne__c!=trigger.new[i].Label_or_Relabel_gne__c ||
                trigger.old[i].Recipient_Category_Descriptions_gne__c !=trigger.new[i].Recipient_Category_Descriptions_gne__c ||
                trigger.old[i].Recipient_Credential_Code_gne__c!=trigger.new[i].Recipient_Credential_Code_gne__c ||
                trigger.old[i].Recipient_SubCategory_gne__c !=trigger.new[i].Recipient_SubCategory_gne__c ||
                trigger.old[i].Recipient_SubCategory_Description_gne__c !=trigger.new[i].Recipient_SubCategory_Description_gne__c||
                trigger.old[i].Relable_Case_gne__c!=trigger.new[i].Relable_Case_gne__c ||
                trigger.old[i].Relabel1_Text_gne__c != trigger.new[i].Relabel1_Text_gne__c ||
                trigger.old[i].Relabel2_Text_gne__c != trigger.new[i].Relabel2_Text_gne__c  ||
                trigger.old[i].Relabel3_Text_gne__c != trigger.new[i].Relabel3_Text_gne__c  ||
                trigger.old[i].Relabel4_Text_gne__c != trigger.new[i].Relabel4_Text_gne__c   ||
                trigger.old[i].Relabel5_Text_gne__c != trigger.new[i].Relabel5_Text_gne__c  ||
                trigger.old[i].Relabel6_Text_gne__c != trigger.new[i].Relabel6_Text_gne__c   ||
                trigger.old[i].Relabel7_Text_gne__c != trigger.new[i].Relabel7_Text_gne__c   ||
                trigger.old[i].Relabel8_Text_gne__c != trigger.new[i].Relabel8_Text_gne__c   ||
                trigger.old[i].Relabel9_Text_gne__c != trigger.new[i].Relabel9_Text_gne__c   ||
                trigger.old[i].Relabel10_Text_gne__c != trigger.new[i].Relabel10_Text_gne__c   ||
                trigger.old[i].Is_Reportable_gne__c  !=trigger.new[i].Is_Reportable_gne__c)
            
            { 
                AGS_Reporting_Configuration_Version__c rv=rvmap.get(trigger.new[i].Version_ID_gne__c);
                
                if(rv!=null)
                {
                    Integer rvint=Integer.Valueof(rv.VERSION_MINOR_NUM_gne__c);
                    rvint=rvint+1;
                    rv.VERSION_MINOR_NUM_gne__c=String.valueof(rvint);
                    // rv.Version_ID_gne__c=rv.Version_ID_gne__c+1;
                    rvupdatelist.add(rv);
                    
                    fieldNames.add('Label_Category_or_Credential_gne__c');
                    fieldNames.add('Label_or_Relabel_gne__c');
                    fieldNames.add('Recipient_Category_Descriptions_gne__c');
                    fieldNames.add('Recipient_Credential_Code_gne__c');
                    fieldNames.add('Recipient_SubCategory_gne__c');
                    fieldNames.add('Recipient_SubCategory_Description_gne__c');
                    fieldNames.add('Relable_Case_gne__c');
                    fieldNames.add('Relabel1_Text_gne__c');
                    fieldNames.add('Relabel2_Text_gne__c');
                    fieldNames.add('Relabel3_Text_gne__c');
                    fieldNames.add('Relabel4_Text_gne__c');
                    fieldNames.add('Relabel5_Text_gne__c');
                    fieldNames.add('Relabel6_Text_gne__c');
                    fieldNames.add('Relabel7_Text_gne__c');
                    fieldNames.add('Relabel8_Text_gne__c');
                    fieldNames.add('Relabel9_Text_gne__c');
                    fieldNames.add('Relabel10_Text_gne__c');
                    fieldNames.add('Is_Reportable_gne__c');

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