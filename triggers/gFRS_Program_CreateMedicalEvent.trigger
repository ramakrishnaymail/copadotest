trigger gFRS_Program_CreateMedicalEvent on GFRS_Program__c (before update,after insert, after update,after delete) {
	
	//gFRS_Util.createMedicalEventForProgram(trigger.new, trigger.oldMap);
	if(Trigger.isBefore){
		if(Trigger.isUpdate){
			//gFRS_gCalUtil.createMedicalEventForProgram(trigger.new, trigger.oldMap);
		}
	}
	if(Trigger.isAfter){
		if(Trigger.isInsert){
			//gFRS_gCalUtil.createMedicalEventForProgram(trigger.new, trigger.oldMap);	
			gFRS_Util_NoShare.populateVenueCityFutureCall(Trigger.newMap.keySet());
		}else if(Trigger.isUpdate){
			if(gFRS_Util_NoShare.checkIfVenueCityOrStatusUnderProgramChanged(trigger.new, trigger.oldMap,new String []{'Program_Status__c','Venue_City__c'})){
				gFRS_Util_NoShare.populateVenueCityFutureCall(Trigger.newMap.keySet());
			}		
		}else if(Trigger.isDelete){
			gFRS_Util_NoShare.populateVenueCityAfterDelete(Trigger.old);	
		}
	}
}