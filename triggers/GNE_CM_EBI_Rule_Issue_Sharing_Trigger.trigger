trigger GNE_CM_EBI_Rule_Issue_Sharing_Trigger on GNE_CM_EBI_Rule_Issue__c (after insert, after update) {
   	// SFA2 bypass. Please not remove!
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_EBI_Rule_Issue_Sharing_Trigger')) {
        return;
    }	


	// first fill a set with TE queues and users
	String groupId=null;
	Set<String> queueGroupUsers=new Set<String>();

	queueGroupUsers.add([SELECT DeveloperName,Id,Name,Type FROM Group WHERE DeveloperName='GNE_CM_EBI_Vendors'].Id);
	for (GroupMember gm : [SELECT Id,GroupId,Group.DeveloperName, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName='GNE_CM_VENDOR_TE'])
	{
		groupId=gm.GroupId;
		queueGroupUsers.add(gm.UserOrGroupId);
	}

	// detect the BI that are now owned by TE
	Set<String> newBIIds=new Set<String>();

	for (GNE_CM_EBI_Rule_Issue__c ebiNew : trigger.new)
	{
		String oldOwner='';
		
		if (trigger.isUpdate) 
		{
			oldOwner=trigger.oldMap.get(ebiNew.Id).OwnerId;	
		}
		
		if (!queueGroupUsers.contains(oldOwner) && queueGroupUsers.contains(ebiNew.OwnerId))
		{
			newBIIds.add(ebiNew.Benefit_Investigation_ID_gne__c);
		}
	}


	// Insert the manual sharing rules
	// note that 
	List<Patient_gne__Share> lstPatShare=new List<Patient_gne__Share>();
	List<Medical_History_gne__Share> lstMHShare=new List<Medical_History_gne__Share>();
	List<CaseShare> lstCaseShare=new List<CaseShare>();
	List<Insurance_gne__Share> lstInsShare=new List<Insurance_gne__Share>();
	List<AccountShare> lstAccShare=new List<AccountShare>();
	List<Benefit_Investigation_gne__Share> lstBIShare=new List<Benefit_Investigation_gne__Share>();

	for (Benefit_Investigation_gne__c bi : [SELECT Id, Case_BI_gne__c, 
				Case_BI_gne__r.Patient_gne__c, 
				Case_BI_gne__r.Practice_gne__c,
				Case_BI_gne__r.AccountId,
				Case_BI_gne__r.Case_Treating_Physician_gne__c,
				Case_BI_gne__r.Medical_History_gne__c, 
				BI_Insurance_gne__c, 
				BI_Insurance_gne__r.Payer_gne__c,
				BI_Insurance_gne__r.Main_Payer_gne__c,
				BI_Insurance_gne__r.Plan_gne__c,
				BI_Insurance_gne__r.Plan_Product_gne__c
			FROM Benefit_Investigation_gne__c
			WHERE Id IN :newBIIds])
	{
		if (bi.Case_BI_gne__r.Patient_gne__c!=null)
		{
			lstPatShare.add(new Patient_gne__Share (AccessLevel = 'Read',
									RowCause = 'Manual',
	  								UserOrGroupId = groupId,
	  								ParentId = bi.Case_BI_gne__r.Patient_gne__c));
		}
		
		  								
		if (bi.Case_BI_gne__r.Medical_History_gne__c!=null)
		{
			lstMHShare.add(new Medical_History_gne__Share (AccessLevel = 'Read',
									RowCause = 'Manual',
	  								UserOrGroupId = groupId,
	  								ParentId = bi.Case_BI_gne__r.Medical_History_gne__c));
	  	}	
	  	
		if (bi.Case_BI_gne__r.AccountId!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.Case_BI_gne__r.AccountId));
	  	}
	  		
		if (bi.Case_BI_gne__r.Case_Treating_Physician_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.Case_BI_gne__r.Case_Treating_Physician_gne__c));
	  	}	
	  	
		if (bi.Case_BI_gne__r.Practice_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.Case_BI_gne__r.Practice_gne__c));
	  	}	
	  	
	  	if (bi.Case_BI_gne__c!=null)
	  	{
			lstCaseShare.add(new CaseShare (CaseAccessLevel = 'Read',
	  								UserOrGroupId = groupId,
	  								CaseId = bi.Case_BI_gne__c));
		}
		
		if (bi.BI_Insurance_gne__c!=null)
		{
			lstInsShare.add(new Insurance_gne__Share (AccessLevel = 'Read',
									RowCause = 'Manual',
	  								UserOrGroupId = groupId,
	  								ParentId = bi.BI_Insurance_gne__c));
		}
		
		if (bi.BI_Insurance_gne__r.Payer_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.BI_Insurance_gne__r.Payer_gne__c));
		}
		
		if (bi.BI_Insurance_gne__r.Main_Payer_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.BI_Insurance_gne__r.Main_Payer_gne__c));
		}
		
		if (bi.BI_Insurance_gne__r.Plan_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.BI_Insurance_gne__r.Plan_gne__c));
		}

		if (bi.BI_Insurance_gne__r.Plan_Product_gne__c!=null)
		{
			lstAccShare.add(new AccountShare (AccountAccessLevel = 'Read',
									OpportunityAccessLevel = 'None',
	  								UserOrGroupId = groupId,
	  								AccountId = bi.BI_Insurance_gne__r.Plan_Product_gne__c));
		}

		lstBIShare.add(new Benefit_Investigation_gne__Share (AccessLevel = 'Read',
									RowCause = 'Manual',
	  								UserOrGroupId = groupId,
	  								ParentId = bi.Id));
	}

	insert lstPatShare;
	insert lstMHShare;
	insert lstCaseShare;
	insert lstInsShare;
	insert lstBIShare;
	insert lstAccShare;
}