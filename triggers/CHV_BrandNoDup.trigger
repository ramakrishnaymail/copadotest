trigger CHV_BrandNoDup on CHV_Brand__c (before insert, before update) {
    List<CHV_Brand__c> brList = Trigger.new;
    if(brList!=null && brList.size()>0){
      CHV_Brand__c br=brList[0];
      br.Brand_No_Duplicates__c = br.name;
    }
}