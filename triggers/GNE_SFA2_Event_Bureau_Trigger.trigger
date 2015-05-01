/************************************************************
*  @author: Rakesh Boinepalli 
*  Date: 2012-12-14
*  Description: This is a trigger for handling Event Bureaus validations, field updates and child record updates
*  Test class: GNE_SFA2_Event_Attendee_Trigger_Test
*    
*  Modification History
*  Date        Name        Description
*            
*************************************************************/

trigger GNE_SFA2_Event_Bureau_Trigger on Event_Bureaus_gne__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (!GNE_SFA2_Util.isAdminMode())
    {
   	   	
   	  if(Trigger.IsBefore && Trigger.IsInsert){
   	  	
   	   	GNE_SFA2_Event_Bureau_Field_Updates.onBeforeInsert(trigger.New);
   	   	
   	  }
    }
}