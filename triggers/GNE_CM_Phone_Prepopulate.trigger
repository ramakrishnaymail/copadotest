trigger GNE_CM_Phone_Prepopulate on Patient_Address_gne__c (before insert) 
{    
    Set<Id> patidset = new Set<Id> ();
    Map<Id, Patient_gne__c> Patient_Map = new Map<Id, Patient_gne__c>();
    List<Patient_Address_gne__c > Patient_Address = new List<Patient_Address_gne__c >();
    Patient_Address = [select Id, Name, Patient_gne__c from Patient_Address_gne__c where Patient_gne__c =: trigger.new[0].Patient_gne__c];    
    
    if(trigger.isinsert && Patient_Address.size() == 0)
    {               
        for(Patient_Address_gne__c patAdd : Trigger.new)
        {
            try
            {   
                if (patAdd.Patient_gne__c != null)
                {
                    patidset.add(patAdd.Patient_gne__c);                
                }
            }
            catch(exception e)
            {
                patAdd.adderror('Error encountered in creation of pat address list' + e.getmessage());
            }
        }
        
        try
        {
            Patient_Map = new Map<Id, Patient_gne__c>([select Id, pat_home_phone_gne__c, pat_work_phone_gne__c, pat_other_phone_gne__c, pat_other_phone_type_gne__c from Patient_gne__c where Id in: patidset]);        
        }
        catch(exception e)
        {
            for(Patient_Address_gne__c patAddr : Trigger.new)
            {
                patAddr.adderror('Error encountered in creation of pat address list' + e.getmessage());
            }
        } 
        try
        {
            for(Patient_Address_gne__c patAddress :trigger.new)
            {
                if((patAddress.Phone_gne__c == null || patAddress.Phone_gne__c == '') && (patAddress.Other_Phone_gne__c == null || patAddress.Other_Phone_gne__c == ''))
                {
                    if((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != ''))
                    {
                        system.debug('Point 11..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Home';
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = 'Work';
                    }
                    if((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != ''))
                    {
                        system.debug('Point 12..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Home';
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = 'Work';
                    }
                    else if((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c != null || Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c != ''))
                    {
                        system.debug('Point 13..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Home';
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c;
                    }
                    else if((Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c != null || Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c != ''))
                    {
                        system.debug('Point 14..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Work';
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c;
                    }
                    else if(Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '')
                    {
                        system.debug('Point 15..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Home';
                        patAddress.Other_Phone_gne__c = '';
                        patAddress.Other_Phone_Type_gne__c = '';
                    }
                    else if(Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != '')
                    {
                        system.debug('Point 16..........');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Work';
                        patAddress.Other_Phone_gne__c = '';
                        patAddress.Other_Phone_Type_gne__c = '';
                    }
                    else if(Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != '')
                    {
                        system.debug('Point 17..........');
                        // setting the value of other field on pat address when the user has entered other phone value on pat rec
                        patAddress.Phone_gne__c = '';
                        patAddress.Phone_Type_gne__c  = '';
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c;
                        
                    }
                }
                
                // Phone on patient address is not null starts here
                else if((patAddress.Phone_gne__c != null || patAddress.Phone_gne__c != '') && (patAddress.Other_Phone_gne__c == null || patAddress.Other_Phone_gne__c == ''))
                {
                    if(Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '')
                    {
                        system.debug('Point 22......11....');
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = 'Home';
                    }
                    else if((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != ''))
                    {
                        system.debug('Point 22........12..');
                        patAddress.Other_Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c = 'Work';
                    }
                    else if ((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != ''))
                    {
                        system.debug('Point 22........13..');
                        patAddress.Other_Phone_gne__c  = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c;
                        patAddress.Other_Phone_Type_gne__c  = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c;
                    }
                }
                // patient phone not null ends here
                
                // patient address other phone field is not null starts here
                else if((patAddress.Phone_gne__c == null || patAddress.Phone_gne__c == '') && (patAddress.Other_Phone_gne__c != null || patAddress.Other_Phone_gne__c != ''))
                {
                    if(Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c != '')
                    {
                        system.debug('Point 33......11....');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Home';
                    }
                    else if((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c != ''))
                    {
                        system.debug('Point 33........12..');
                        patAddress.Phone_gne__c = Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c;
                        patAddress.Phone_Type_gne__c = 'Work';
                    }
                    else if ((Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_home_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c == null || Patient_Map.get(patAddress.Patient_gne__c).pat_work_phone_gne__c == '') && (Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != null && Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c != ''))
                    {
                        system.debug('Point 33........13..');
                        patAddress.Phone_gne__c  = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_gne__c;
                        patAddress.Phone_Type_gne__c  = Patient_Map.get(patAddress.Patient_gne__c).pat_other_phone_type_gne__c;
                    }
                }
                // patient address other phone field is not null ends here
            }
        }
        catch(exception e)
        {
            system.debug('ERROR WHILE UPDATING PHONE FIELDS' + e.getMessage()); 
        }
    }
}