trigger EM3_Bureau_Membership_before_Insert on Speaker_Bureau_Membership_gne__c (before insert) {
    for(Speaker_Bureau_Membership_gne__c member : trigger.new){
        if(member.Nominated_By_gne__c == null){
            member.Nominated_by_gne__c = userInfo.getUserId(); 
        }
    }
}