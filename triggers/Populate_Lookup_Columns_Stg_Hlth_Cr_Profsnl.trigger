trigger Populate_Lookup_Columns_Stg_Hlth_Cr_Profsnl on Stg_Hlth_Cr_Profsnl_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}