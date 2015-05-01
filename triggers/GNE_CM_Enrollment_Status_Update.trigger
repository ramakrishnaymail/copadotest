trigger GNE_CM_Enrollment_Status_Update on Case (before insert , after insert) 
{
    // skip this trigger during merge process
    if(GNE_SFA2_Util.isMergeMode() || GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_Enrollment_Status_Update')){
        system.debug('GNE_CM_Enrollment_Status_Update SKIPPED');
        return;
    }
  
    Set<Id> Enrollment_Id_Set=new Set<Id>();
    List<Patient_Enrollment_request_gne__c> Enrollment_List_Update = new List<Patient_Enrollment_request_gne__c>();
    
    //Changes BY AS:19th June 2013
    List<BRC_RituxanRA_Archive__c> lstBRCArchToUpdate   = new List<BRC_RituxanRA_Archive__c>();
    for(Case cas :Trigger.new)
    {
        try
        {
            if(cas.patient_enrollment_request_gne__c != null)
                Enrollment_Id_Set.add(cas.patient_enrollment_request_gne__c);
        }
        catch(Exception e)
        {
            cas.adderror('Error encountered while creating Patient Enrollment Request set' +e.getmessage());
        }   //end of catch
     } //end of for 
   if(trigger.isBefore)
   {
     try
     {
       if( Enrollment_Id_Set.size()>0)
             Enrollment_List_Update = new List<Patient_Enrollment_request_gne__c>([select Date_Intake_Processed_gne__c,status__c from patient_enrollment_request_gne__c where status__c != 'Processed by Intake' 
                                                                                     and id IN :Enrollment_Id_Set]);
          if(Enrollment_List_Update.size()>0)
          {
              for(integer i=0;i<Enrollment_List_Update.size();i++)
              {
                  Enrollment_List_Update[i].status__c = 'Processed by Intake';
                  Enrollment_List_Update[i].Date_Intake_Processed_gne__c = System.now();
              }
              update (Enrollment_List_Update);
           }
     }
     catch(Exception e)
       {
           for(case cas:trigger.new)
              cas.adderror('Error encountered while updating Enrollment Request status '+e.getmessage());
       }   //end of catch
   }
     if(trigger.isAfter)
     {
        try
        {
           List<BRC_RituxanRA_Archive__c> lstBRCArch = [Select id , Reverification_Case_gne__c ,PER_id_gne__c from BRC_RituxanRA_Archive__c where PER_id_gne__c in :Enrollment_Id_Set];
           for(Case cas:trigger.new)
           {
               system.debug('-------------------cas.Patient_Enrollment_Request_gne__c'+cas.Patient_Enrollment_Request_gne__c);
               system.debug('-------------------cas.CaseNumber'+cas.CaseNumber);
               if(lstBRCArch != null && lstBRCArch.size() > 0)
          {
            for(BRC_RituxanRA_Archive__c BRC : lstBRCArch)
            {
              if(BRC.PER_id_gne__c == cas.Patient_Enrollment_Request_gne__c)
              {
                BRC.Reverification_Case_gne__c = cas.CaseNumber;
                lstBRCArchToUpdate.add(BRC);
              }
            }
          }
           }
           system.debug('-------------------lstBRCArchToUpdate'+lstBRCArchToUpdate);
      if(lstBRCArchToUpdate != null && lstBRCArchToUpdate.size() > 0)
      {
        update lstBRCArchToUpdate;
      }
        }catch(exception ex){
          
        }
     }
}