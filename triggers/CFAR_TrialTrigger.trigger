trigger CFAR_TrialTrigger on CFAR_Trial_gne__c (after insert, after update, before insert, before update) {
    if(!CFAR_Utils.hasAlreadyProcessed()) {    	
        if(Trigger.isInsert && Trigger.isAfter ){
            CFAR_Utils.createMilestoneActivities(trigger.newMap); 
            CFAR_Utils.createOrUpdateTeamMembers(trigger.newMap, null);
            CFAR_Utils.handleGeneralIndicationsNew(trigger.newMap);
            CFAR_Utils.handleSpecificIndicationsNew(trigger.newMap);          
        }
        //it's not needed since, there're no updates of Pri Cont / Inv / MSL from other places than Team Info tab (e.g. General Info)
        /**
        if(Trigger.isUpdate && Trigger.isAfter ){
            CFAR_Utils.createOrUpdateTeamMembers(trigger.newMap, trigger.oldMap);

        }
        */
        
        /**
        if(Trigger.isInsert && Trigger.isBefore) {
			CFAR_Utils.setIRBValueYes(trigger.new);   
		}
    	*/
    	
    	if(Trigger.isUpdate && Trigger.isAfter){
    		CFAR_MilestonesUtils.handleNumOfMonthsChanged(trigger.oldMap,trigger.newMap);
    		CFAR_Utils.handleOtherGNEAgentsChanged(trigger.oldMap,trigger.newMap);  		
    		CFAR_Utils.handleGeneralIndicationsChanged(trigger.oldMap,trigger.newMap);
    		CFAR_Utils.handleSpecificIndicationsChanged(trigger.oldMap,trigger.newMap);  
    	}

    }
    if(Trigger.isUpdate && Trigger.isBefore) {
			CFAR_MilestonesUtils.handleTrialsChange(trigger.oldMap,trigger.newMap);      
		}

    
}