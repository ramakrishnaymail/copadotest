trigger LWO_Update_ShiptoName on Product_Order_Address_gne__c (before insert, before update) {

SET<ID> orders = new SET<ID>();
List<Product_Order_gne__c> orderlist = new List<Product_Order_gne__c>();
Map<ID,String> ship_to_name_map = new Map<ID,String>();
Map<ID,String> ship_to_number_map = new Map<ID,String>();

for(Product_Order_Address_gne__c praddress: trigger.new)
{
   if(praddress.Billing__c==false && praddress.Billto_Shipto_Name__c!=null &&  praddress.SAP_Address_ID__c!=null)
   {	
   	ship_to_name_map.put(praddress.Order__c,praddress.Billto_Shipto_Name__c);
   	ship_to_number_map.put(praddress.Order__c,praddress.SAP_Address_ID__c);
   	
    orders.add(praddress.order__c);
   }
   
 }
  
   for(Product_Order_gne__c order: [select id,ship_to_Name__c,Ship_to_Number__c from Product_Order_gne__c where id in : orders])
   {
   	order.Ship_to_Number__c=ship_to_number_map.get(order.id);
   	order.Ship_to_Name__c=ship_to_name_map.get(order.id);
   	orderlist.add(order);
   }

  if(orderlist.size()>0)
  {
  	try{
  		update orderlist;
  	   }
  	catch (Exception e ){
  		System.debug('upsert failed');
  	}
  }
}