trigger GNE_SFA2_PFG_IC_Trigger on SFA2_PFG_Inventory_Count_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if(Trigger.isBefore && Trigger.isInsert){
		GNE_SFA2_PFG_IC_Field_Updates.onBeforeInsert(Trigger.new);
	} else if(Trigger.isBefore && Trigger.isUpdate) {
		GNE_SFA2_PFG_IC_Field_Updates.onBeforeUpdate(Trigger.new,Trigger.old);
	} else if(Trigger.isBefore && Trigger.isDelete){

	} else if(Trigger.isAfter && Trigger.isInsert){
		GNE_SFA2_PFG_IC_Child_Record_Updates.onAfterInsert(Trigger.new);	
	} else if(Trigger.isAfter && Trigger.isUpdate){
		GNE_SFA2_PFG_IC_Child_Record_Updates.onAfterUpdate(Trigger.new, Trigger.old);
	} else if(Trigger.isAfter && Trigger.isDelete){

	}
}