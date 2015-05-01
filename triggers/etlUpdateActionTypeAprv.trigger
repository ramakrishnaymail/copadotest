trigger etlUpdateActionTypeAprv on CADS_Account_Address_Issues_gne__c (before update) 
{
    for(CADS_Account_Address_Issues_gne__c issue: trigger.new)
    {
       if(issue.STEWARD_REVIEW_STS_gne__c == 'N' && issue.PROCESSING_STS_GNE__C == 'Submitted')
       {
           issue.Current_Action_Condition_Type_gne__c = 'Aprv';
           issue.Manual_Action_gne__c = 'No';
       }
    }
}