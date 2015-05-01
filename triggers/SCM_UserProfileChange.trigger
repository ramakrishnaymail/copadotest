trigger SCM_UserProfileChange on User (before insert, before update) 
{
    List<Profile> userProfileList = [Select Id, Name FROM Profile Where Name like 'GNE-CM-%' AND Name!='GNE-CM-IHCP-PROFILE'];
    // Set SpringCM user flag based on Profile match
    for(Integer i=0;i<Trigger.new.size();i++)
    {
        boolean IsCMProfile = false;
        boolean ActiveChanged = false;
        boolean ProfileChanged = false;
        boolean OverrideChanged = false; 
        boolean DirtyFlagChanged = false;        
        boolean UserFlagChanged = false;   
        boolean EmailChanged = false;        

        if (Trigger.isUpdate)
        {
            ActiveChanged = Trigger.new[i].IsActive != Trigger.old[i].IsActive;
            ProfileChanged = Trigger.new[i].ProfileId != Trigger.old[i].ProfileId;  
            OverrideChanged = Trigger.new[i].OverrideSpringCMUserFlag__c != Trigger.old[i].OverrideSpringCMUserFlag__c;              
            DirtyFlagChanged = Trigger.new[i].Security_Dirty__c != Trigger.old[i].Security_Dirty__c;              
            UserFlagChanged = Trigger.new[i].SpringCM2SF__SpringCM_User__c != Trigger.old[i].SpringCM2SF__SpringCM_User__c;                          
            EmailChanged = Trigger.new[i].Email != Trigger.old[i].Email;                                           
        }   
        
        for(Profile prfl: userProfileList)
        {
            if(prfl.Id==Trigger.new[i].ProfileId)
            {
                IsCMProfile = true;
            }
        }
                
                
                //set user flags if there is a change to a field that dives the spring user flags
        if (ProfileChanged || ActiveChanged || Trigger.isInsert || OverrideChanged || (DirtyFlagChanged && !Trigger.new[i].SpringCM2SF__SpringCM_User__c) || UserFlagChanged || EmailChanged )
        {
            if (IsCMProfile && Trigger.new[i].IsActive)
            {
                Trigger.new[i].Security_Dirty__c = true;
                Trigger.new[i].SpringCM2SF__SpringCM_User__c = true;
            }
        }
                
        //no longer in the cm profile
        if (ProfileChanged && !IsCMProfile)
        {
            Trigger.new[i].Security_Dirty__c = false;
            Trigger.new[i].SpringCM2SF__SpringCM_User__c = false;
            Trigger.new[i].OverrideSpringCMUserFlag__c = false;
        }


        // check to see if just the dirty flag is set
        if (Trigger.new[i].Security_Dirty__c && !Trigger.new[i].SpringCM2SF__SpringCM_User__c)
        {
            Trigger.new[i].SpringCM2SF__SpringCM_User__c = true;
        }

        //override will clear all flags
        if (Trigger.new[i].OverrideSpringCMUserFlag__c)
        {
            Trigger.new[i].Security_Dirty__c = false;
            Trigger.new[i].SpringCM2SF__SpringCM_User__c = false;
        }
    
        //is not active
        if (Trigger.new[i].IsActive == false)
        {
            Trigger.new[i].Security_Dirty__c = false;
            Trigger.new[i].SpringCM2SF__SpringCM_User__c = false;
            Trigger.new[i].OverrideSpringCMUserFlag__c = false;
        }
    }
}