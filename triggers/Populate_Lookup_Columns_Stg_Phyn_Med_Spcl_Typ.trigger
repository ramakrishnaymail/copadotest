trigger Populate_Lookup_Columns_Stg_Phyn_Med_Spcl_Typ on Stg_Phyn_Med_Spcl_Typ_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}