/**
Trigger Name : GNE_gCOI_ComposeEmail_PopulateSenderInfo.cls
Created Date : 06/22/2013
Last Modified: 06/22/2012
Author       : Srinivas Chalasani, Navomi Inc.
Comments     : This populates the formula fields of sender territory #, etc. when a sender is added to the record.
**/
trigger GNE_gCOI_ComposeEmail_PopulateSenderInfo on GNE_gCOI_Message__c (before insert) {
	System.debug('**** Begin trigger GNE_gCOI_ComposeEmail_PopulateSenderInfo');
	
    Set<Id> userIds = new Set<Id>();

    for (GNE_gCOI_Message__c msg : Trigger.New) {
        userIds.add(msg.Sender__c);
    }  
    
    // Map between userId, and user's TerritoryId  
 	Map<Id,Id> userId2terrId = new Map<Id,Id>();
    for (UserTerritory userTerr : [SELECT userId, TerritoryId FROM UserTerritory WHERE
    					userId IN :userIds AND IsActive = true]) {
        userId2terrId.put(userTerr.userId, userTerr.TerritoryId);
    } 
    
    // Territory Ids
	List<Id> territoryIds = userId2terrId.values();
	
	// Map between territoryId and territoryNumber
    Map<Id,String> terId2terNumberMap = new Map<Id,String>();
    //--------- get territory information of users ----------
    system.debug('**** get territory info for user:' + userIds);
    for (Territory terr : [SELECT Id, Name, Territory_Number_gne__c
    					FROM Territory WHERE Id IN :territoryIds]) {
        terId2terNumberMap.put(terr.Id, terr.Territory_Number_gne__c);
    }

    for (GNE_gCOI_Message__c msg : Trigger.New) {
        System.debug('**** adding info to GNE_gCOI_Message__c record, sender:' + msg.Sender__c);
        
        String terrNumber = '';
        Id terrId = (Id) userId2terrId.get(msg.Sender__c);
        if (terrId != null && terId2terNumberMap.get(terrId) != null) {
        	terrNumber = (String) terId2terNumberMap.get(terrId);
        }
        msg.Sender_territory__c = terrNumber;
        System.debug('**** Set Sender_territory__c:' + terrNumber);
    }    
    
    System.debug('**** End of trigger GNE_gCOI_ComposeEmail_PopulateSenderInfo');        
}