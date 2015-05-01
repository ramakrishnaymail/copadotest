trigger GNE_SFA2_Task_Trigger on Task bulk(before insert,before update, before delete,after delete) {

    if (!GNE_SFA2_Util.isAdminMode()) {
        if(Trigger.isBefore && Trigger.isInsert){
            GNE_SFA2_Task_Field_Updates.onBeforeInsert(Trigger.new);
            GNE_SFA2_Task_Validation_Rules.OnBeforeInsert(Trigger.new);
        } else if(Trigger.isBefore && Trigger.isUpdate) {
            GNE_SFA2_Task_Validation_Rules.OnBeforeUpdate(Trigger.oldMap,Trigger.newMap);
        } else if(Trigger.isBefore && Trigger.isDelete){
            GNE_SFA2_Task_Validation_Rules.OnBeforeDelete(Trigger.oldMap);
        } else if(Trigger.isAfter && Trigger.isDelete){
            GNE_SFA2_Task_Child_Record_Updates.OnAfterDelete(Trigger.oldMap);
        }
    }
}