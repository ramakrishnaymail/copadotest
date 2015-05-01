trigger GNE_CM_MPS_ActivityTrigger on GNE_CM_MPS_ARX_ePAN_Management__c (after update) {

    if(trigger.isUpdate){
        List<Task> taskList=new List<Task>();
        
        //If ePAN is originating from Case or MPS Case Detail page (SMN PAN Options)
        if(trigger.new[0].Case__c != null) {
	        List<Case> caseList = [select id, RecordType.Name, Case_Manager__c,Foundation_Specialist_gne__c from Case where id =: trigger.new[0].Case__c];
	        
	        if(caseList.size() <= 0) {
	        	return;
	        }
	        
	        for(GNE_CM_MPS_ARX_ePAN_Management__c ePanObj : trigger.new){
	            if(ePanObj.PAN_Status__c=='INVITED' && ePanObj.PAN_Origin_MPS__c=='CMGT Case Invitation') {
	                Task tsk=new Task();
	                tsk.Subject='Successful ePAN Sent';
	                //tsk.Closed_Date_gne__c=System.now();
	                tsk.ActivityDate=System.today();
	                tsk.Activity_Type_gne__c='Successful ePAN Sent';
	                tsk.Process_Category_gne__c='Fax/Document Management';
	                tsk.whatId=ePanObj.Case__c;
	                tsk.Status='Completed';
	                tsk.Priority='Normal';
	                if(caseList!=null && caseList.size()>0){
		                if(caseList[0].RecordType.Name.contains('C&R')){
		                    tsk.OwnerID=caseList[0].Case_Manager__c;
		                }
		                else if(caseList[0].RecordType.Name.contains('GATCF')){
		                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
		                }
	                } 
	                taskList.add(tsk);
	                
	                tsk=new Task();
	                tsk.Subject='Follow up on Paperless PAN Form';
	                tsk.ActivityDate=System.today().addDays(1);
	                tsk.Activity_Type_gne__c='Follow up on Paperless PAN Form';
	                tsk.Process_Category_gne__c='Managing a Case';
	                tsk.OwnerID=UserInfo.getUserId();
	                tsk.whatId=ePanObj.Case__c;
	                tsk.Status='Not Started';
	                tsk.Priority='High';
	               	if(caseList!=null && caseList.size()>0){
		                if(caseList[0].RecordType.Name.contains('C&R')){
		                    tsk.OwnerID=caseList[0].Case_Manager__c;
		                }
		                else if(caseList[0].RecordType.Name.contains('GATCF')){
		                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
		                }
	                } 
	                taskList.add(tsk);
	                system.debug('taskList----->'+taskList);
	            }
	            else if(ePanObj.PAN_Status__c=='SUBMITTED' && 
	            	(ePanObj.PAN_Origin_MPS__c=='CMGT Case Invitation'
	                  || ePanObj.PAN_Origin_MPS__c== 'MPS Case Invitation' 
	                  || ePanObj.PAN_Origin_MPS__c== 'MPS Case Submit Now')) {
	                Task tsk=new Task();
	                tsk.Subject='ePAN Saved to Case';
	                tsk.ActivityDate=System.today();
	                tsk.Activity_Type_gne__c='Fax Saved to Case';
	                tsk.Process_Category_gne__c='Fax/Document Management';
	                tsk.whatId=ePanObj.Case__c;
	                tsk.Status='Completed';
	                tsk.Priority='Normal';
	                tsk.Description='Document Type: Paperless PAN';
	               	if(caseList!=null && caseList.size()>0){
		                if(caseList[0].RecordType.Name.contains('C&R')){
		                    tsk.OwnerID=caseList[0].Case_Manager__c;
		                }
		                else if(caseList[0].RecordType.Name.contains('GATCF')){
		                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
		                }
	                } 
	                taskList.add(tsk);
	                
	                tsk=new Task();
	                tsk.Subject='Review Incoming Documents';
	                tsk.ActivityDate=System.today();
	                tsk.Activity_Type_gne__c='Reviewing Incoming Documents';
	                tsk.Process_Category_gne__c='Fax/Document Management';
	                tsk.whatId=ePanObj.Case__c;
	                tsk.Status='New';
	                tsk.Priority='High';
	                tsk.Description='Document Type: Paperless PAN';
	                if(caseList!=null && caseList.size()>0){
		                if(caseList[0].RecordType.Name.contains('C&R')){
		                    tsk.OwnerID=caseList[0].Case_Manager__c;
		                }
		                else if(caseList[0].RecordType.Name.contains('GATCF')){
		                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
		                }
	                }  
	                taskList.add(tsk);
	            } 
	        }
        } else { //If ePAN originating from PER confirmation page
        	List<Case> caseList = [select id, Status, CaseNumber, RecordType.Name, Case_Manager__c,Foundation_Specialist_gne__c from Case where Patient_Enrollment_Request_gne__c =: trigger.new[0].Patient_Enrollment_Request__c];
			System.debug('trigger.new[0].Patient_Enrollment_Request__c ' + trigger.new[0].Patient_Enrollment_Request__c);
	        System.debug('caseList.size() : ' + caseList.size());
	        
	        if(caseList.size() <= 0) {
	        	return;
	        }
	        
	        if(caseList.size() == 1) { //If only 1 case then create task and activily, irrespective of Case status is Active or not
	        	for(GNE_CM_MPS_ARX_ePAN_Management__c ePanObj : trigger.new){
		        		if(ePanObj.PAN_Status__c=='SUBMITTED' &&
		        			(ePanObj.PAN_Origin_MPS__c=='MPS PER Invitation'
	                  		|| ePanObj.PAN_Origin_MPS__c== 'MPS PER Submit Now')) {
			                Task tsk=new Task();
			                tsk.Subject='ePAN Saved to Case';
			                tsk.ActivityDate=System.today();
			                tsk.Activity_Type_gne__c='Fax Saved to Case';
			                tsk.Process_Category_gne__c='Fax/Document Management';
			                tsk.whatId=caseList[0].Id;
			                tsk.Status='Completed';
			                tsk.Priority='Normal';
			                tsk.Description='Document Type: Paperless PAN';
			               	if(caseList!=null && caseList.size()>0){
				                if(caseList[0].RecordType.Name.contains('C&R')){
				                    tsk.OwnerID=caseList[0].Case_Manager__c;
				                }
				                else if(caseList[0].RecordType.Name.contains('GATCF')){
				                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
				                }
			                } 
			                taskList.add(tsk);
			                
			                tsk=new Task();
			                tsk.Subject='Review Incoming Documents';
			                tsk.ActivityDate=System.today();
			                tsk.Activity_Type_gne__c='Reviewing Incoming Documents';
			                tsk.Process_Category_gne__c='Fax/Document Management';
			                tsk.whatId=caseList[0].Id;
			                tsk.Status='New';
			                tsk.Priority='High';
			                tsk.Description='Document Type: Paperless PAN';
			                if(caseList!=null && caseList.size()>0){
				                if(caseList[0].RecordType.Name.contains('C&R')){
				                    tsk.OwnerID=caseList[0].Case_Manager__c;
				                }
				                else if(caseList[0].RecordType.Name.contains('GATCF')){
				                    tsk.OwnerID=caseList[0].Foundation_Specialist_gne__c;
				                }
			                }  
			                taskList.add(tsk);
		            } 
	        	}
	        } else {
	        	//Process only Active Cases
					for(GNE_CM_MPS_ARX_ePAN_Management__c ePanObj : trigger.new){
		        		if(ePanObj.PAN_Status__c=='SUBMITTED' &&
		        			(ePanObj.PAN_Origin_MPS__c=='MPS PER Invitation'
	                  		|| ePanObj.PAN_Origin_MPS__c== 'MPS PER Submit Now')) {
		        			for(Case aCase : caseList) {
		        				System.debug('Case Number : ' + aCase.CaseNumber);
		        				System.debug('Case Status : ' + aCase.Status);
		        				if(aCase.Status == 'Active') {
					                Task tsk=new Task();
					                tsk.Subject='ePAN Saved to Case';
					                tsk.ActivityDate=System.today();
					                tsk.Activity_Type_gne__c='Fax Saved to Case';
					                tsk.Process_Category_gne__c='Fax/Document Management';
					                tsk.whatId=aCase.Id; 
					                System.debug('tsk.whatId1 : ' + tsk.whatId);
					                tsk.Status='Completed';
					                tsk.Priority='Normal';
					                tsk.Description='Document Type: Paperless PAN';
					               	if(caseList!=null && caseList.size()>0){
						                if(aCase.RecordType.Name.contains('C&R')){
						                    tsk.OwnerID=aCase.Case_Manager__c;
						                }
						                else if(aCase.RecordType.Name.contains('GATCF')){
						                    tsk.OwnerID=aCase.Foundation_Specialist_gne__c;
						                }
					                } 
					                taskList.add(tsk);
					                
					                tsk=new Task();
					                tsk.Subject='Review Incoming Documents';
					                tsk.ActivityDate=System.today();
					                tsk.Activity_Type_gne__c='Reviewing Incoming Documents';
					                tsk.Process_Category_gne__c='Fax/Document Management';
					                tsk.whatId=aCase.Id;
					                System.debug('tsk.whatId2 : ' + tsk.whatId);
					                tsk.Status='New';
					                tsk.Priority='High';
					                tsk.Description='Document Type: Paperless PAN';
					                if(caseList!=null && caseList.size()>0){
						                if(aCase.RecordType.Name.contains('C&R')){
						                    tsk.OwnerID=aCase.Case_Manager__c;
						                }
						                else if(aCase.RecordType.Name.contains('GATCF')){
						                    tsk.OwnerID=aCase.Foundation_Specialist_gne__c;
						                }
					                }  
					                taskList.add(tsk);
		        				}
		        			}
		            } 
	        	}	        	
	        }     	
        }
        
        if(taskList.size()>0){
            system.debug('Inserting task list');
            insert taskList;
            system.debug('tasklist---'+taskList[0].id+' -----task2--- '+taskList[1].id);
        }
        
    }
}