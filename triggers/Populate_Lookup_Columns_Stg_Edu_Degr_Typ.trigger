trigger Populate_Lookup_Columns_Stg_Edu_Degr_Typ on Stg_Edu_Degr_Typ_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}