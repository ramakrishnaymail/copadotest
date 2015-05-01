/************************************************************
*  @author: Krzysztof Wilczek, Roche
*  Date: 2011-03-01
*  Description: 
*  
*  Modification History
*  Date        Name        Description
*                
*************************************************************/

trigger GNE_CM_Case_FRM_Alignment_Trigger on GNE_CM_Case_Owner_FRM_Alignment__c (before insert, before update, after insert, after update) 
{
    if(CustomSettingsHelper.CMAlignmentSelf().getCurrentRun().get(CustomSettingsHelper.CM_TERRITORY_ALIGNMENT_RUN).TriggerDisabled__c == true)
    {
        return;
    }
        
    Map<String, Set<String>> productZipMap = new Map<String, Set<String>>();
    Map<String, Set<String>> productZipNotToRealign = new Map<String, Set<String>>();
    Map<String, Set<String>> productZipToRealign = new Map<String, Set<String>>();
    //modification of RecordType newly inserted GNE_CM_Case_Owner_FRM_Alignment__c -> after save it should be edit RT
    if(trigger.isInsert && trigger.isBefore)
    {
        Id editFRMRT = Schema.SObjectType.GNE_CM_Case_Owner_FRM_Alignment__c.getRecordTypeInfosByName().get('Edit Case Owner Algmt').getRecordTypeId();
        for(GNE_CM_Case_Owner_FRM_Alignment__c frmAlignment : trigger.new)
        {
            frmAlignment.RecordTypeId = editFRMRT;
        }
    }
        
    //validation rule for 'Case Owner FRM Alignment' object: FRM Zip and product combination should be unique.
    if(trigger.isBefore)
    {
        productZipMap = new Map<String, Set<String>>();
        productZipNotToRealign = new Map<String, Set<String>>();
        productZipToRealign = new Map<String, Set<String>>();
        Set<String> validProducts = GNE_CM_FRM_Alignment_Helper.getProductsForAlignment();
        
        for(GNE_CM_Case_Owner_FRM_Alignment__c frmAlignment : trigger.new)
        {
            //prepare collection of product-zip that already have a flag to be reprocessed
            if(frmAlignment.To_Process_gne__c == true)
            {
                GlobalUtils.addValueToCollection(productZipNotToRealign,
                                                 frmAlignment.GNE_CM_Product_gne__c, 
                                                 frmAlignment.GNE_CM_FRM_Zip_gne__c);               
            }
            //do not realign zips where alignment data did not change
            Boolean notToProcess = false;
            if(trigger.isUpdate 
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_Secondary_Case_Manager_gne__c == frmAlignment.GNE_CM_Secondary_Case_Manager_gne__c
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_FRM_gne__c == frmAlignment.GNE_CM_FRM_gne__c
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_CS_gne__c == frmAlignment.GNE_CM_CS_gne__c
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_Primary_Case_Manager_gne__c == frmAlignment.GNE_CM_Primary_Case_Manager_gne__c
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_Secondary_Foundation_Specialist__c == frmAlignment.GNE_CM_Secondary_Foundation_Specialist__c
                && trigger.oldMap.get(frmAlignment.Id).GNE_CM_Primary_Foundation_Specialist_gne__c == frmAlignment.GNE_CM_Primary_Foundation_Specialist_gne__c)
            {
                GlobalUtils.addValueToCollection(productZipNotToRealign,
                                                 frmAlignment.GNE_CM_Product_gne__c, 
                                                 frmAlignment.GNE_CM_FRM_Zip_gne__c);
                notToProcess = true;
            }
            //do not realign zips where product is not in GNE-CM-Auto-Alignment-Product environment variable
            if(!validProducts.contains(frmAlignment.GNE_CM_Product_gne__c))
            {
                GlobalUtils.addValueToCollection(productZipNotToRealign,
                                                 frmAlignment.GNE_CM_Product_gne__c, 
                                                 frmAlignment.GNE_CM_FRM_Zip_gne__c);               
                notToProcess = true;    
                if(Trigger.isInsert)
                {
                    frmAlignment.addError('This Product is not enabled for auto-alignment. Please pick another Product.');
                }
            }           
            
            //actual validation - for duplicates in passed collection
            if(productZipMap.containsKey(frmAlignment.GNE_CM_Product_gne__c))
            {
                if(productZipMap.get(frmAlignment.GNE_CM_Product_gne__c).contains(frmAlignment.GNE_CM_FRM_Zip_gne__c))
                {
                    frmAlignment.addError('Product (' + frmAlignment.GNE_CM_Product_gne__c + ') and ZipCode (' + frmAlignment.GNE_CM_FRM_Zip_gne__c + ') combination must be unique in GNE_CM_Case_Owner_FRM_Alignment__c object.');
                    GlobalUtils.addValueToCollection(productZipNotToRealign,
                                                 frmAlignment.GNE_CM_Product_gne__c, 
                                                 frmAlignment.GNE_CM_FRM_Zip_gne__c);                    
                }
                else
                {                   
                    productZipMap.get(frmAlignment.GNE_CM_Product_gne__c).add(frmAlignment.GNE_CM_FRM_Zip_gne__c);
                    if(!notToProcess)
                    {
                        frmAlignment.To_Process_gne__c = true;
                    }                    
                }
            }
            else
            {
                productZipMap.put(frmAlignment.GNE_CM_Product_gne__c, new Set<String>{frmAlignment.GNE_CM_FRM_Zip_gne__c});
                if(!notToProcess)
                {
                    frmAlignment.To_Process_gne__c = true;
                }                
            }
        }
        
        //validation for duplicates in existing data                    
        List<List<String>> invalidData = GNE_CM_FRM_Alignment_Helper.getInvalidProductZip(productZipMap);                       
        for(GNE_CM_Case_Owner_FRM_Alignment__c frmAlignment : trigger.new)
        {
            for(List<String> productZipPair : invalidData)
            {
                if(frmAlignment.GNE_CM_Product_gne__c == productZipPair[0] &&
                    frmAlignment.GNE_CM_FRM_Zip_gne__c == productZipPair[1])
                    {                           
                        if(trigger.isUpdate 
                            && trigger.oldMap.get(frmAlignment.Id).GNE_CM_Product_gne__c == frmAlignment.GNE_CM_Product_gne__c)
                        {
                            continue;
                        }                           
                        frmAlignment.addError('Product (' + frmAlignment.GNE_CM_Product_gne__c + ') and ZipCode (' + frmAlignment.GNE_CM_FRM_Zip_gne__c + ') combination must be unique in GNE_CM_Case_Owner_FRM_Alignment__c object.');
                        GlobalUtils.addValueToCollection(productZipNotToRealign,
                                                 frmAlignment.GNE_CM_Product_gne__c, 
                                                 frmAlignment.GNE_CM_FRM_Zip_gne__c);                        
                    }
            }
        }
    }
}