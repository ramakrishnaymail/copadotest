trigger Populate_Lookup_Columns_Stg_Ctry on Stg_Ctry_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}