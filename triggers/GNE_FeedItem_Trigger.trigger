trigger GNE_FeedItem_Trigger on FeedItem (after delete, after insert, after undelete, after update, before delete, before insert, before update){
	
	if (!GNE_SFA2_Util.isAdminMode()){
    	
        if(Trigger.isInsert && Trigger.isBefore){  
            GNE_Chatter_Validation.onBeforeInsertFeedItem(null, Trigger.new);
        }
	
	}
}