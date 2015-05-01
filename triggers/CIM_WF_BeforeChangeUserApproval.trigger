trigger CIM_WF_BeforeChangeUserApproval on CIM_UserApproval__c (before insert, before update) {
    CIM_UserApproval__c request;
    List<CIM_UserApproval__c> requests = Trigger.new;
    
    //disable update and delete if request record is supported to be locked
    if(requests!=null && requests.size()>=0){
        request = requests[0];

            List<CIM_eWorkflow_Delegation__c> appHirs=[select Name, Approver__c, ApproverOnVacation__c, proxyApprover__c, vacationEndDate__c, vacationStartDate__c from CIM_eWorkflow_Delegation__c where   Workflow_Type__c='User Approval' ];
            if(appHirs!=null && appHirs.size()>0){
                for(CIM_eWorkflow_Delegation__c app: appHirs){
                    String approver;
                    if(app.ApproverOnVacation__c==true && System.today()>=app.vacationStartDate__c && System.today()<app.vacationEndDate__c){
                        approver=app.proxyApprover__c;
                    }else approver=app.Approver__c;
                   
                     request.approver__c = approver;
                    
                }
            }
            if(request.Requester__c==null) request.Requester__c=UserInfo.getUserId();

			if(request.End_Date__c==null) request.send_end_date_reminder__c = true;
			else request.send_end_date_reminder__c = false;
    }
}