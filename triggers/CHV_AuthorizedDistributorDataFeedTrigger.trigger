trigger CHV_AuthorizedDistributorDataFeedTrigger on CHV_Authorized_Distributor__c (after insert, after update, after delete) {
  List<CHV_Authorized_Distributor__c> adList;
    CHV_Authorized_Distributor__c ad;
    CHV_Authorized_Distributor__c adOld;
    String action='';
    if(Trigger.isInsert) action = 'Create';
    else if(Trigger.isUpdate) action='Update';
    else if(Trigger.isDelete) action = 'Delete';
    
    if(action == 'Create' || action == 'Update') adList = Trigger.new;
    else adList = Trigger.old;

    if(adList!=null && adList.size()>0) ad=adList[0];
    
    boolean feedChange=true;
    //String here = 'here 0';
    if(action=='Update') {
       // here +=', 1';
        List<CHV_Authorized_Distributor__c> adListOld=Trigger.old;
        
        if(adListOld!=null && adListOld.size()>0) {
            adOld=adListOld[0];
            //here += ', 2';
        }
        if(ad!=null && adOld!=null && ad.Corporate_Fax__c == adOld.Corporate_Fax__c && 
            ad.Corporate_Phone__c == adOld.Corporate_Phone__c && 
            ad.Corporate_URL__c == adOld.Corporate_URL__c) {
            feedChange = false;
            //here += ', 3';
          }
    }
    if(ad!=null && feedChange == true) {
        CHV_AD_History__c adFeed = new CHV_AD_History__c();
        adFeed.SFDC_AD_Record_ID__c = ad.id;
        adFeed.Authorized_Distributor_Name__c = ad.name;               
        adFeed.Corporate_Fax__c = ad.Corporate_Fax__c;
        adFeed.Corporate_Phone__c = ad.Corporate_Phone__c;
        adFeed.Corporate_URL__c = ad.Corporate_URL__c;
        adFeed.Action__c = action;
        adFeed.Action_Time__c = system.now();           
        if(action=='update'){
           if(ad.Corporate_Fax__c <> adOld.Corporate_Fax__c)
                    adFeed.Before_FaxNum__c = adOld.Corporate_Fax__c;
                    
           if(ad.Corporate_Phone__c <> adOld.Corporate_Phone__c)
                    adFeed.Before_PhoneNum__c = adOld.Corporate_Phone__c;
                    
           if(ad.Corporate_URL__c <> adOld.Corporate_URL__c)
                    adFeed.Before_URL__c = adOld.Corporate_URL__c;
         }
         adFeed.SentToAccessSolution__c = false;
         insert adFeed;
    }
  
}