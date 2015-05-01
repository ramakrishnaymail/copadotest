/** @date 10/31/2012
* @Author Pawel Sprysak
* @description Trigger for AGS_ST_Held_Transaction_gne__c insert, for creating Junction Objects
*/
trigger AGS_ST_HeldTransactionInsert_gne on AGS_ST_Held_Transaction_gne__c (after insert) {
	List<AGS_ST_Held_And_Dispute_Junction_gne__c> newJunctionObjects = new List<AGS_ST_Held_And_Dispute_Junction_gne__c>();
	for(AGS_ST_Held_Transaction_gne__c ht : Trigger.New) {
		if(ht.Dispute_ID_List_gne__c != null) {
			// Splitting string with Dispute Id's
			for(String dispute : ht.Dispute_ID_List_gne__c.split(',', -2)) {
				// Creating junction object for each relation: Dispute <-> Held Transaction
				AGS_ST_Held_And_Dispute_Junction_gne__c junctionObject = new AGS_ST_Held_And_Dispute_Junction_gne__c();
				junctionObject.AGS_ST_Held_Transaction_gne__c = ht.Id;
				junctionObject.AGS_ST_Dispute_Management_gne__c = (Id)dispute;
				newJunctionObjects.add(junctionObject);
			}
		}
	}
	insert newJunctionObjects;
}