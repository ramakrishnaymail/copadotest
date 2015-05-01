trigger prfGRpMp_OnCreateSetName on Profile_to_Group_Map_gne__c (before insert, before update) {
   String PRF_GRP ='PRF_GRP_';
   for(Profile_to_Group_Map_gne__c prfGrp: Trigger.new){
       string grpName = prfGrp.Group_Name_gne__c;
       if (grpName.startsWith(PRF_GRP))
          grpName = grpName.subString(PRF_GRP.length(),grpName.length());
       prfGrp.Name = grpName +'-'+prfGrp.Locale_gne__c+'-'+prfGrp.Profile_Mask_gne__c;
   }
}