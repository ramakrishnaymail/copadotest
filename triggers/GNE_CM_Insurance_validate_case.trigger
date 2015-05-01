trigger GNE_CM_Insurance_validate_case on Insurance_gne__c (after update) 
{
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger || GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_Insurance_validate_case')){
        return;
    }
    
    // map of caseID and insuranceID
    Map<id, string> insCases = new Map<id, string>();
    for(Insurance_gne__c ins :Trigger.new)
    {               
        insCases.put(ins.Case_Insurance_gne__c, ins.id);
    }
    
    for (Case c : [SELECT id, Patient_gne__c FROM Case WHERE id IN : insCases.keySet()])
    {       
        Insurance_gne__c relatedInsurance = Trigger.oldMap.get(insCases.get(c.id));
        if (relatedInsurance.Patient_Insurance_gne__c != c.Patient_gne__c)
            Trigger.newMap.get(insCases.get(c.id)).addError('Only cases related to Insurance\'s Patient can be saved.');
    }
}