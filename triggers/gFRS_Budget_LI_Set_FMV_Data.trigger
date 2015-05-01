trigger gFRS_Budget_LI_Set_FMV_Data on GFRS_Request_Budget_Line_Item__c (after insert, after update) {
	gFRS_Util.linkBudgetLIsToFMV(trigger.new, trigger.oldMap );
}