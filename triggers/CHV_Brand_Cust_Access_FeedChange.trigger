trigger CHV_Brand_Cust_Access_FeedChange on CHV_Brand_Customer_Access__c (after insert, after delete, after update) 
{
 List<CHV_Brand_Customer_Access__c> bcdList;
 
 String action='';
 
  if(Trigger.isInsert) action = 'Create';
  else if(Trigger.isUpdate) action='Update';
   else if(Trigger.isDelete) action = 'Delete';
 
 if(action == 'Create' || action == 'Update') bcdList = Trigger.new;
    else bcdList = Trigger.old;
    
 //logic for create or update, create and update only impact single record
 if(action=='Create' || action=='Update') {
    CHV_Brand_Customer_Access__c bcd;
 	CHV_Brand_Customer_Access__c bcdOld;
 	if(bcdList !=null && bcdList.size()>0) bcd = bcdList[0];
 
 	boolean feedChange=true;
 
 	if(action=='Update') {
 		List<CHV_Brand_Customer_Access__c> bcdListOld = Trigger.old;
 	
 		if(bcdListOld!=null && bcdListOld.size()>0) 	bcdOld=bcdListOld[0];
    
    	if(bcd!=null && bcdOld !=null && ( bcd.Brand__c==bcdOld.Brand__c && 
    		bcd.Customer_Access__c==bcdOld.Customer_Access__c))   
    			feedChange = false; 
 	}
 
 	if(bcd!=null && feedChange == true) {
 		CHV_Band_Cust_Access_History__c dataFeed = new CHV_Band_Cust_Access_History__c();
 		dataFeed.SFDC_record_ID__c = bcd.id;
 		dataFeed.Action__c = action;
 		dataFeed.Action_Time__c = system.now();
 		dataFeed.SentToAccessSolution__c = false;
 		dataFeed.Brand_Name__c = getBrandName(bcd.Brand__c);
 		dataFeed.Customer_Access_Type__c = getCustAccTypeName(bcd.Customer_Access__c);
 	
 		if(action=='Update'){
 		
 			if(bcd.Brand__c != bcdOld.Brand__c)
 				dataFeed.Before_Brand__c =getBrandName(bcdOld.Brand__c);
 			
 			if(bcd.Customer_Access__c != bcdOld.Customer_Access__c) 
 				dataFeed.Before_CustAccType__c = getCustAccTypeName(bcdOld.Customer_Access__c); 			
 		}
 	
		insert dataFeed;
 	}
 }else if(action=='Delete'){
 		if(bcdList!=null && bcdList.size()>0){
 			List<CHV_Band_Cust_Access_History__c> dataFeedList = new List<CHV_Band_Cust_Access_History__c>();
 			for(CHV_Brand_Customer_Access__c dbcd: bcdList){
 				CHV_Band_Cust_Access_History__c dataFeed = new CHV_Band_Cust_Access_History__c();
 				dataFeed.SFDC_record_ID__c = dbcd.id;
 				dataFeed.Action__c = action;
 				dataFeed.Action_Time__c = system.now();
 				dataFeed.SentToAccessSolution__c = false;
 				dataFeed.Brand_Name__c = getBrandName(dbcd.Brand__c);
 				dataFeed.Customer_Access_Type__c = getCustAccTypeName(dbcd.Customer_Access__c);
 				dataFeedList.add(dataFeed);
 			}
 			if(dataFeedList!=null && dataFeedList.size()>0) insert dataFeedList;
 		}
 	}
 	
  Private String getBrandName(String bid){
 	CHV_Brand__c brand =[select name from CHV_Brand__c where id=:bid limit 1];
 	if(brand!=null) return brand.name;
 	else return '';
 }
 
 Private String getCustAccTypeName (String catid){
 	CHV_Customer_Access__c cat = [select name from CHV_Customer_Access__c where id=: catid limit 1];
 	if(cat!=null) return cat.name;
 	else return '';
 }

 
 
	
	
/*
List<CHV_Band_Cust_Access_History__c> lstBCA = new List<CHV_Band_Cust_Access_History__c>();
List<CHV_Band_Cust_Access_History__c> lstBCA1 = new List<CHV_Band_Cust_Access_History__c>();

set<Id> brandSet = new set<Id>();
set<Id> brandDSet = new set<Id> ();
String strAction;


if(Trigger.isInsert)
{
Set<Id> commonBrandSet = new Set<Id>();
for(CHV_Brand_Customer_Access__c ob: Trigger.new)
{   
brandSet.add(ob.Brand__c);
}
commonBrandSet = brandSet;
//strAction = 'Insert';
Map<Id, CHV_Brand__c> brandMap = new Map<Id,CHV_Brand__c>([select Id, Name from CHV_Brand__c where id in: brandSet]);
//Map<Id, CHV_Customer_Access__c> brandMap1 = new Map<Id,CHV_Customer_Access__c>([select Id, Name from CHV_Customer_Access__c where id in: brandSet]);

for(CHV_Brand_Customer_Access__c  br : Trigger.new)
{
CHV_Band_Cust_Access_History__c brFeed = new CHV_Band_Cust_Access_History__c();
                brFeed.Brand_Name__c = brandMap.get(br.Brand__c).Name;  
               brFeed.Customer_Access_Type__c=br.Brand_Customer_Access_Displayed_Name__c;
                           
  brFeed.Action__c ='Insert';
  brFeed.Action_Time__c = system.now();   
lstBCA.add(brFeed);
}

 Insert lstBCA;
            
}
      
    if(Trigger.isDelete)
{
for(CHV_Brand_Customer_Access__c ob: Trigger.old)
{   
brandDSet.add(ob.Brand__c);
}
//commonBrandSet = brandDSet;

Map<Id, CHV_Brand__c> brandMap = new Map<Id,CHV_Brand__c>([select Id, Name from CHV_Brand__c where id in: brandDSet]);
//Map<Id, CHV_Customer_Access__c> brandMap1 = new Map<Id,CHV_Customer_Access__c>([select Id, Name from CHV_Customer_Access__c where id in: brandDSet]);


            for(CHV_Brand_Customer_Access__c  br : Trigger.old)
{
CHV_Band_Cust_Access_History__c brFeed = new CHV_Band_Cust_Access_History__c();
                brFeed.Brand_Name__c = brandMap.get(br.Brand__c).Name;    
                brFeed.Customer_Access_Type__c=br.Brand_Customer_Access_Displayed_Name__c;
         
  brFeed.Action__c = 'Delete';
  brFeed.Action_Time__c = system.now();   
lstBCA.add(brFeed);
}

 Insert lstBCA;
}

*/   

    
}