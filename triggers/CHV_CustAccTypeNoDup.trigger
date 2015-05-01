trigger CHV_CustAccTypeNoDup on CHV_Customer_Access__c (before insert, before update) {
    List<CHV_Customer_Access__c> brList=Trigger.new;
    if(brList!=null && brList.size()>0) {
        CHV_Customer_Access__c br= brList[0];
        br.Customer_Access_Type_No_Duplicates__c=br.name;
    }
}