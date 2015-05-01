trigger LWO_OptIn_Orders_Lookup_Trigger on LWO_OptIn_Orders_Lookup__c (before insert) {
	//detech duplicates
	List <LWO_OptIn_Orders_Lookup__c> newOrders=Trigger.new;
	LWO_OptIn_Orders_Lookup__c newOrder;
	if(newOrders!=null && newOrders.size()>0) newOrder=newOrders[0];
	List<LWO_OptIn_Orders_Lookup__c> dups= [select id, External_System_Name__c, SAP_Order_Id__c from LWO_OptIn_Orders_Lookup__c 
			where SAP_Order_Id__c=:newOrder.SAP_Order_Id__c and External_System_Name__c=:newOrder.External_System_Name__c];
	//find dup
	if(dups!=null && dups.size()>0) {
		newOrder.addError('A record for this External System and SAP order ID already exists.');
	}
}