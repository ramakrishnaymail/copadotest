trigger assignParentTerritory on Territory (before insert) {

     Set<String> terrNamesToQuery = new Set<String>{};
     for(Territory t : Trigger.new){
            if(t.parent_external_id_gne__c != null){
                System.debug('Need to find the Id of Territory: ' + t.parent_external_id_gne__c);
                terrNamesToQuery.add(t.parent_external_id_gne__c);           
            }   
            
     } 
     
     Map<String,String> territoryLookup = new Map<String,String>();
     for(Territory t : [select external_id_gne__c,id from Territory where external_id_gne__c IN :terrNamesToQuery]) {
         territoryLookup.put(t.external_id_gne__c, t.id);
     }
       
     for(Territory t : Trigger.new) {
            if(t.parent_external_id_gne__c != null){
                if(territoryLookup.containsKey(t.parent_external_id_gne__c)){
                    System.debug('Found the parent territory id for Territory with parent_external_id_gne__c ' + t.parent_external_id_gne__c);
                    t.parentTerritoryId = territoryLookup.get(t.parent_external_id_gne__c);
                }   
                else{
                    System.debug('Error: Could not find the Parent Territory for parent_external_id_gne__c: ' + t.parent_external_id_gne__c);
                    t.addError('Error: Could not find the Parent Territory for parent_external_id_gne__c: ' + t.parent_external_id_gne__c);
                }
            }
     }
}