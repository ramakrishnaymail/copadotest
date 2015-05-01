trigger GNE_User_DelegationTrigger on GNE_User_Delegation__c (before insert, before update, after insert, after update) {
	
	if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		Set<ID> userIds= new Set<ID>();
		for(GNE_User_Delegation__c delegation: Trigger.new){
			if(delegation.Username__c != null){
				userIds.add(delegation.Username__c);
			}
		}
		Map<ID,User> delegationOwner=new Map<ID,User>([select id,email,username from user where id in: userIds]);
		for(GNE_User_Delegation__c delegation: Trigger.new){
			if(delegationOwner.containsKey(delegation.Username__c)){
				delegation.Name=delegationOwner.get(delegation.Username__c).username;
			}	
		}
	} else if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
		if (Trigger.isInsert) {
			GNE_User_Delegation_Child_Record_Update.onAfterInsert(Trigger.new);
		} 
		if (Trigger.isUpdate) {
			GNE_User_Delegation_Child_Record_Update.onAfterUpdate(Trigger.old, Trigger.new);
		}
	}
}