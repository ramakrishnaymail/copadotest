trigger GNE_CM_EBI_Payer_Result_Trigger on GNE_CM_EBI_Payer_Result__c (before update)
{
	if (GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_EBI_Payer_Result_Trigger')) {
		return;
	}
	
	if (Trigger.isUpdate && Trigger.isBefore) {
		Map<Id,Attachment> fullResponses = new Map<Id,Attachment>();
		for (Attachment a : [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId IN :Trigger.newMap.keySet() ORDER BY CreatedDate DESC]) {
			if (!fullResponses.containsKey(a.ParentId) && a.Name != null && a.Name.endsWith(GNE_CM_EBI_Request_Response_Handler.FULL_RESPONSE_ATTACHMENT_SUFFIX)) {
				fullResponses.put(a.ParentId, a);
			}
		}
		for (GNE_CM_EBI_Payer_Result__c pr : Trigger.new) {
			if (fullResponses.containsKey(pr.Id)) {
				pr.Full_Response_gne__c = '/servlet/servlet.FileDownload?file=' + fullResponses.get(pr.Id).Id;
			}
		}
	}
}