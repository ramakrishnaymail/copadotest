trigger GNE_CM_Case_MultiTherapyView on Case (before insert, before update)
{
    if (GNE_CM_MultiTherapyView_Trigger_Class.isDisabledTrigger)
    {
        System.debug('Skipping trigger GNE_CM_Case_MultiTherapyView');
        return;     
    }

    if (GNE_CM_UnitTestConfig.isSkipped('GNE_CM_Case_MultiTherapyView'))
    {
        return;
    }  
    
    if (!GNE_CM_MultiTherapyView_Util_Class.isMtvTriggerFlag())
    {
        GNE_CM_MultiTherapyView_Util_Class.setMtvTriggerFlag(true);
        if (Trigger.isBefore && Trigger.isInsert)
        {
            GNE_CM_MultiTherapyView_Trigger_Class.onBeforeInsert(Trigger.new);
        }
        else if (Trigger.isBefore && Trigger.isUpdate)
        {
            GNE_CM_MultiTherapyView_Trigger_Class.onBeforeUpdate(Trigger.oldMap, Trigger.new);
        }
        GNE_CM_MultiTherapyView_Util_Class.setmtvTriggerFlag(false);
    }
}