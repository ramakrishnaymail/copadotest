trigger Populate_Lookup_Columns_Stg_Indv on Stg_Indv_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}