/************************************************************
*  @author: Rakesh Boinepalli 
*  Date: 2012-12-13
*  Description: This is a trigger for handling Event attendee validations, field updates and child record updates
*  Test class: GNE_SFA2_Event_Attendee_Trigger_Test
*    
*  Modification History
*  Date        Name                 Description
*  2014-12-03  Mateusz Michalczyk   Added after delete logic for OTR_Deleted_Record_gne__c record creation.
*            
*************************************************************/


trigger GNE_SFA2_Event_Attendee_Trigger on Event_Attendee_vod__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
 
   if (!GNE_SFA2_Util.isAdminMode()) {   	   	
   	  if(Trigger.IsBefore && Trigger.IsInsert){   	  		   	  	
   	  	GNE_SFA2_Event_Attendee_Validation_Rules.onBeforeInsert(Trigger.New);
   	  	GNE_SFA2_Event_Attendee_Field_Updates.onBeforeInsert(Trigger.New);
   	  } else if(Trigger.IsBefore && Trigger.IsUpdate){   	  
   	  	GNE_SFA2_Event_Attendee_Validation_Rules.onBeforeUpdate(Trigger.old,Trigger.New);
   	  	GNE_SFA2_Event_Attendee_Field_Updates.onBeforeUpdate(Trigger.old,Trigger.New);   	  	
   	  } else if (Trigger.IsBefore && Trigger.IsDelete){   	  	
   	  	 GNE_SFA2_Event_Attendee_Validation_Rules.onBeforeDelete(Trigger.old);   	  	
   	  } else if(Trigger.IsAfter && Trigger.isInsert){   	  	
   	  	GNE_SFA2_Event_Attendee_Trigger_Helper.populateSpeakersFields(Trigger.New);   	  	
   	  } else if(Trigger.isAfter && Trigger.isUpdate){   	  	
   	  	GNE_SFA2_Event_Attendee_Trigger_Helper.populateSpeakersFields(Trigger.New);   	  	
   	  } else if(Trigger.isAfter && Trigger.isDelete){   	  	
   	  	GNE_SFA2_Event_Attendee_Trigger_Helper.populateSpeakersFields(Trigger.old);
   	  	GNE_SFA2_Deleted_Records_Util.onAfterDelete(Trigger.old, Event_Attendee_vod__c.getSObjectType());
   	  }
  }
}