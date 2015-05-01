trigger GNE_SFA2_Event_Trigger on Event bulk(before insert,after delete, 
after update, before delete, before update) 
{
    if (!GNE_SFA2_Util.isAdminMode())   
    {
        if(Trigger.isInsert && Trigger.isBefore){  
            GNE_SFA2_Event_Field_Updates.onBeforeInsert(Trigger.new);  
        }
        if(Trigger.isUpdate && Trigger.isBefore){  
            GNE_SFA2_Event_Validation_Rules.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);  
        }
        else if(Trigger.isUpdate && Trigger.isAfter){
            GNE_SFA2_Event_Child_Record_Updates.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        else if(Trigger.isDelete && Trigger.isBefore){  
            GNE_SFA2_Event_Validation_Rules.onBeforeDelete(Trigger.oldMap); 
        }
        else if(Trigger.isDelete && Trigger.isAfter){
          GNE_SFA2_Event_Child_Record_Updates.OnAfterDelete(Trigger.oldMap);
        }
    }
}