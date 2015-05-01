/**
 * Trigger setting MPS_Registration and MPS_Prescriber fields used on reports.
 *
 * Created By: Radek Krawiec
 * Created On: 05/22/2012
 */
trigger GNE_CM_MPS_CaseMPSFieldsTrigger on Case (before insert, before update)
{
    
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
    }
    
    GNE_CM_MPS_Case_Util.updateCaseMPSRegistrationForTrigger(Trigger.NEW);
    
    // make sure this method is called after "updateCaseMPSRegistrationForTrigger" has been called, because
    // it depends on the MPS_Registration__c field set by the above method.
    GNE_CM_MPS_Case_Util.updateCaseMPSPrescriber(Trigger.NEW, false);
    
    //************************************** AS Changes :1/17/2013 **********************************//
    if(trigger.isUpdate)
    {
        for(Case cas:trigger.new)
        {
            try
            {
                string status = cas.Status;
                if(trigger.oldMap.get(cas.id).Status == 'Active' && status.contains('Closed'))
                {
                    cas.Case_Closed_By_gne__c = UserInfo.getUserId();
                }
                if(trigger.oldMap.get(cas.id).Status != status && status == 'Active')
                {
                    cas.Case_Closed_By_gne__c = null;
                }
            }
            catch(exception ex)
            {
                cas.adderror('Error encountered while updating Case '+ex.getmessage());
            }
        }
    }
    if(trigger.isInsert)
    {
        for(Case cas:trigger.new)
        {
            try
            {
                string status = cas.Status;
                if(status.contains('Closed'))
                {
                    cas.Case_Closed_By_gne__c = UserInfo.getUserId();
                }
            }
            catch(exception ex)
            {
                cas.adderror('Error encountered while creating Case '+ex.getmessage());
            }
        }
    }
}