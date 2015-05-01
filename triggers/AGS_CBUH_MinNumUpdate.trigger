trigger AGS_CBUH_MinNumUpdate on AGS_Contact_Business_Unit_gne__c (after update) {

    try
    {
        Map<double, AGS_Reporting_Configuration_Version__c> rvmap=new Map<double, AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvlist=new List<AGS_Reporting_Configuration_Version__c>();
        List<AGS_Reporting_Configuration_Version__c > rvupdatelist=new List<AGS_Reporting_Configuration_Version__c>();
        // List<String> Reportcodes=new List<String>();
        List<double> versionIDcodes=new List<double>();
        
        List<String> fieldNames = new List<String>();
          
        for(AGS_Contact_Business_Unit_gne__c sc: trigger.new)
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
         
        for (Integer i=0;i<trigger.size;i++)
        {  
            if(trigger.old[i].BUSINESS_UNIT_ADDRESS_LANE_1_TEXT_gne__c!=trigger.new[i].BUSINESS_UNIT_ADDRESS_LANE_1_TEXT_gne__c ||
                trigger.old[i].BUSINESS_UNIT_ADDRESS_LANE_2_TEXT_gne__c!=trigger.new[i].BUSINESS_UNIT_ADDRESS_LANE_2_TEXT_gne__c ||
                trigger.old[i].BUSINESS_UNIT_ADDRESS_LANE_3_TEXT_gne__c!=trigger.new[i].BUSINESS_UNIT_ADDRESS_LANE_3_TEXT_gne__c ||
                trigger.old[i].BUSINESS_UNIT_ADDRESS_LANE_4_TEXT_gne__c!=trigger.new[i].BUSINESS_UNIT_ADDRESS_LANE_4_TEXT_gne__c ||
                trigger.old[i].BUSINESS_UNIT_CITY_NAME_gne__c!=trigger.new[i].BUSINESS_UNIT_CITY_NAME_gne__c ||
                trigger.old[i].BUSINESS_UNIT_EMAIL_ADDRESS_TEXT_gne__c!=trigger.new[i].BUSINESS_UNIT_EMAIL_ADDRESS_TEXT_gne__c ||
                trigger.old[i].BUSINESS_UNIT_FAX_NUM_gne__c!=trigger.new[i].BUSINESS_UNIT_FAX_NUM_gne__c ||
                trigger.old[i].Business_Unit_Name_gne__c!=trigger.new[i].Business_Unit_Name_gne__c ||
                trigger.old[i].Business_Unit_Phone_Number_gne__c!=trigger.new[i].Business_Unit_Phone_Number_gne__c ||
                trigger.old[i].BUSINESS_UNIT_POSTALZIP_CODE_gne__c!=trigger.new[i].BUSINESS_UNIT_POSTALZIP_CODE_gne__c ||
                trigger.old[i].BUSINESS_UNIT_STATE_CODE_gne__c!=trigger.new[i].BUSINESS_UNIT_STATE_CODE_gne__c ||
                trigger.old[i].CONACT_ADDRESS_LANE_1_TEXT_gne__c!=trigger.new[i].CONACT_ADDRESS_LANE_1_TEXT_gne__c ||
                trigger.old[i].CONACT_ADDRESS_LANE_2_TEXT_gne__c!=trigger.new[i].CONACT_ADDRESS_LANE_2_TEXT_gne__c ||
                trigger.old[i].CONACT_ADDRESS_LANE_3_TEXT_gne__c!=trigger.new[i].CONACT_ADDRESS_LANE_3_TEXT_gne__c ||
                trigger.old[i].CONACT_ADDRESS_LANE_4_TEXT_gne__c!=trigger.new[i].CONACT_ADDRESS_LANE_4_TEXT_gne__c ||
                trigger.old[i].CONACT_CITY_NAME_gne__c!=trigger.new[i].CONACT_CITY_NAME_gne__c ||
                trigger.old[i].CONTACT_EMAIL_ADDRESS_gne__c!=trigger.new[i].CONTACT_EMAIL_ADDRESS_gne__c ||
                trigger.old[i].CONTACT_FAX_NUM_gne__c!=trigger.new[i].CONTACT_FAX_NUM_gne__c ||
                trigger.old[i].Contact_First_Name_gne__c!=trigger.new[i].Contact_First_Name_gne__c ||
                trigger.old[i].Contact_Last_Name_gne__c!=trigger.new[i].Contact_Last_Name_gne__c ||
                trigger.old[i].Contact_Middle_Initial_gne__c!=trigger.new[i].Contact_Middle_Initial_gne__c ||
                trigger.old[i].CONTACT_PHONE_NUMBER_gne__c!=trigger.new[i].CONTACT_PHONE_NUMBER_gne__c ||
                trigger.old[i].CONTACT_POSTALZIP_CODE_gne__c!=trigger.new[i].CONTACT_POSTALZIP_CODE_gne__c ||
                trigger.old[i].CONACT_STATE_CODE_gne__c!=trigger.new[i].CONACT_STATE_CODE_gne__c ||
                trigger.old[i].Contact_Suffix_Name_gne__c!=trigger.new[i].Contact_Suffix_Name_gne__c ||
                trigger.old[i].CONTACT_TITLE_gne__c!=trigger.new[i].CONTACT_TITLE_gne__c ||
                trigger.old[i].Division_Name_gne__c!=trigger.new[i].Division_Name_gne__c ||
                trigger.old[i].Formulary_Inclusion_End_Date_gne__c!=trigger.new[i].Formulary_Inclusion_End_Date_gne__c ||
                trigger.old[i].Formulary_Inclusion_Start_Date_gne__c!=trigger.new[i].Formulary_Inclusion_Start_Date_gne__c ||
                trigger.old[i].Generic_Indicator_gne__c!=trigger.new[i].Generic_Indicator_gne__c ||
                trigger.old[i].Generic_Name_gne__c!=trigger.new[i].Generic_Name_gne__c ||
                trigger.old[i].Is_Reportable_gne__c!=trigger.new[i].Is_Reportable_gne__c ||
                trigger.old[i].Lic_Number_gne__c!=trigger.new[i].Lic_Number_gne__c ||
                trigger.old[i].Source_System_Date_gne__c !=trigger.new[i].Source_System_Date_gne__c)
            
            { 
                
                AGS_Reporting_Configuration_Version__c rv=rvmap.get(trigger.new[i].Version_ID_gne__c);
                
                if(rv!=null)
                {
                    Long rvint=Long.Valueof(rv.VERSION_MINOR_NUM_gne__c);
                    rvint=rvint+1;
                    rv.VERSION_MINOR_NUM_gne__c=String.valueof(rvint);
                    //rv.Version_ID_gne__c=rv.Version_ID_gne__c+1;
                    rvupdatelist.add(rv);
                    
                    
                    fieldNames.add('BUSINESS_UNIT_ADDRESS_LANE_1_TEXT_gne__c');
                    fieldNames.add('BUSINESS_UNIT_ADDRESS_LANE_2_TEXT_gne__c');
                    fieldNames.add('BUSINESS_UNIT_ADDRESS_LANE_3_TEXT_gne__c');
                    fieldNames.add('BUSINESS_UNIT_ADDRESS_LANE_4_TEXT_gne__c');
                    fieldNames.add('BUSINESS_UNIT_CITY_NAME_gne__c');
                    fieldNames.add('BUSINESS_UNIT_EMAIL_ADDRESS_TEXT_gne__c');
                    fieldNames.add('BUSINESS_UNIT_FAX_NUM_gne__c');
                    fieldNames.add('Business_Unit_Phone_Number_gne__c');
                    fieldNames.add('BUSINESS_UNIT_POSTALZIP_CODE_gne__c');
                    fieldNames.add('BUSINESS_UNIT_STATE_CODE_gne__c');
                    fieldNames.add('CONACT_ADDRESS_LANE_1_TEXT_gne__c');
                    fieldNames.add('CONACT_ADDRESS_LANE_2_TEXT_gne__c');
                    fieldNames.add('CONACT_ADDRESS_LANE_3_TEXT_gne__c');
                    fieldNames.add('CONACT_ADDRESS_LANE_4_TEXT_gne__c');
                    fieldNames.add('CONACT_CITY_NAME_gne__c');
                    fieldNames.add('CONTACT_EMAIL_ADDRESS_gne__c');
                    fieldNames.add('CONTACT_FAX_NUM_gne__c');
                    fieldNames.add('Contact_First_Name_gne__c');
                    fieldNames.add('Contact_Last_Name_gne__c');
                    fieldNames.add('Contact_Middle_Initial_gne__c');
                    fieldNames.add('CONTACT_PHONE_NUMBER_gne__c');
                    fieldNames.add('CONTACT_POSTALZIP_CODE_gne__c');
                    fieldNames.add('CONACT_STATE_CODE_gne__c');
                    fieldNames.add('Contact_Suffix_Name_gne__c');
                    fieldNames.add('CONTACT_TITLE_gne__c');
                    fieldNames.add('Division_Name_gne__c');
                    fieldNames.add('Formulary_Inclusion_End_Date_gne__c');
                    fieldNames.add('Formulary_Inclusion_Start_Date_gne__c');
                    fieldNames.add('Generic_Indicator_gne__c');
                    fieldNames.add('Generic_Name_gne__c');
                    fieldNames.add('Is_Reportable_gne__c');
                    fieldNames.add('Lic_Number_gne__c');
                    fieldNames.add('Source_System_Date_gne__c');
                    
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