trigger GNE_CM_PatientEnrollmentRequestTrigger on Patient_Enrollment_Request_gne__c (before insert, after insert, before update, after update, before delete, after delete) 
{
	GNE_CM_TriggerFactory.createAndExecuteHandler(Patient_Enrollment_Request_gne__c.SObjectType);
}