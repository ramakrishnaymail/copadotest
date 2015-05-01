trigger GNE_RM_UserBusinessRole on User_Business_Role_gne__c (after insert, after update, after delete) {

    List<Id> userIdList = new List<Id>();
    List<User_Business_Role_gne__c> ubrList = Trigger.IsDelete ? Trigger.old : Trigger.new; 
        
    for (User_Business_Role_gne__c ubr : ubrList ) 
        userIdList.add (ubr.user_gne__c);
    
    GNE_RM_UpdateUserRole.updateUserRole ( userIdList );                    

}