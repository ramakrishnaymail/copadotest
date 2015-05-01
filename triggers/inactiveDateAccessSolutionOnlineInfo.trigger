trigger inactiveDateAccessSolutionOnlineInfo on Access_Solution_Online_Info_gne__c (before insert, before update) {
	if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isMergeMode()){
		for(Access_Solution_Online_Info_gne__c record : Trigger.new){
		    	if(record.Record_Status_gne__c == 'Inactive'){
		        	if(record.Date_Inactive_gne__c == null){
		            	record.Date_Inactive_gne__c =system.today();
		            }
		                                    
		         } else if(record.Record_Status_gne__c != 'Inactive' && record.Date_Inactive_gne__c != null){
		         	record.Date_Inactive_gne__c = null;
		         } 
		}         
    } 
}