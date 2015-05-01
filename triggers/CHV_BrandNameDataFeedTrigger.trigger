trigger CHV_BrandNameDataFeedTrigger on CHV_Brand__c (after insert, after update, after delete)
 {
  List<CHV_Brand__c> brList;
    CHV_Brand__c br;
    CHV_Brand__c brOld;
    String action='';
    if(Trigger.isInsert) action = 'Create';
    else if(Trigger.isUpdate) action='Update';
    else if(Trigger.isDelete) action = 'Delete';
    
    if(action == 'Create' || action == 'Update') brList = Trigger.new;
    else brList = Trigger.old;

    if(brList!=null && brList.size()>0) br=brList[0];
    
    boolean feedChange=true;
   
    if(action=='Update') {
       
        List<CHV_Brand__c> brListOld=Trigger.old;
        
        if(brListOld!=null && brListOld.size()>0) {
            brOld=brListOld[0];
            
        }
        if(br!=null && brOld!=null && br.Name == brOld.name) {
            feedChange = false;
           
          }
    }
    if(br!=null && feedChange == true) {
        //make sure brand name is unique
        //if(action!='Delete')        br.Brand_No_Duplicates__c = br.name;
        CHV_Brand_History__c brFeed = new CHV_Brand_History__c();
        brFeed.SFDC_Brand_Record_ID__c = br.id;
        brFeed.Brand_Name__c = br.name;               
        brFeed.Action__c = action;
        brFeed.Action_Time__c = system.now();           
        if(action=='update'){
           if(br.Name <> brOld.Name)
                    brFeed.Before_Brand_Name__c = brOld.Name;
                    
           
         }
         brFeed.SentToAccessSolution__c = false;
         insert brFeed;
    }
  }