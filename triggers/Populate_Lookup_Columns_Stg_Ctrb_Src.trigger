trigger Populate_Lookup_Columns_Stg_Ctrb_Src on Stg_Ctrb_Src_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}