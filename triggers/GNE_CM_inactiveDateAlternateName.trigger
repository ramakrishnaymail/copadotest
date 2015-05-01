trigger GNE_CM_inactiveDateAlternateName on Alternate_Name_gne__c (before insert, before update) 
{    
    for(Alternate_Name_gne__c record : Trigger.new)

        {
            if(record.Status_gne__c == 'Inactive')
                {
                    if(record.Date_Inactive_gne__c == null)
                        {
                            record.Date_Inactive_gne__c =system.today();
                        }
                                    
                }
            else if(record.Status_gne__c != 'Inactive' && record.Date_Inactive_gne__c != null)
                {
                    record.Date_Inactive_gne__c = null;
                 } 
        }       
    
}