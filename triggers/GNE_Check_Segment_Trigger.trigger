// ************************************************************************************************************************************
// This trigger has been modified by GDC 18/2.
// LOGIC TO SET RAPTIVA_GSK_INDICATOR_gne__c.
// ************************************************************************************************************************************

trigger GNE_Check_Segment_Trigger on Transaction_File_Staging_gne__c (before insert) 
{

   Transaction_file_Staging_gne__c[] t = trigger.new;
   
   System.Debug('GNE TEST: IN TRANSACTION_FILE_STAGING_GNE__C AFTER BEFORE TRIGGER');
   
   for (integer counter=0;counter<t.size();counter++)
   { 
        if (t[counter].Segment_Id_gne__c == 1570)  // only execute if primary raptiva segment identified
        {
            
            //************ COMMENTED OUT BY GDC check segment id for RAPTIVA_GSK_INDICATOR_gne__c flag************//
            // String patientID = t[counter].Patient_Program_gne__r.Patient_gne__c; 
            // List<Patient_Program_gne__c> programList = new List<Patient_Program_gne__c>([SELECT pp.ID FROM Patient_Program_gne__c pp 
            // WHERE ( (pp.Patient_gne__c = :patientID) AND (pp.GSK_Sent_Date_gne__c Not In (NULL)) )]); 
            //************ COMMENTED OUT BY GDC check segment id for RAPTIVA_GSK_INDICATOR_gne__c flag ************//
            
            t[counter].RAPTIVA_GSK_INDICATOR_gne__c = 'Y';
            System.Debug('GSK INDICATOR TEST: IS RAPTIVA - GSK EXISTS IN PATIENT PROGRAM');
        }
        
        else if (t[counter].Segment_Id_gne__c == 803)
        {
            t[counter].RAPTIVA_GSK_INDICATOR_gne__c = 'N';
            System.Debug('GSK INDICATOR TEST: IS RAPTIVA - GSK DOES NOT EXIST IN PATIENT PROGRAM');
        }

        else
        {
            t[counter].RAPTIVA_GSK_INDICATOR_gne__c = 'N';
            System.Debug('GSK INDICATOR TEST: IS NOT RAPTIVA -- GSK DOES NOT EXIST IN PATIENT PROGRAM');
        } // not raptiva
   } // for loop   
    
 //  update t;
}