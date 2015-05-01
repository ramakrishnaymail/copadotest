trigger gFRS_FundingAllocationTrigger on GFRS_Funding_Allocation__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {


     /*** BEFORE SECTION ***/
     if( Trigger.isBefore ){
        if(Trigger.isInsert){
            /***Put here your befor instert methods***/
			gFRS_Util.populateGLAccout(Trigger.new);
        }else if(Trigger.isUpdate){
            //***Put here your before Update methods
   
        }else if(Trigger.isDelete){
            //***Put here your before delete methods
        }else if(Trigger.isUnDelete){
            //***Put here your before Undelete methods
        }
    }
        
        /*** AFTER SECTION ***/
    if(Trigger.isAfter){
        if(Trigger.isInsert){
        //*** put here your after inster methods
		/*** SFDC-1996 New Payment/Refund Processing ***/
	    Type t = Type.forName('gFRS_PaymentProcess');
	    gFRS_FundingProcess paymentProcess = (gFRS_FundingProcess)t.newInstance();
	    paymentProcess.createDefaultFALineItems(trigger.new);
	    /***/
                
        }else if(Trigger.isUpdate){           
            	
                //*** put here your after update methods

                
       }else if(Trigger.isDelete){
                //**** put here your after delete methods
       }else if(Trigger.isUnDelete){
                //*** put here your after Undelete methods
       }
   }
}