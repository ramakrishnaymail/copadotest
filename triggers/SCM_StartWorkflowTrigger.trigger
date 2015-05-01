trigger SCM_StartWorkflowTrigger on SCM_DeletedPER__c (before insert) {
SCM_DeletedPER__c[] Pers = Trigger.new;
for(SCM_DeletedPER__c per: Pers){
SCM_StartWorkflow.StartWorkflowPERDelete(per.DeletedPERID__c,per.DeletedPERNumber__c);
}

}