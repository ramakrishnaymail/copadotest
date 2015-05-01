trigger CHV_Brand_CT_AD_DataFeedTrigger on CHV_Brand_Customer_Access_Distributor__c (after delete, after insert, after update) {
 List<CHV_Brand_Customer_Access_Distributor__c> bcdList;
 
 String action='';
 
  if(Trigger.isInsert) action = 'Create';
  else if(Trigger.isUpdate) action='Update';
   else if(Trigger.isDelete) action = 'Delete';
 
 if(action == 'Create' || action == 'Update') bcdList = Trigger.new;
    else bcdList = Trigger.old;
 
 //logic for create and update only, cause create and update only impact one record   
 if(action == 'Create' || action =='Update') {
 	CHV_Brand_Customer_Access_Distributor__c bcd;
 	CHV_Brand_Customer_Access_Distributor__c bcdOld;
 	if(bcdList !=null && bcdList.size()>0) bcd = bcdList[0];
 
 	boolean feedChange=true;
 
 	if(action=='Update') {
 		List<CHV_Brand_Customer_Access_Distributor__c> bcdListOld = Trigger.old;
 	
 		if(bcdListOld!=null && bcdListOld.size()>0) 	bcdOld=bcdListOld[0];
    
    	if(bcd!=null && bcdOld !=null && ( bcd.Authorized_Distributor__c==bcdOld.Authorized_Distributor__c && 
    		bcd.Authorized_Distributor_Note__c==bcdOld.Authorized_Distributor_Note__c &&
    		bcd.Brand_Customer_Access__c == bcdOld.Brand_Customer_Access__c))   
    			feedChange = false; 
 	}
 
 	if(bcd!=null && feedChange == true) {
 		CHV_Brand_CT_AD_His__c dataFeed = new CHV_Brand_CT_AD_His__c();
 		dataFeed.SFDC_record_ID__c = bcd.id;
 		dataFeed.Action__c = action;
 		dataFeed.Action_Time__c = system.now();
 		dataFeed.Send_to_AccessSolution__c = false;
 		dataFeed.AD_Note__c = bcd.Authorized_Distributor_Note__c;
 		dataFeed.Authorized_Distributor_Name__c =getADName(bcd.Authorized_Distributor__c);
 		Map<String, String> names=getBrandCAT(bcd.Brand_Customer_Access__c);
 		dataFeed.Brand_Name__c = names.get('Brand');
 		dataFeed.CustAccType__c = names.get('Cat');
 	
 		if(action=='Update'){
 			if(bcd.Authorized_Distributor__c!=bcdOld.Authorized_Distributor__c)
 				dataFeed.Before_Authorized_Distributor__c = getADName(bcdOld.Authorized_Distributor__c);
 		
 			if(bcd.Authorized_Distributor_Note__c != bcdOld.Authorized_Distributor_Note__c)
 				dataFeed.Before_AD_Note__c = bcdOld.Authorized_Distributor_Note__c;
 			
 			if(bcd.Brand_Customer_Access__c != bcdOld.Brand_Customer_Access__c) {
 				Map<String, String> oldnames=getBrandCAT(bcdOld.Brand_Customer_Access__c);
 				dataFeed.Before_Brand__c = oldnames.get('Brand');
 				dataFeed.Before_CustAccType__c = oldnames.get('Cat');
 			}
 			
 		}
 	
		insert dataFeed;
 	}
 }else if(action=='Delete') {
 	if(bcdList!=null && bcdList.size()>0){
 			List<CHV_Brand_CT_AD_His__c> dataFeedList = new List<CHV_Brand_CT_AD_His__c>();
 			for(CHV_Brand_Customer_Access_Distributor__c dbcd: bcdList){
 				CHV_Brand_CT_AD_His__c dataFeed = new CHV_Brand_CT_AD_His__c();
 				dataFeed.SFDC_record_ID__c = dbcd.id;
 				dataFeed.Action__c = action;
 				dataFeed.Action_Time__c = system.now();
 				dataFeed.Send_to_AccessSolution__c = false;
 				dataFeed.AD_Note__c = dbcd.Authorized_Distributor_Note__c;
 				dataFeed.Authorized_Distributor_Name__c =getADName(dbcd.Authorized_Distributor__c);
 				Map<String, String> names=getBrandCAT(dbcd.Brand_Customer_Access__c);
 				dataFeed.Brand_Name__c = names.get('Brand');
 				dataFeed.CustAccType__c = names.get('Cat');
 				dataFeedList.add(dataFeed);
 			}
 			if(dataFeedList!=null && dataFeedList.size()>0) insert dataFeedList;
 		}
 }
 
  private String getADName(String adid){
 	CHV_Authorized_Distributor__c ad=[select name from CHV_Authorized_Distributor__c where id=:adid limit 1];
 	if(ad!=null) return ad.name;
 	else return'';
 }
 
 private Map<String,String> getBrandCAT(String bcatId){
 	Map<String, String> returnStr = new Map<String, String>();
 	CHV_Brand_Customer_Access__c bcat=[select 	Brand__c, 	Customer_Access__c from CHV_Brand_Customer_Access__c where id=:bcatId limit 1];
 	if(bcat!=null) {
 		CHV_Brand__c brand =[select name from CHV_Brand__c where id=:bcat.Brand__c limit 1];
 		CHV_Customer_Access__c cat = [select name from CHV_Customer_Access__c where id=: bcat.Customer_Access__c limit 1];
 		String returnString='';
 		if(brand!=null) returnStr.put('Brand', brand.name); 
 		if(cat!=null) returnStr.put('Cat', cat.name); 
 	}
 	return returnStr;
 }
}