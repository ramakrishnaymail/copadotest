/**
 *  Trigger that creates the association between the Organization and the ACCME for accrediation
 **/
trigger gFRS_OrganizationAccmeAssociation on GFRS_Organization__c (before insert, before update) {
	gFRS_Util.updateOrganizationAccreditationStatus( Trigger.NEW );
}