trigger GNE_CM_MPS_User_Unique_Rec_Validation on GNE_CM_MPS_User__c (after update) {

     Set<String> regSet = new Set<String>();
    
     Map<String,GNE_CM_MPS_User__c> gneMPSUserMap =new Map<String,GNE_CM_MPS_User__c>();
     List<String> usrNameList =new List<String>();
     List<String> usrIdList =new List<String>();
     List<String> usrEmailList =new List<String>();

     for(GNE_CM_MPS_User__c mpsUser : trigger.new)
     {
         system.debug('Registration number is '+mpsUser.GNE_CM_MPS_Registration__r.Name);
          system.debug('Updated User is ' + mpsUser.Name);
         regSet.add(mpsUser.GNE_CM_MPS_Registration__c);
         usrNameList.add(mpsUser.Name);
         usrIdList.add(mpsUser.Id);
         usrEmailList.add(mpsUser.Email_address__c);
     }
     
     List<GNE_CM_MPS_User__c> gneMPSUserList =[select id, Name, First_name__c, Last_name__c, Email_address__c, GNE_CM_MPS_Registration__r.Name, Do_not_display_in_View__c , Disabled__c from GNE_CM_MPS_User__c 
                                                where GNE_CM_MPS_Registration__c in :regSet and Do_not_display_in_View__c = false and Disabled__c = true]; 

     List<GNE_CM_MPS_User__c> toBeUpdated = new List<GNE_CM_MPS_User__c>();  
     
     //TODO Runtime Exception gneMPSUserList not null and size() > 0
     for(GNE_CM_MPS_User__c gneMPSUser : gneMPSUserList)
     {
     	boolean alreadyExists = false;
     	//TODO Runtime Exception usrNameList not null and size() > 0
     	for(String userName : usrNameList) {
     		System.debug('userName : ' + userName);
     		System.debug('gneMPSUser.Name : ' + gneMPSUser.Name);
     		if(gneMPSUser.Name.equals(userName)) {
     			alreadyExists = true;
     			break;
     		}
     	}
     	
     	if(alreadyExists) {
     		continue;
     	}
     	
        if(GNE_CM_MPS_Utils.contains(usrEmailList, gneMPSUser.Email_address__c)) {
            gneMPSUser.Do_not_display_in_View__c = true;
            system.debug('Duplicate email : ' + gneMPSUser.Name + ' ' + gneMPSUser.Email_address__c + ' ' + gneMPSUser.First_name__c + ' ' + gneMPSUser.Last_name__c);
            toBeUpdated.add(gneMPSUser);
        }
     }     
     
     if(toBeUpdated.size() > 0) {
        update toBeUpdated;
     }
}