/**
 * Offload business logic to FRM_Triggers.cls for FRM_Metrics_gne__c.
 * Gains: Maintenance, set order of execution
 *
 * @author JH - houj8@gene.com
 * @date Oct 4, 2012
 */

trigger FRM_Classify_Trigger on FRM_Metrics_gne__c (before insert, before update, before delete, after insert, after update, after delete) {
     FRM_Triggers.processTrigger(Trigger.oldMap, Trigger.new, Trigger.isBefore);
}