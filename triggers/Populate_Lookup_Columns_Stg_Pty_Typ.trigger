trigger Populate_Lookup_Columns_Stg_Pty_Typ on Stg_Pty_Typ_gne__c (before insert, before update) {GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);}