trigger CIM_WF_BeforeInsertDeleteDelegation on CIM_eWorkflow_Delegation__c (before delete, before insert) {
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    
    CIM_eWorkflow_Delegation__c delegation;
    String action ='';
    if(Trigger.isDelete) {
        delegation = Trigger.old[0];
        action ='delete';
    }   else {
        delegation = Trigger.new[0];
        action ='insert';
    }
    
    if(prof.name != 'System Administrator' && prof.name!='GNE-SYS-Support' && prof.name!='GNE-SFA-InternalUser') {
        delegation.addError('You do not have permission to '+action+' delegation');
    }
}