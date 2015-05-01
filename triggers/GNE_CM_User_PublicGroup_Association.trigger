trigger GNE_CM_User_PublicGroup_Association on User (after insert, after update, before update) {
   // SFA2 bypass
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_User_PublicGroup_Association')) {
        return;
    }
    /**This trigger puts the users with GENE_CM_ profiles in the specific public groups. 
Refer interface 39 document for the group to profile mapping.
Last Modified on :05/21/2010 by swati dhingra as per offshore request 445,to add the 
logic to add the users to group GNE_CM_inactive_users when they are inactive or there 
profile is changed from 'GNE-CM' to non 'GNE-CM'.
**/
    /** Last Modified 07/09/2010 saxenam : Added the logic so when users are becoming inactive 
and do not exist in User Hierarchy table still get unassigned from the CM groups and get 
assigned to the inactive user group.**/
    /**Last Modified 07/12/2010 shwetab: Excluded GNE-CM-Physician profile**/
    /**Last Modified 07/13/2010 shwetab: Update users to Inactive user role when profile is changed frm GNE-CM to non GNE-CM**/
    /**Last Modified 11/03/2010   adamb: Removed the check of user's existence in the User_Hierarchy_gne__c table **/
    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_User_PublicGroup_Association'))
    {
        System.debug('Skipping trigger GNE_CM_User_PublicGroup_Association');
        return;
    }
    
    Map<Id, Profile> userProfileList =  new Map<Id, Profile>([Select Id, Name FROM Profile WHERE Name LIKE 'GNE-CM-%' AND (NOT Name LIKE 'GNE-CM-Physician Profile%') AND (Name != 'GNE-CM-REIMBSPECIALIST-VENDOR-TE') AND (Name != 'GNE-CM-IHCP-PROFILE') ]);                          
    List<Environment_Variables__c> envVarList_new = new List<Environment_Variables__c>([select Key__c,Value__c,Description_Name__c from Environment_Variables__c 
    WHERE Description_Name__c = 'GNE_CM_User_PublicGroup_Association' or  Key__c = 'GNE-CM-INACTIVE-USER-ROLE-NAME' ]);
    
    List<Environment_Variables__c> InactiveUser_list = new List<Environment_Variables__c>();
    List<Environment_Variables__c> envVarList = new List<Environment_Variables__c>();
    List<GroupMember> GrpMemInsertList = new List<GroupMember>();
    List<GroupMember> GrpMemDeleteList = new List<GroupMember>();
    String InactiveUserRole;       
    String InactiveUserRoleId; 
    Map<String, Group> grpMap = new Map<String, Group>();   
    String newUserID;
    String oldUserID;
    String newProfileName; 
    String oldProfileName;
    String newUserRoleId; 
    String oldUserRoleId;
    // String oldGroupId ;
    set<string> oldGroupId = new set<string>();
    boolean inActiveUser;
    String newUserExternalId;
    boolean alreadyExists = false;
    boolean inActiveUserFlag = false;
    Id inActiveUserGroupId;
    boolean setnoncmflag=false;
    boolean processThisUser = false;
    
    for(integer i = 0; i <envVarList_new.size(); i++)      
    {       
        if(envVarList_new[i].Key__c == 'GNE-CM-INACTIVE-USER-ROLE-NAME')        
        {            
            InactiveUser_list.add(envVarList_new[i]);        
        }       
        else        
        envVarList.add(envVarList_new[i]);     
    }     
    
    if( InactiveUser_list.size()>0)    
    {       
        InactiveUserRole = InactiveUser_list[0].Value__c;     
    }    
    if(InactiveUserRole != null && InactiveUserRole != '')    
    {    
        UserRole usrole = [Select Id, name  from UserRole where name = :InactiveUserRole limit 1 ];     
        InactiveUserRoleId = usrole.Id;       
    }
    //Create the group names for the where clause for the Group table otherwise could hit the governor limit of rows returned.
    List<String> groupNames = new List<String>();
    for (Environment_Variables__c envVar: envVarList)
    {
        groupNames.add(envVar.Key__c);
    } 
    
    //Create the groupids for the where clause for the GroupMember table otherwise could hit the governor limit of rows returned.     
    List<String> groupIDs = new List<String>();
    for (Group[] grp : [select id, name from Group where name in :groupNames])
    {             
        for (integer i = 0; i < grp.size();i++)
        {
            if (grp[i] != null && grp[i].name != null)
            {
                grpMap.put(grp[i].name, grp[i]);
                groupIDs.add(grp[i].id); 
                if(grp[i].name == 'GNE-CM-Inactive-Users')
                inActiveUserGroupId = grp[i].id;
            }
            
        }   
    }
    system.debug('**grpMap**'+grpMap);
    List<GroupMember> grpMemberList = new List<GroupMember>([select Id, GroupId, UserOrGroupId from GroupMember where GroupId in :groupIDs and UserOrGroupId in :Trigger.new]);      
    
    if(trigger.isafter)
    {
        for (Integer k =0; k < Trigger.new.size(); k++)
        {
            GroupMember GrpMemberInsert = new GroupMember();       
            GroupMember GrpMemberDelete = new GroupMember();
            boolean isCmUser = userProfileList.containskey(Trigger.new[k].ProfileId);
            boolean isUserActive = Trigger.new[k].isActive;
            boolean wasCmUser = false;
            boolean wasUserActive = false;
            boolean wasProfileChanged = false;
            
            if(Trigger.isUpdate)
            {
                if(userProfileList.containskey(Trigger.old[k].ProfileId))
                wasCmUser = true;
                if(Trigger.old[k].ProfileId != Trigger.new[k].ProfileId)
                wasProfileChanged = true;
                if(Trigger.old[k].isActive == true)
                wasUserActive = true;
            }
            if((isCmUser != wasCmUser) || 
                    ((isUserActive != wasUserActive) && (isCmUser || wasCmUser)) ||
                    (wasProfileChanged && wasCmUser  && isCmUser))
            {
                newUserID = null;
                oldUserID = null;
                newProfileName = null; 
                oldProfileName = null;
                oldGroupId.clear();
                newUserExternalId = null;
                alreadyExists = false;
                inActiveUser= false;
                
                if( Trigger.new[k].IsActive == true)
                {
                    if(Trigger.new[k].ProfileId!=null)
                    {
                        //Filter out the users with GNE_CM profile
                        
                        if(userProfileList.containskey(Trigger.new[k].ProfileId))
                        {     
                            //Get the new user information.
                            newUserId = Trigger.new[k].Id;
                            inActiveUserFlag = true;
                            newProfileName =  userProfileList.get(Trigger.new[k].ProfileId).Name;  
                            newUserExternalId = Trigger.new[k].EXTERNAL_ID_GNE__C;           
                        }
                        else
                        {
                            newProfileName = 'NewInactiveProfile'; //set new profile name to dummy value for any users with profile other than GNE-CM
                            newUserId = Trigger.new[k].Id;
                        }
                    }
                }    
                if(Trigger.isUpdate)
                {  
                    if(Trigger.old[k].ProfileId!=null)
                    {
                        
                        if(userprofileList.containskey(Trigger.old[k].ProfileId))
                        {                               
                            //get the old user infromation 
                            setnoncmflag = true;
                            oldUserId = Trigger.old[k].Id;
                            oldProfileName = userprofileList.get(Trigger.old[k].ProfileId).Name;                               
                        }
                        
                        if(!setnoncmflag && Trigger.old[k].ProfileId != Trigger.new[k].ProfileId)
                        {
                            oldUserId = Trigger.old[k].Id;
                            oldProfileName =  'OldInactiveProfile'; //set old profile name to dummy value for any users with profile other than GNE-CM
                        }
                    } 
                    if(Trigger.old[k].IsActive != Trigger.new[k].IsActive && Trigger.new[k].IsActive == false)
                    {
                        inActiveUser= true; //set the flag when current user is inactive 
                    }       
                } // end of if(Trigger.isUpdate)
                //create member record for inactive user and assign the user to GNE-CM-Inactive-Users group
                //also delete existing member record from Group member table
                if(inActiveUser)
                {
                    for(GroupMember grpMem: grpMemberList)
                    {
                        if(grpMem.UserOrGroupId == Trigger.new[k].Id)
                        {
                            //Check against the environment variable to only process the configured groups.
                            for (Environment_Variables__c envVar: envVarList)
                            {
                                if (grpMem.GroupId == grpMap.get(envVar.Key__c).Id)
                                {
                                    GrpMemberDelete = grpMem;
                                }                                                                                                         
                            }
                        }
                        
                        if (GrpMemberDelete.GroupId != null)
                        {
                            GrpMemDeleteList.add(GrpMemberDelete);                          
                        }
                    }
                    GrpMemberInsert.UserOrGroupId = Trigger.new[k].Id;
                    GrpMemberInsert.GroupId = inActiveUserGroupId;
                    GrpMemInsertList.add(GrpMemberInsert);
                } //End of if(inActiveUser)
                //Only go further if the new user or the profile of the user has changed.
                if(Trigger.new[k].IsActive == true)
                {
                    if (newProfileName  != oldProfileName || (Trigger.old[k].IsActive == false && Trigger.new[k].IsActive == True))
                    {        
                        if (oldProfileName != null && oldUserId != null  )
                        {
                            for(GroupMember grpMem: grpMemberList)
                            {
                                if(grpMem.UserOrGroupId == oldUserId)
                                {
                                    //Check against the environment variable to only process the configured groups.
                                    for (Environment_Variables__c envVar: envVarList)
                                    {
                                        if (grpMem.GroupId == grpMap.get(envVar.Key__c).Id)
                                        {
                                            GrpMemberDelete = grpMem;
                                        }
                                    }                                                                                                                                                     
                                }
                                if (GrpMemberDelete.GroupId != null)
                                {
                                    oldGroupId.add(GrpMemberDelete.GroupId);  
                                    GrpMemDeleteList.add(GrpMemberDelete);                          
                                }
                            }
                        }
                        
                        if (newProfileName != null && newUserId != null)
                        {             
                            GrpMemberInsert.UserOrGroupId = newUserId; 
                            
                            if (newProfileName.startswith('GNE-CM'))
                            {
                                //If user is not the vendor then match the groups from the environment variable.
                                for (Environment_Variables__c envVar: envVarList)
                                {
                                    if (newProfileName.equals(envVar.Value__c))
                                    {
                                        GrpMemberInsert.GroupId = grpMap.get(envVar.Key__c).Id;
                                        break;
                                    }  
                                    if (envVar.Value__c == '<AllOtherCMProfile>')
                                    {
                                        GrpMemberInsert.GroupId = grpMap.get(envVar.Key__c).Id;                 
                                    }
                                }           
                            } 
                            else //any non CM users will be assigned to GNE-CM-Inactive-Users group
                            {
                                GrpMemberInsert.GroupId = inActiveUserGroupId;
                                //GrpMemInsertList.add(GrpMemberInsert);
                                
                            }                  
                            for(GroupMember grpMem: grpMemberList)
                            {
                                //If the user is already asigned to the desired group then skip it.
                                if(grpMem.GroupId==GrpMemberInsert.GroupId 
                                        && grpMem.UserOrGroupId == newUserId
                                        && !oldGroupId.contains(GrpMemberInsert.GroupId) 
                                        )
                                {     
                                    alreadyExists = true;                 
                                    break;              
                                }
                            }        
                            if (!alreadyExists && GrpMemberInsert.GroupId != null)
                            {
                                GrpMemInsertList.add(GrpMemberInsert); 
                            }        
                        }
                    }
                }
            }
        }
        
        Database.deleteresult[] GM_DELETE;
        Database.saveresult[] GM_INSERT;   
        Savepoint sp = Database.setSavepoint();
        system.debug('**MEMLIST********************'+GrpMemDeleteList); 
        
        GM_DELETE = Database.delete(GrpMemDeleteList , false); 
        String result;
        for(Database.deleteresult srLIST : GM_DELETE)
        { 
            if(!srLIST.isSuccess())
            {
                for(Database.Error err : srLIST.getErrors())
                {
                    result = 'Fail to un-assign users from Public Groups '+ err.getMessage();
                    Error_Log_gne__c error=new Error_Log_gne__c(Object_Name__c='GroupMember', Error_Level_gne__c='High',Snippet_Name__c='GNE_CM_User_PublicGroup_Association', Code_Type__c='Apex Trigger', Error_Description__c=result, User_Name__c=UserInfo.getUserName());             
                }
                Database.rollback(sp);         
                return;
            }
        }       
        GM_INSERT = Database.insert(GrpMemInsertList , false);
        for(Database.saveresult srLIST : GM_INSERT)
        {
            if(!srLIST.isSuccess())
            {
                for(Database.Error err : srLIST.getErrors())
                {
                    result = 'Fail to assign users to Public Groups '+ err.getMessage();
                    Error_Log_gne__c error=new Error_Log_gne__c(Object_Name__c='GroupMember', Error_Level_gne__c='High',Snippet_Name__c='GNE_CM_User_PublicGroup_Association', Code_Type__c='Apex Trigger', Error_Description__c=result, User_Name__c=UserInfo.getUserName());             
                }
                Database.rollback(sp);         
                return;
            }
        }
    }
    //assign non GNE-CM users to inactive user role
    if(trigger.isbefore)
    {
        for(User usr: Trigger.new)
        {
            
            //check whether the user shlould be processed or not
            //get the user's old profile and new profile info                           

            if(system.trigger.oldmap.get(usr.Id).ProfileId != null && userprofileList.containskey(system.trigger.oldmap.get(usr.Id).ProfileId))
            {                               
                oldProfileName = userprofileList.get(system.trigger.oldmap.get(usr.Id).ProfileId).Name;
                oldUserRoleId = system.trigger.oldmap.get(usr.Id).UserRoleId;     
            }
system.debug('@@@@@@@@@@@@@@@@@@@'+newUserRoleId );
            if(usr.ProfileId !=null && userprofileList.containskey(usr.ProfileId))
            {                               
                newProfileName = userprofileList.get(usr.ProfileId).Name;
                newUserRoleId = usr.UserRoleId;   
            }
 system.debug('$$$$$$$$$$$$$$$$$$$$$$$$'+newUserRoleId ) ;          
            if(oldProfileName == null)
            {
                oldProfileName = 'OLDPROFILENAME'; //for non GNE-CM profiles
                oldUserRoleId = system.trigger.oldmap.get(usr.Id).UserRoleId;
            }
            if(newProfileName == null)
            {
                newProfileName = 'NEWPROFILENAME';//for non GNE-CM profiles
                newUserRoleId = usr.UserRoleId;
            }          
       system.debug('####################'+newUserRoleId ) ;      
            system.debug('**CHECK**'+oldProfileName+' '+newProfileName);    
            if(oldProfileName != null && newProfileName != null && oldProfileName != newProfileName)  
            {
                if (InactiveUserRoleId != null 
                        && (!newProfileName.startswith('GNE-CM') && oldProfileName.startswith('GNE-CM'))
                        && (oldUserRoleId  == newUserRoleId))     
                {                 
                    usr.UserRoleId = InactiveUserRoleId;
                }                
            }                                 
        }
    }//end of isbefore trigger     
}