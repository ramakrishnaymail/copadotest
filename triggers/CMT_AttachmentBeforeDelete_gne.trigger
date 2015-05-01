trigger CMT_AttachmentBeforeDelete_gne on CMT_Attachment_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Attachment_gne__c', Trigger.old);
}