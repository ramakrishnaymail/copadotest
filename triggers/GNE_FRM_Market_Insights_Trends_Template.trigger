/************************************************************
*  @author: James Hou, Genentech
*  Date: 2013-5-23
*  Description: Offload business logic to GNE_FRM_Market_Insights_Trends_Triggers.cls
*  
*  Modification History
*  Date        Name        Description
*            
*************************************************************/
trigger GNE_FRM_Market_Insights_Trends_Template on Market_Insight_Trend_gne__c (before insert, before update, before delete, after insert, after update, after delete) {
     GNE_FRM_Market_Insights_Trends_Triggers.processTrigger(Trigger.oldMap, Trigger.new, Trigger.isBefore);
}