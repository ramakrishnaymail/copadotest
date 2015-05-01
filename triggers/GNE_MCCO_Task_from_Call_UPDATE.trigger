trigger GNE_MCCO_Task_from_Call_UPDATE on Task (before insert) {

	// SFA2 bypass
	if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('GNE_MCCO_Task_from_Call_UPDATE')) {
		return;
	}


    
    for (Integer i=0; i<trigger.new.size(); i++) {
        if (trigger.new[i].Followup_Activity_Type_vod__c != null && trigger.new[i].Subject == 'Other - See Comments') {  
            trigger.new[i].Subject = trigger.new[i].Description;


        }       
    }
    
   
    

}