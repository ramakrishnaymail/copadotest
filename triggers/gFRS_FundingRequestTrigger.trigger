trigger gFRS_FundingRequestTrigger on GFRS_Funding_Request__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update)
{
    GFRS_OrgSettings__c myOrgCS = GFRS_OrgSettings__c.getOrgDefaults();
    if(myOrgCS.Funding_Request_Trigger_Enabled__c){
        System.debug('GFRS DEV DEBUG: gFRS Funding Request Trigger ENABLED');
        
         /*** BEFORE SECTION ***/
         if( Trigger.isBefore )
         {
            if(Trigger.isInsert)
            {
                /***Put here your befor instert methods***/
                gFRS_Util.updateStatusLastModifiedDate2( trigger.new, trigger.oldMap );
                gFRS_Util_NoShare.setLastGrantStatus(trigger.new, trigger.oldMap);
                //SFDC-3513 BU-TA defaulting
                gFRS_Util.SetBusinessUnit(Trigger.new,trigger.oldMap);
            }
            else if(Trigger.isUpdate)
            {
                //***Put here your before Update methods
                
                
                gFRS_Util_NoShare.foundationBA1ApproveSubStatusUpdate(Trigger.newMap,trigger.oldMap);
                //SFDC-3513 BU-TA defaulting
                
                gFRS_Util.SetBusinessUnit(Trigger.new,trigger.oldMap);
                
                gFRS_Util.setBiogenIdecLogo(Trigger.newMap, Trigger.new,myOrgCS);  
                //
                gFRS_Util_NoShare.setLastGrantStatus(trigger.new, trigger.oldMap);
                //
                gFRS_Util_NoShare.setClosedDate(trigger.new, trigger.oldMap);
                //
                gFRS_Util_NoShare.resetSysRequestApprovedToNo(trigger.new, trigger.oldMap);
                //
                gFRS_Util_NoShare.setProcessPaymentStatusDate(trigger.new, trigger.oldMap);
                //
                gFRS_Util.autoPopulateCCOOwnerIfNeeded(Trigger.new, Trigger.oldMap);
                //SFDC-1457
                gFRS_Util.updateUnixID(trigger.new, trigger.oldMap );
                //SFDC-1468
                gFRS_Util.RfiResetInformationNeeded(Trigger.new);
                //
                gFRS_Util.setApprovalOptionalStepStatus( Trigger.new, Trigger.OldMap );
                //
                gFRS_Util.transferApprovalSteps( Trigger.new, Trigger.oldMap );
                //
                gFRS_Util.updateStatusLastModifiedDate2( trigger.new, trigger.oldMap );
                //         
                gFRS_Util.updateFundingTypeName(trigger.new, trigger.oldMap);
                //
                gFRS_Util.resetFieldsAfterRecall(trigger.new, trigger.oldMap);
                
                gFRS_Util.setRecallDate(trigger.new, trigger.oldMap);
                //
                gFRS_Util.beforeUpdateFundingRequestLogic(trigger.new, trigger.oldMap); 
                //
               gFRS_Util_NoShare.setDeliveryMethodForFundationOrNo(trigger.new, trigger.oldMap);
               //
               gFRS_Util.setFundingSubTypeForInternalFundingTypes(trigger.new, trigger.oldMap);           
            }
            else if(Trigger.isDelete)
            {
                //***Put here your before delete methods
            }
            else if(Trigger.isUnDelete)
            {
                //***Put here your before Undelete methods
            }
        }
        
        /*** AFTER SECTION ***/
        if(Trigger.isAfter)
        {
            if(Trigger.isInsert)
            {
                //*** put here your after inster methods
                //from GFRS_FR_Create_Funding_Allocation trigger
               
                /*new implementation of creating default Funding allocation.*/
                Type t = Type.forName('gFRS_PaymentProcess');
                gFRS_FundingProcess paymentProcess = (gFRS_FundingProcess)t.newInstance();
                paymentProcess.createFundingAllocation(Trigger.newMap);
       
                gFRS_Util.createDefaultFRPrograms( trigger.new );
                
                gFRS_Util.assignFinancialApprovers( trigger.new);
                
                gFRS_Util.upsertFundingRequestStatusHistory(trigger.newMap, null);
                
            }
            else if(Trigger.isUpdate)
            {           
            	
                //*** put here your after update methods
                //gFRS_Util_NoShare.restrictBA1FromEditting(Trigger.newMap,trigger.oldMap);
                
                gFRS_Util_NoShare.validateBA1Approval(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.validateFA1Approval(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.validateFA3Approval(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.stopApprovalProcessIFBADidntSetApprovedAmount(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.stopApprovalProcessIFFA3DidntSetComAcitvity(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.stopApprovalProcessIfGCDidntSetApprovers(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.stopApprovalIfLRNotSpecified(Trigger.newMap,trigger.oldMap);
                gFRS_Util_NoShare.addSharingForBrBaApproversForFoundation(Trigger.newMap,trigger.oldMap);
                gFRS_Util.upsertFundingRequestStatusHistory(trigger.newMap, trigger.oldMap);
                System.debug('Check how many times its executed');
                //gFRS_gCalUtil.addProgramsToGcalUnderFundingRequest(trigger.newMap, trigger.oldMap);
                
                /*** SFDC-1996 New Payment/Refund Processing ***/
                Type t = Type.forName('gFRS_PaymentProcess');
                gFRS_FundingProcess paymentProcess = (gFRS_FundingProcess)t.newInstance();
                paymentProcess.createFundingAllocation(Trigger.newMap);
                paymentProcess.updateFieldInitiatedExhibitsSplits(trigger.new, trigger.oldMap, trigger.newMap);
                paymentProcess.resetFALITotalAmount(Trigger.new, Trigger.oldMap );
                paymentProcess.updateFALIFundingRequestType( Trigger.new, Trigger.oldMap );
                /***/
                
                gFRS_Util_NoShare.createAppropriateTask(trigger.new, trigger.oldMap);
                
                //gFRS_Util.confirmApprovedHC_Programs( trigger.new, trigger.oldMap );
                
                gFRS_Util_NoShare.submitHC_Programs( trigger.new, trigger.oldMap );
                
                gFRS_Util.createActivities(trigger.new, trigger.oldMap, trigger.newMap);
                
                //gFRS_Util.updateStatus(trigger.new, trigger.oldMap, trigger.newMap);
                
                gFRS_Util.changeStatusOnApproval( Trigger.new, Trigger.oldMap );
                 
                
                gFRS_Util.submitForApproval(Trigger.new, Trigger.oldMap);
                
            }
            else if(Trigger.isDelete)
            {
                //**** put here your after delete methods
            }
            else if(Trigger.isUnDelete)
            {
                //*** put here your after Undelete methods
            }
        }
    }
    else{
        System.debug('GFRS DEV DEBUG: gFRS Funding Request Trigger DISABLED');  
    }
}