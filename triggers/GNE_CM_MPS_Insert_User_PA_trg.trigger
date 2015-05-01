trigger GNE_CM_MPS_Insert_User_PA_trg on GNE_CM_MPS_User__c (after insert) {

      List<GNE_CM_MPS_Practice_Agreement__c> tobeInsertedPA =new List<GNE_CM_MPS_Practice_Agreement__c>();
      for(GNE_CM_MPS_User__c user :trigger.new)
      {
         if(user.Mapped_Account__c == null) {
             continue;
         }
         
      
          GNE_CM_MPS_Practice_Agreement__c agreement= new GNE_CM_MPS_Practice_Agreement__c();
          agreement.Account__c = user.Mapped_Account__c;
          agreement.Is_User__c= true;
          agreement.MPS_Registration__c = user.GNE_CM_MPS_Registration__c;
          agreement.MPS_User__c=user.Id;
          tobeInsertedPA.add(agreement);
      }
      
      if(tobeInsertedPA !=null && tobeInsertedPA.size() > 0)
      {
          insert tobeInsertedPA;
      }

}