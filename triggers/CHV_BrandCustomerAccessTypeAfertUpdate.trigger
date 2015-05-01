trigger CHV_BrandCustomerAccessTypeAfertUpdate on CHV_Brand_Customer_Access__c (after insert, after update) {
	for (CHV_Brand_Customer_Access__c d : Trigger.new){
		if (CHV_Utils.isNotEmpty(d.Customer_Access__c)){
			List<CHV_Customer_Access__c> dd = [SELECT Id FROM CHV_Customer_Access__c WHERE Id =: d.Customer_Access__c];
			if (CHV_Utils.listNotEmpty(dd)){
				update(dd);
			}
		}
	}
}