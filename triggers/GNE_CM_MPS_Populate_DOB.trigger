trigger GNE_CM_MPS_Populate_DOB on Patient_Enrollment_Request_gne__c (before insert, before update) 
{

	for(Patient_Enrollment_Request_gne__c PER:Trigger.new)
	{
			if(PER.DOB_gne__c!=null && PER.DOB_gne__c!='')
				PER.dob_mps_gne__c=date.parse(PER.DOB_gne__c);		
	}

}