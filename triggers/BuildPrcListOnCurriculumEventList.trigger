trigger BuildPrcListOnCurriculumEventList on Curriculum_Module_gne__c (after delete, after insert, after update) {

Set<Id> CurrEventIds = new Set<Id>(); 
List<Event_Curriculum_gne__c> EventCurriculumList = new List<Event_Curriculum_gne__c>();
List<Event_Curriculum_gne__c> EventCurriculumToUpdate = new List<Event_Curriculum_gne__c>();

if(trigger.isInsert || trigger.isUpdate)
{
    for(Curriculum_Module_gne__c tmp : Trigger.new)
    {
        CurrEventIds.add(tmp.Event_Curriculum_gne__c); 
    }   
}
if(trigger.isDelete)
{
    for(Curriculum_Module_gne__c tmp : Trigger.old)
    {
        CurrEventIds.add(tmp.Event_Curriculum_gne__c); 
    }   
}

EventCurriculumList = [Select Name, Id,PRC_Number_gne__c, (Select PRC_ID_gne__c From Curriculum_Modules__r) From Event_Curriculum_gne__c where Id IN :CurrEventIds];

for(Event_Curriculum_gne__c evn :EventCurriculumList)
{
    evn.PRC_Number_gne__c = '';
    for(Curriculum_Module_gne__c curMod :evn.Curriculum_Modules__r)
    {
        if(curMod.PRC_ID_gne__c != null && curMod.PRC_ID_gne__c != '')
        {
                evn.PRC_Number_gne__c += curMod.PRC_ID_gne__c + ',';
        }
    }
    
    if(evn.PRC_Number_gne__c.endsWith(','))
    {
        if(evn.PRC_Number_gne__c.lastIndexOf(',') != -1)
            evn.PRC_Number_gne__c = evn.PRC_Number_gne__c.substring(0,evn.PRC_Number_gne__c.lastIndexOf(','));
    }
    if(evn.PRC_Number_gne__c.length() > 255)
       evn.PRC_Number_gne__c = evn.PRC_Number_gne__c.substring(0,255); 
     
    EventCurriculumToUpdate.add(evn);
}

update EventCurriculumToUpdate;

}