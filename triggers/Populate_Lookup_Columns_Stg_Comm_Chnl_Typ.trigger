trigger Populate_Lookup_Columns_Stg_Comm_Chnl_Typ on Stg_Comm_Chnl_Typ_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}