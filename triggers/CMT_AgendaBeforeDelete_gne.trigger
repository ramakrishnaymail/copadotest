trigger CMT_AgendaBeforeDelete_gne on CMT_Agenda_gne__c (before delete) 
{
    CMT_MiscUtils.onDeleteTrigger ('CMT_Agenda_gne__c', Trigger.old);
}