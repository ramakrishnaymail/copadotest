//**************************
// GDC - 04/07/2009 - Created to set the Date Inactive field to the Date when the record was set to Inactive for the
// frist time. 
//**************************

trigger GNE_CM_special_prg_trg on Special_Program_gne__c (before insert, before update) 
{

    // SFA2 bypass
    if(GNE_SFA2_Util.isAdminMode()) {
        return;
    }
    
    for(Special_Program_gne__c sp : Trigger.new) 
      {
          if (sp.Date_Un_Enrolled_gne__c > Date.Today())
          {
              sp.Date_Inactive_gne__c = null;
          }
          else
          {
              sp.Date_Inactive_gne__c = sp.Date_Un_Enrolled_gne__c;
          }
      }
}