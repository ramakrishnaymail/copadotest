trigger GNE_CM_Drug_required on Intelligence_Notes_gne__c (before insert,before update)
{
    for(Intelligence_Notes_gne__c intel: trigger.new)
    {
        if(intel.Intelligence_Type_gne__c !=null)
        {
            if((intel.Intelligence_Type_gne__c == 'Triage'
                || intel.Intelligence_Type_gne__c == 'Appeals Process'
                || intel.Intelligence_Type_gne__c == 'Medical Policy/Process'
                || intel.Intelligence_Type_gne__c =='PA/PreD/Process') 
                && intel.Drug_gne__c == null)   
                intel.adderror('Drug field is required if Intelligence type is either Triage, PA/PreD/Process, Medical Policy/Process or Appeals Process');
         }
     }
}