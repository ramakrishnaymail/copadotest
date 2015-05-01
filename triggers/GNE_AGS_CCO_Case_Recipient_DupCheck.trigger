trigger GNE_AGS_CCO_Case_Recipient_DupCheck on AGS_CCO_Case_Recipient_gne__c (before insert) {
	
	List<String> mdm_id_list = new List<String>();
	
	for (AGS_CCO_Case_Recipient_gne__c recp : trigger.new) {
		mdm_id_list.add(recp.Name);
	}
	
	
	List<AGS_CCO_Case_Recipient_gne__c> recp_list = new List<AGS_CCO_Case_Recipient_gne__c>([select id from AGS_CCO_Case_Recipient_gne__c where Name in :mdm_id_list]);
	
	System.assert (recp_list.size() == 0, 'Error - Duplicate MDM Ids have been found while trying to insert new AGS Recipients.');
	
}