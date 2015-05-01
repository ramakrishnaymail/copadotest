trigger CHV_BrandCustAccessDistAfterUpdate on CHV_Brand_Customer_Access_Distributor__c (after insert, after update) {
	for (CHV_Brand_Customer_Access_Distributor__c d : Trigger.new){
		if (CHV_Utils.isNotEmpty(d.Authorized_Distributor__c)){
			List<CHV_Authorized_Distributor__c> dd = [SELECT Id FROM CHV_Authorized_Distributor__c WHERE Id =: d.Authorized_Distributor__c];
			if (CHV_Utils.listNotEmpty(dd)){
				update (dd);
			}
		}
	}
}