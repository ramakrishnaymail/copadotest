/**
 *  Trigger that creates the default Funding Allocation line items
 **/
trigger GFRS_Funding_Allocation_After_Insert on GFRS_Funding_Allocation__c (after insert) {
    /*** SFDC-1996 New Payment/Refund Processing ***/
    /*Type t = Type.forName('gFRS_PaymentProcess');
    gFRS_FundingProcess paymentProcess = (gFRS_FundingProcess)t.newInstance();
    paymentProcess.createDefaultFALineItems(trigger.new);*/
    /***/
}