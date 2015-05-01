trigger GNE_CM_Operational_VerificationUpdate on Operational_Verification_gne__c (before update) {
    
    for(Operational_Verification_gne__c Ov : trigger.new)
    {
     if(trigger.oldmap.get(Ov.id).OV_Interval_FIN_gne__c != Ov.OV_Interval_FIN_gne__c)
     {
       Ov.FIN_Count_gne__c = 0;
     }
     if(trigger.oldmap.get(Ov.id).OV_Interval_INS_gne__c != Ov.OV_Interval_INS_gne__c)
     {
       Ov.INS_Count_gne__c = 0;
     }
     if(trigger.oldmap.get(Ov.id).OV_Interval_INF_gne__c != Ov.OV_Interval_INF_gne__c)
     {
       Ov.INF_Count_gne__c = 0;
     }
     /* Do not allow NPE */
     if(Ov.OV_Interval_FIN_gne__c == null || Ov.OV_Interval_FIN_gne__c == 0)
     {
        Ov.OV_Interval_FIN_gne__c = 25; // 4% default
     }
     if(Ov.OV_Interval_INS_gne__c == null || Ov.OV_Interval_INS_gne__c == 0)
     {
        Ov.OV_Interval_INS_gne__c = 25; // 4% default
     }
     if(Ov.OV_Interval_INF_gne__c == null || Ov.OV_Interval_INF_gne__c == 0)
     {
        Ov.OV_Interval_INF_gne__c = 25; // 4% default
     }
    }

}