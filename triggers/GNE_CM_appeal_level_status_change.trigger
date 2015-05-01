/*------------      Name of trigger : GNE_CM_appeal_level_status_change       --------------*/
/*------------                                                                --------------*/
/*------------      This code timestamps the Date Status Changed field        --------------*/
/*------------      every time the Appeal Status changes                      --------------*/
/*------------                                                                --------------*/
/*------------      Created by: Marc Friedman                                 --------------*/
/*------------      Last Modified: 12/09/2008                                 --------------*/

trigger GNE_CM_appeal_level_status_change on Appeal_Level_gne__c (before update) {
    //skip this trigger if it is triggered from transfer wizard
    if(GNE_CM_MPS_TransferWizard.isDisabledTrigger){
     return;
   }
    // Loop through the Appeal Levels in the Trigger.  If the Appeal Status has changed, stamp the Date Status Changed field
    for (Integer i = 0; i < Trigger.new.size() ; i++ ) {
        if (Trigger.old[i].Appeal_Status_gne__c != Trigger.new[i].Appeal_Status_gne__c) {
            Trigger.new[i].Date_Status_Changed_gne__c = datetime.now();
        }
    }
    
}