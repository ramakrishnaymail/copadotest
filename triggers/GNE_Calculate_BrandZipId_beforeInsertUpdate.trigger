trigger GNE_Calculate_BrandZipId_beforeInsertUpdate on Zip_to_Territory_gne__c (before insert, before update) {
    for (Zip_to_Territory_gne__c zipToTerr : Trigger.new) {
        zipToTerr.Brand_Zip_Id_gne__c = zipToTerr.STARS_BrandCode_gne__c + '_' +
                             zipToTerr.Zip_Code_gne__c + '_' +
                             zipToTerr.Territory_Number_gne__c;
    }
}