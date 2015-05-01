trigger GNE_AP_Detail_Trigger on AP_Detail_gne__c (after delete, after insert, after update) {
  if (!GNE_SFA2_Util.isAdminMode())
  {
        
    if(trigger.IsAfter && trigger.IsInsert){
      GNE_AP_Detail_Parent_Record_Updates.onAfterInsert(trigger.new);
    }
    
    
    if(trigger.IsAfter && trigger.IsUpdate){
      GNE_AP_Detail_Parent_Record_Updates.onAfterUpdate(trigger.new);
    }

    if(trigger.IsAfter && trigger.IsDelete){
      GNE_AP_Detail_Parent_Record_Updates.onAfterDelete(trigger.old);
    }
        
  }
    
}