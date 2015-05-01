trigger prfGRpMp_onEditLimitLocale on Profile_to_Group_Map_gne__c (before insert, before update) {
    //return;
    List<String> grpNames =new List<String>();
    for(Profile_to_Group_Map_gne__c prfGrpMap: Trigger.new)
       grpNames.add(prfGrpMap.Group_Name_gne__c);
    
    // build list to verify groups exist
    List<Group> groups = [Select id, name from Group where type = 'Regular' and name in :grpNames];
    
    for(Profile_to_Group_Map_gne__c prfGrpMap: Trigger.new){
       String grpName='';
       List<Profile_to_Group_Map_gne__c> maps = [Select Id, Name, Profile_Mask_gne__c, Group_Name_gne__c, Locale_gne__c from Profile_to_Group_Map_gne__c where Profile_Mask_gne__c = :prfGrpMap.Profile_Mask_gne__c and Id <> :prfGrpMap.Id];
       //prfGrpMap.Group_Name_gne__c.addError(groups+'error');
        for(Profile_to_Group_Map_gne__c existPrfGrpMap: maps){
           // Ensure this Groups do not cross locales unless it is a SUPER profile
           if (prfGrpMap.Locale_gne__c <> existPrfGrpMap.Locale_gne__c &&
               prfGrpMap.Locale_gne__c <> null && existPrfGrpMap.Locale_gne__c <> null &&
               (!prfGrpMap.Profile_Mask_gne__c.toUpperCase().contains('SUPER') ||
                !existPrfGrpMap.Profile_Mask_gne__c.toUpperCase().contains('SUPER')))
                prfGrpMap.Locale_gne__c.addError(existPrfGrpMap.Name+' is mapped to Locale '+existPrfGrpMap.Locale_gne__c+' and '+
                  prfGrpMap.Name+' is mapped to Locale '+prfGrpMap.Locale_gne__c+' this is valid only for "SUPER_USER" profiles.'); 
           // Ensure this is not a duplicate Group to Profile Mask Mapping       
           else if (prfGrpMap.Group_Name_gne__c ==  existPrfGrpMap.Group_Name_gne__c &&
                    prfGrpMap.Profile_Mask_gne__c ==  existPrfGrpMap.Profile_Mask_gne__c)
                prfGrpMap.Locale_gne__c.addError('This is a duplicate Profile to Group Mapping and is not Allowed');
         }/*for maps*/
         for (Group grp: groups){
            grpName = grp.Name;
            if (grpName == prfGrpMap.Group_Name_gne__c)
               break;
         }/*for groups*/ 
         if(grpName <> prfGrpMap.Group_Name_gne__c)     
           prfGrpMap.Group_Name_gne__c.addError(groups+'A Regular Group by the name "'+ prfGrpMap.Group_Name_gne__c+'" does not exist. Please verify the correct name and/or create the group before saving the "Profile to Group Mapping".'); 
    }/*for Trigger.new*/        
}/*prfGRpMp_onEditLimitLocale*/