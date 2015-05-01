trigger SPCM_AttachmentTrigger on Attachment (before insert, before update, before delete)
{
    
    // before event
    if (Trigger.isBefore)
    {
    
        // insert
        if (Trigger.isInsert)
        {
            SPCM_AttachmentUtils.HandleBeforeInsert(Trigger.new);
        }
    
        // update
        if (Trigger.isUpdate)
        {
            SPCM_AttachmentUtils.HandleBeforeUpdate(Trigger.old);
        }
    
        // delete
        if (Trigger.isDelete)
        {
            SPCM_AttachmentUtils.HandleBeforeDelete(Trigger.old);
        }
    }
}