trigger gFRS_Budget_Set_FMV_Data on GFRS_RequestBudget__c (after insert,after update) {
	gFRS_Util.assignRequestBudgetFMV( Trigger.new, Trigger.oldMap );
}