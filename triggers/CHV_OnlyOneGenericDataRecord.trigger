trigger CHV_OnlyOneGenericDataRecord on CHV_Generic_Data__c (before insert) {

    List<CHV_Generic_Data__c> genericDataList = [select Id from CHV_Generic_Data__c];
    Integer cnt = 0;
    
    for (CHV_Generic_Data__c genericData : Trigger.new){
        if (!genericDataList.isEmpty() || cnt > 0) {
            genericData.addError('There can be only one Generic Data Record!');
        }
        cnt++;
    }
}