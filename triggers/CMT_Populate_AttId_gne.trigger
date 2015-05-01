trigger CMT_Populate_AttId_gne on Attachment (after insert) 
{
    Map<Id, Id> parentRecAttIdMap = new Map<Id, Id>();
    
    for(Attachment att : Trigger.new)
    {
        parentRecAttIdMap.put(att.ParentId, att.Id);
    }
    List<CMT_Attachment_gne__c> customAttList = new List<CMT_Attachment_gne__c>();
    customAttList = [Select Id from CMT_Attachment_gne__c where Id IN : parentRecAttIdMap.keySet()];
    if(customAttList.size() >0)
    {
        for(CMT_Attachment_gne__c cAtt : customAttList)
        {
            for(Id attParentId : parentRecAttIdMap.keySet())
            {
                if(cAtt.Id == attParentId)
                {
                    cAtt.downloadURL_gne__c = '/services/data/v23.0/sobjects/Attachment/'+parentRecAttIdMap.get(attParentId)+'/body';                   
                }
            }
        }
    }
    update customAttList;
}