trigger GNE_SFA2_Question_After_Insert on Question_gne__c (after insert) {
    try{
        // Why do we need to check this ?? 
        if(Util.isQuestionsAfterInsert){
            GNE_SFA2_Add_Questions.AddQuestionsAfterInsert(Trigger.new,UserInfo.getUserId());
            // Why are we changing it to false, this will ensure that this trigger gets executed only once ??
            Util.isQuestionsAfterInsert = false;
        }
    }catch(Exception e)
    {
        trigger.old[0].addError(' exception:'+ e.getMessage());
    }
}