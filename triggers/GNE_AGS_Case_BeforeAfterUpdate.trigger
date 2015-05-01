trigger GNE_AGS_Case_BeforeAfterUpdate on AGS_Case_gne__c (before update) {

//FINAL VERSION

//  This trigger will only fire on update.  So Automatic Case Creation will not fire (those are inserts)
//  This trigger will still account for Batch Case inserts
//  This trigger will copy the Analyst selection into the Owner field, and Vice Versa, Copy the Owner into the Analyst field

    // Capture Bulk case IDs and assign to a SET
    set<ID> case_ids = new set<ID>();
    for(AGS_Case_gne__c cases : Trigger.new){
            case_ids.add(cases.id);
    }
    
    //Pull out the fields needed for our swap, assign to a MAP
    Map<ID, AGS_Case_gne__c> cMap = new Map<ID, AGS_Case_gne__c>([select id, Analyst_gne__c, OwnerId  from AGS_Case_gne__c where id IN :case_ids]);
    ID AGSQueue = [select QueueId from QueueSObject where SObjectType = 'AGS_Case_gne__c'].QueueId;
    
    //Loop through and perform the swaps
    for (Integer i =0; i < trigger.new.size(); i++) {            
        if (trigger.isUpdate) {

            if(trigger.isBefore){
            
            
                //If Analyst = the owner, then all's well.
                if (trigger.new[i].Analyst_gne__c != trigger.new[i].OwnerId){
                
                //Case 1. they're changing the Analyst, make Owner Analyst
                    if (trigger.new[i].Analyst_gne__c != trigger.old[i].Analyst_gne__c){
                        if (trigger.new[i].Analyst_gne__c != null ){
                            trigger.new[i].OwnerID =  trigger.new[i].Analyst_gne__c;
                        }               
                    }
                //Case 2.  When Analyst takes ownership from the queue
                    if (trigger.new[i].OwnerId != AGSQueue){
                        trigger.new[i].Analyst_gne__c =  trigger.new[i].OwnerId;
                        //trigger.new[i].Analyst_gne__c.addError('This is the OwnerID ' + trigger.new[i].OwnerID + ' This is the QueueID '+ AGSQueue);              
                    }

                    //But if they're re-assigning back to the queue, then blank out the analyst
                    if (trigger.new[i].OwnerId != trigger.old[i].OwnerId){
                        if (trigger.new[i].OwnerId == AGSQueue){
                            trigger.new[i].Analyst_gne__c =  null;
                        }           
                    }           
                
                    
                }//End if Analyst is not the Owner
            }//end isBefore
        }
    
    }
    
}