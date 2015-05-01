trigger GNE_CM_inactiveDateProfileIDLicense on ProfileID_License_gne__c (before insert, before update) 
{
	if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isMergeMode()){
	    for(ProfileID_License_gne__c record : Trigger.new)
	    {
	       if(record.ID_License_Status_gne__c == 'Inactive' && record.Date_Inactive_gne__c == null)
	       {
	           record.Date_Inactive_gne__c =system.today();
	       }
	       else if(record.ID_License_Status_gne__c != 'Inactive' && record.Date_Inactive_gne__c != null)
	       {
	           record.Date_Inactive_gne__c = null;
	       } 
	       // GDC - 4/1/2009 - Moved this condition from else if to if, changed the comparison with system.today() to have == 
	       // intsead of <= and also set the date inactive to Expiration date + 1.
	       if(record.Expiration_Date_gne__c == date.today() && record.ID_License_Status_gne__c != 'Inactive'  && record.Date_Inactive_gne__c == null)
	       {
	            record.Date_Inactive_gne__c = record.Expiration_Date_gne__c + 1;
	       }
	   } 
   }
}