trigger gFRS_LocationDataFirewall on GFRS_Location__c (before insert, before update) {
	gFRS_Util.locationDataFirewall(Trigger.new, Trigger.oldMap);
}