trigger gFRS_PaymentHistoryTrigger on GFRS_Payment_History__c (after delete, after insert, after undelete,after update, before delete, before insert, before update) 
{

/*** BEFORE SECTION ***/
     if( Trigger.isBefore )
     {
        if(Trigger.isInsert)
        {
           
        }
        else if(Trigger.isUpdate)
        {
            gFRS_FundingProcess.CheckESBPaymentUpdate(Trigger.new,Trigger.oldMap);     
        }
        else if(Trigger.isDelete)
        {
        }
        else if(Trigger.isUnDelete)
        {
        }
    }
    
    /*** AFTER SECTION ***/
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            
        }
        else if(Trigger.isUpdate)
        {   
            /*Releases the paymentHistory if the ESB sets the status into released, and sets the status of the
             funding request to approved.*/        
            gFRS_FundingProcess.releasePaymentHistoryApprovesFR( Trigger.new, Trigger.oldMap );
            
            gFRS_FundingProcess.updateRefundedAmountAfterRefundHistorySuccess( Trigger.new, Trigger.oldMap );
        }
        else if(Trigger.isDelete)
        {
            gFRS_FundingProcess.updateRefundedAmountAfterRefundHistoryDeleted(Trigger.old);
        }
        else if(Trigger.isUnDelete)
        {

        }
    }

}