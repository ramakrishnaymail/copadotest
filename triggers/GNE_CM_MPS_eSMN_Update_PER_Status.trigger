trigger GNE_CM_MPS_eSMN_Update_PER_Status on GNE_CM_MPS_ARX_eSMN_Management__c (after delete, after insert, after update)
{
	// just call the util method that does all the logic
	GNE_CM_MPS_eSMN_Trigger_Util.onInsertUpdateDeleteTrigger(Trigger.NEW);
}