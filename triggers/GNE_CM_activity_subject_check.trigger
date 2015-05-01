/* 
 *   Versions:
 *   Modified by         Modified Date       Description 
 *   Puneet Aggarwal     5/2/2011            Trigger was modified to stamp following fields on insert of Task:
 *                                           1. Case Record Type Name - Changes done in Case_map query to include RecordType.Name
 *                                           2. Case Address Id -    Changes done in Case_map query to include Addess Id                                         
 *                                           Step 4.2.2 in Tech Doc for CMR3 WS 1
 */
trigger GNE_CM_activity_subject_check on Task (before insert, before update, after insert) 
{
    // SFA2 bypass. Please not remove!
    
    system.debug('GNE_SFA2_Util.isAdminMode(): ' + GNE_SFA2_Util.isAdminMode());
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_CM_activity_subject_check'))
    {
        system.debug('TRIGGER SKIPPED');
        return;
    }
    if(!trigger.isAfter){
    	GNE_CM_activity_subject_check_Utils logic = new GNE_CM_activity_subject_check_Utils();
    	logic.excecuteTaskTriggerLogic(trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate);
    }
   
 }