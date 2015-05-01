trigger GNE_CollaborationGroup_Trigger on CollaborationGroup (after delete, after insert, after undelete, after update, before delete, before insert, before update){
	
	if (!GNE_SFA2_Util.isAdminMode()){
    	
        if(Trigger.isInsert && Trigger.isBefore){  
            GNE_Chatter_Validation.onBeforeInsertCollaborationGroup(null, Trigger.new);
        }
	
	}

}