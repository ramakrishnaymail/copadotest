trigger GNE_CM_EBI_Rule_Issue_Trigger on GNE_CM_EBI_Rule_Issue__c (after update, after insert, before update) {
   	// SFA2 bypass. Please not remove!
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_EBI_Rule_Issue_Trigger')) {
        return;
    }	
    
    if(trigger.isInsert && trigger.isAfter){
        afterInsert();
    } else if (trigger.isUpdate && trigger.isBefore){
        beforeUpdate();
    }
   
    
    public void afterInsert(){
        for(Integer i = 0; i < trigger.new.size(); i++){               
                GNE_CM_EBI_Rule_Issue__c ruleIssueNew = trigger.new[i];
            Approval.ProcessSubmitRequest req1 = 
                    new Approval.ProcessSubmitRequest();
            req1.setComments('technical step - auto-start approval process ');
            req1.setObjectId(ruleIssueNew.id);
            Approval.ProcessResult result = Approval.process(req1);
        }   
    }

    public void beforeUpdate(){
            
        for (GNE_CM_EBI_Rule_Issue__c ebiNew : trigger.new)
        {
			GNE_CM_EBI_Rule_Issue__c ebiOld=trigger.oldMap.get(ebiNew.Id);
	        if(ebiOld.Status_gne__c=='New' && !(ebiNew.Status_gne__c=='New' || ebiNew.Status_gne__c=='Under GNE Review'))
	        {
	            ebiNew.addError('Invalid Sequence: Must go to Status=\'Under GNE Review\' first.');
	        }
			
	        if(ebiOld.Status_gne__c=='Assigned to Vendor' && !(ebiNew.Status_gne__c=='Assigned to Vendor' || ebiNew.Status_gne__c=='Received By Vendor'))
	        {
	            ebiNew.addError('Invalid Sequence: Must go to Status=\'Received By Vendor\' first.');
	        }
	        
	        // Added this here because SFDC doesn't fire validation rules on Approval Process Actions 
	        if((ebiNew.Status_gne__c=='Closed - Approved' || ebiNew.Status_gne__c=='Closed - Cancelled By Vendor')  && ebiNew.TE_Resolution_Type_gne__c==null)
	        {
	            ebiNew.addError('Resolution Type must be specified to close issue.');
	        }
	        
        }
    }
 
}