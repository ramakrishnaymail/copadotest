trigger CIM_WF_AfterUpdateDelegation on CIM_eWorkflow_Delegation__c (after update) {
	List<CIM_eWorkflow_Delegation__c> delegations = Trigger.new;
	if(delegations != null && delegations.size()>0){
		for(CIM_eWorkflow_Delegation__c delegation: delegations){
			 String approver;
             if(delegation.ApproverOnVacation__c==true && System.today()>=delegation.vacationStartDate__c && System.today()<delegation.vacationEndDate__c){
                  approver=delegation.proxyApprover__c;
             }else approver=delegation.Approver__c;
             			
			if(delegation.Workflow_Type__c == 'Parameter Approval'){
				List<CIM_ParameterApproval__c> paraApprs = [select id, status__c, approver__c from CIM_ParameterApproval__c where Status__c='New' or Status__c='Recalled'];
				if(paraApprs != null && paraApprs.size()>0) {
					for(CIM_ParameterApproval__c paraAppr: paraApprs) {
						paraAppr.Approver__c = approver;
					}
					
					update paraApprs;
				}
			}else if(delegation.Workflow_Type__c == 'User Approval'){
				List<CIM_UserApproval__c> userApprs = [select id, Process_Status__c, Approver__c, End_Date__c from CIM_UserApproval__c where Process_Status__c='New' or Process_Status__c='Recalled'];
				if(userApprs!=null && userApprs.size()>0){
					for(CIM_UserApproval__c userAppr: userApprs) {	 
						userAppr.Approver__c = approver;
						if(userAppr.End_Date__c < userAppr.Start_Date__c || userAppr.End_Date__c < System.today() ){
							userAppr.End_Date__c = null;
						}
					}
					
					update userApprs;
				}
			}
		}
	}
	
}