trigger CIM_WF_AfterInsertNewUserApproval on CIM_UserApproval__c (after insert) {
    CIM_UserApproval__c newRequest = trigger.new[0];
    if (newRequest.Process_Status__c == 'New' && newRequest.AutoSubmitRequest__c==true){
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();     
        req.setComments('Submitted for approval. Please approve.');
        req.setObjectId(Trigger.new[0].Id);
        // submit the approval request for processing
        Approval.ProcessResult result = Approval.process(req);
        // display if the reqeust was successful
        System.debug('Submitted for approval successfully: '+result.isSuccess());
    }
}