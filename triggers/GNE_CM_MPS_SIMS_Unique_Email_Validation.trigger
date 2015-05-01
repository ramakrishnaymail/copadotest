trigger GNE_CM_MPS_SIMS_Unique_Email_Validation on GNE_CM_MPS_SIMS_User_Management__c (before insert) {

    Set<String> emailSet =new Set<String>();
    Map<String, GNE_CM_MPS_SIMS_User_Management__c> emailSIMSObjectMap = new Map<String, GNE_CM_MPS_SIMS_User_Management__c>();
    
    for(GNE_CM_MPS_SIMS_User_Management__c simsuser :trigger.new)
    {
        emailSet.add(simsuser.Email_address__c);
        emailSIMSObjectMap.put(simsuser.Email_address__c, simsuser);   
    }
    
    List<GNE_CM_MPS_SIMS_User_Management__c> simsuserList =  new List<GNE_CM_MPS_SIMS_User_Management__c>();
    Map<String,GNE_CM_MPS_SIMS_User_Management__c> emailUserMap =new Map<String,GNE_CM_MPS_SIMS_User_Management__c>();
    
    simsuserList = [select id,name, Email_address__c from GNE_CM_MPS_SIMS_User_Management__c where email_address__c in :emailSet];
    
    //TODO Runtime Exception simsuserList is not null and size() > 0
    for(GNE_CM_MPS_SIMS_User_Management__c simsuser :simsuserList )
    {
        emailUserMap.put(simsuser.Email_address__c, simsuser);
    }
    
    //TODO Runtime Exception emailset is not null and size() > 0
    for(String emailStr : emailset )
    {
        if(emailUserMap.get(emailStr) != null )
        {
            system.debug('Email id should be Unique: ' + emailStr);
            GNE_CM_MPS_SIMS_User_Management__c simsUserObj = emailSIMSObjectMap.get(emailStr);
            simsUserObj.addError('Email id should be Unique: ' + emailStr);
        } 
    }
}