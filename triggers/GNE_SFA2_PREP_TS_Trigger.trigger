trigger GNE_SFA2_PREP_TS_Trigger on SFA2_PREP_Testing_Strategy_gne__c (before insert, before update) {
    if (!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isTriggerDisabled('GNE_SFA2_PREP_TestingStrategy_Trigger')
        && !GNE_SFA2_PREP_Trigger_Helper.inTestingStrategyTrig()) {
                           
        GNE_SFA2_PREP_Trigger_Helper.setTestingStrategyTrig(true);
        if(Trigger.isBefore && Trigger.isInsert){   
            GNE_SFA2_PREP_TS_Field_Updates.onBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) { 
            GNE_SFA2_PREP_TS_Field_Updates.onBeforeUpdate(Trigger.old, Trigger.new);
        }
        
        GNE_SFA2_PREP_Trigger_Helper.setTestingStrategyTrig(false);
    }
}