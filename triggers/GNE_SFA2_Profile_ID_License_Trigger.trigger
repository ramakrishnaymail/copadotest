/************************************************************
*  @author: 
*  Date: 
*  Description: This is a trigger for handling ProfileID_License_gne__c
*  Test class: 
*    
*  Modification History
*  Date        Name                 Description
*  2015-01-12  Lukasz Bieniawski   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*************************************************************/

trigger GNE_SFA2_Profile_ID_License_Trigger on ProfileID_License_gne__c (after delete) {
    
    if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isMergeMode()){
        if(Trigger.isAfter && trigger.isDelete){
            GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, ProfileID_License_gne__c.getSObjectType());            
        }
    }
}