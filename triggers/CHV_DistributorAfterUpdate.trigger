trigger CHV_DistributorAfterUpdate on CHV_Authorized_Distributor__c (after update, after insert) {
	for (CHV_Authorized_Distributor__c d : Trigger.new){
		Id newManagerId = d.Account_Manager__c;
		if (CHV_Utils.isNotEmpty(newManagerId)){
			List<CHV_Account_Manager__c> m = [SELECT Id FROM CHV_Account_Manager__c WHERE Id =: newManagerId];
			if (CHV_Utils.listNotEmpty(m)){
				update (m);
			}
		}
	}
}