trigger GNE_validateSalesRoster_BeforeInsertUpdate on IC_Calc_Sales_Roster_gne__c (before insert, before update) {
    for (IC_Calc_Sales_Roster_gne__c  objICHeader : Trigger.new) {                                             
        objICHeader.Unique_Key_gne__c = objICHeader.Unique_Key_Calc_gne__c;                         
    }                                                                                               
}