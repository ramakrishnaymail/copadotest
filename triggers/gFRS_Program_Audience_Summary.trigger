/**
 *  Trigger that works as a 'roll-up summary' to bypass the limitation on the Funding Request
 **/
trigger gFRS_Program_Audience_Summary on GFRS_Program_Audience_Group__c (after delete, after insert, after update) {
if( Trigger.isDelete ){
        gFRS_Util.sumUpAudienceForFundingRequest(trigger.old);
    } else {
        gFRS_Util.sumUpAudienceForFundingRequest(trigger.new);
    }
}