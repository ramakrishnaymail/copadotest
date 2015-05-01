trigger Populate_Lookup_Columns_Stg_Prvd_Lic on Stg_Prvd_Lic_gne__c (before insert, before update) {
	
	     GNE_Subscribe_Utility.populateLookupRefColumn(Trigger.new);

         GNE_Subscribe_Utility.populateLookupRefColumnByLookupTable(Trigger.new, 
                        'Stg_Pty_gne__c',
                        'Prvd_Pty_Id_gne__c',
                        'Prvd_Pty_Id_ref_gne__c' );

}