/*------------      Name of trigger : GNE_CM_Access_Solutions_Validation   --------------*/
/*------------      This enforces uniqueness and parity requirements       --------------*/
/*------------      for Access Solutions Online Records                    --------------*/
/*------------      Created by: Marc Friedman                              --------------*/
/*------------      Last Modified: 02/01/2009                              --------------*/
/*------------      Last Modified: 03/16/2009 (Shweta Bhardwaj, GDC)       --------------*/
/*------------      Call EV class to get EV values                         --------------*/
trigger GNE_CM_Access_Solutions_Validation on Access_Solution_Online_Info_gne__c (before insert, before update, before delete) {
    
    // Bypass the Trigger if the code is already in process
    if (GNE_CM_AccessSolutionsOnlineHelper.getTriggerInProcess() == false && !GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isMergeMode()) {
        
        // Declare Local Variables
        Access_Solution_Online_Info_gne__c workingASOI;
        List<Access_Solution_Online_Info_gne__c> additionalASOIs = new List<Access_Solution_Online_Info_gne__c>();
        List<Access_Solution_Online_Info_gne__c> accessSolutionsOnline = new List<Access_Solution_Online_Info_gne__c>();
        List<Access_Solution_Online_Info_gne__c> deleteASOIs = new List<Access_Solution_Online_Info_gne__c>();
        List<Access_Solution_Online_Info_gne__c> updateASOIs = new List<Access_Solution_Online_Info_gne__c>();
        List<Access_Solution_Online_Info_gne__c> syncList = new List<Access_Solution_Online_Info_gne__c>();
        List<Environment_Variables__c> envVariables = new List<Environment_Variables__c>();
        Map<String, List<Access_Solution_Online_Info_gne__c>> syncArray = new Map<String, List<Access_Solution_Online_Info_gne__c>>();
        Set<Id> asoiIds = new Set<Id>();
        Set<String> asoiKeys = new Set<String>();
        Set<String> syncDrugs = new Set<String>();
        String productOld;
        String productNew;
        String tempKeyOld;
        String tempKeyNew;
        String username = UserInfo.getUserName();
        Set<string> Access_ID = new Set<string>();
        Set<string> variable = new Set<string>{'Access_Solution_Online_Info_Sync_Drug'};
        System.debug('Starting the code for Access solution online info');
        // Get the drugs for which corresponding records must be kept in sync
        envVariables= GNE_CM_Environment_variable.get_env_variable(variable);
        for (Environment_Variables__c tempEnvVar : envVariables) 
        {
            syncDrugs.add(tempEnvVar.Value__c);
        }
        if(trigger.isinsert || trigger.isupdate)
        {
            for(Access_Solution_Online_Info_gne__c acc:trigger.new)
            {
                if(acc.Prescriber_gne__c !=null)
                Access_ID.add(acc.Prescriber_gne__c);
            }
        }
        else if (trigger.isdelete)
        {
            for(Access_Solution_Online_Info_gne__c acc:trigger.old)
            {
                if(acc.Prescriber_gne__c !=null)
                Access_ID.add(acc.Prescriber_gne__c);
            }           
        }
        // Get all other existing records in the database that will need to be checked
        System.debug('Querying the database');
        if (Trigger.IsUpdate || Trigger.IsDelete) 
        {
            asoiIds = Trigger.oldMap.keySet();
            accessSolutionsOnline = [SELECT Id, Address_gne__c, Prescriber_gne__c, Access_Solutions_Online_ID_gne__c, Drug_gne__c FROM Access_Solution_Online_Info_gne__c WHERE Id NOT IN :asoiIds and Prescriber_gne__c in: Access_ID];
        } 
        else 
        {
            accessSolutionsOnline = [SELECT Id, Address_gne__c, Prescriber_gne__c, Access_Solutions_Online_ID_gne__c, Drug_gne__c FROM Access_Solution_Online_Info_gne__c where Prescriber_gne__c in: Access_ID];
        }
        
        // Create Sets and Maps of unique keys for existing records
        System.debug('Starting the processing of database records');
        for (Integer i = 0; i < accessSolutionsOnline.size(); i++) 
        {
            productOld = (syncDrugs.contains(accessSolutionsOnline[i].Drug_gne__c) ? 'SYNC' : accessSolutionsOnline[i].Drug_gne__c);
            tempKeyOld = accessSolutionsOnline[i].Access_Solutions_Online_ID_gne__c + accessSolutionsOnline[i].Prescriber_gne__c + productOld + accessSolutionsOnline[i].Address_gne__c;
            asoiKeys.add(tempKeyOld);
            
            // If this is an Update or a Delete, create Maps of the existing SYNC records
            if ((Trigger.IsUpdate || Trigger.IsDelete) && productOld == 'SYNC') 
            {                
                // Get the List out of the Map if it already exists
                syncList.clear();
                if (syncArray.containsKey(tempKeyOld)) 
                {
                    syncList = syncArray.get(tempKeyOld);
                }
                // Add the current Access Solutions Online record to the List and update the Map
                syncList.add(accessSolutionsOnline[i]);
                syncArray.put(tempKeyOld, syncList.deepClone(true));
            }
        }
        
        // Process Inserts
        if (Trigger.IsInsert) 
        {
            for (Access_Solution_Online_Info_gne__c asoiTemp : Trigger.new) 
            {
                productNew = (syncDrugs.contains(asoiTemp.Drug_gne__c) ? 'SYNC' : asoiTemp.Drug_gne__c);
                tempKeyNew = asoiTemp.Access_Solutions_Online_ID_gne__c + asoiTemp.Prescriber_gne__c + productNew + asoiTemp.Address_gne__c;
                if (asoiKeys.contains(tempKeyNew)) 
                {
                    asoiTemp.addError('This record cannot be inserted because the combination of Access Solutions ID, Prescriber, Address and Drug already exists.');
                } 
                else 
                {
                    asoiKeys.add(tempKeyNew);
                    
                    // If inserting a SYNC record, create the duplicates by looping through the SYNC drugs and creating a new record for each
                    if (productNew == 'SYNC') 
                    {
                        workingASOI = asoiTemp.clone(false,true);
                        for (String tempDrug : syncDrugs) 
                        {
                            if (asoiTemp.Drug_gne__c != tempDrug) 
                            {
                                workingASOI.Drug_gne__c = tempDrug;
                                additionalASOIs.add(workingASOI.clone(false,true));
                            }
                        }
                        
                        // Set the Helper Class in process and insert the additional records
                        //Taking below insert statement out of for loop
                       // GNE_CM_AccessSolutionsOnlineHelper.setTriggerInProcess();
                       // insert additionalASOIs;
                    }
                }
            }
            if(additionalASOIs.size()>0)
            {
                GNE_CM_AccessSolutionsOnlineHelper.setTriggerInProcess();
                insert additionalASOIs;
            }
        // Process Updates
        } 
        else if (Trigger.IsUpdate) 
        {
            for (Integer i = 0; i < Trigger.old.size(); i++) 
            {
                
                // Get the keys for the record
                productOld = ((syncDrugs.contains(Trigger.old[i].Drug_gne__c)) ? 'SYNC' : Trigger.old[i].Drug_gne__c);
                productNew = ((syncDrugs.contains(Trigger.new[i].Drug_gne__c)) ? 'SYNC' : Trigger.new[i].Drug_gne__c);
                tempKeyOld = Trigger.old[i].Access_Solutions_Online_ID_gne__c + Trigger.old[i].Prescriber_gne__c + productOld + Trigger.old[i].Address_gne__c;
                tempKeyNew = Trigger.new[i].Access_Solutions_Online_ID_gne__c + Trigger.new[i].Prescriber_gne__c + productNew + Trigger.new[i].Address_gne__c;
                
                // If the drug has changed to a SYNC
                if (productOld != 'SYNC' && productNew == 'SYNC')
                {
                    if (asoiKeys.contains(tempKeyNew)) 
                    {
                        Trigger.new[i].addError('This record cannot be updated because the new combination of Access Solutions ID, Prescriber, Address and Drug already exists.');
                    } 
                    else 
                    {
                        asoiKeys.remove(tempKeyOld);
                        asoiKeys.add(tempKeyNew);
                
                        // Create the copies of the SYNC record for the other drugs
                        for (String tempDrug : syncDrugs) 
                        {
                            if (Trigger.new[i].Drug_gne__c != tempDrug) 
                            {
                                workingASOI = Trigger.new[i].clone(false, true);
                                workingASOI.Drug_gne__c = tempDrug;
                                additionalASOIs.add(workingASOI.clone(false,true));
                            }
                        }
                    }
                
                // If the drug has changed from a SYNC
                } 
                else if (productOld == 'SYNC' && productNew != 'SYNC') 
                {
                    if (asoiKeys.contains(tempKeyNew)) 
                    {
                        Trigger.new[i].addError('This record cannot be updated because the new combination of Access Solutions ID, Prescriber, Address and Drug already exists.');
                    } 
                    else 
                    {
                        asoiKeys.remove(tempKeyOld);
                        asoiKeys.add(tempKeyNew);
                        syncList = syncArray.get(tempKeyOld);
                        if (syncList != null) 
                        {
                            for (Integer j = 0; j < syncList.size(); j++) 
                            {
                                
                                // Delete the other SYNC records unless they are also involved in the Update
                                if (syncList[j].Id != Trigger.old[i].Id && !Trigger.oldMap.containsKey(syncList[j].Id)) 
                                {
                                    deleteASOIs.add(syncList[j]);
                                }
                            }
                        }
                    }
                
                // If key fields other than the drug have changed, check to make sure the new combo does not already exist
                } 
                else if (productOld == 'SYNC' && productNew == 'SYNC' 
                    && Trigger.old[i].Drug_gne__c == Trigger.new[i].Drug_gne__c 
                    && (Trigger.old[i].Access_Solutions_Online_ID_gne__c != Trigger.new[i].Access_Solutions_Online_ID_gne__c 
                    || Trigger.old[i].Prescriber_gne__c != Trigger.new[i].Prescriber_gne__c 
                    || Trigger.old[i].Address_gne__c != Trigger.new[i].Address_gne__c) 
                    && asoiKeys.contains(tempKeyNew)) 
                {
                    Trigger.new[i].addError('This record cannot be updated because the new combination of Access Solutions ID, Prescriber, Address and Drug already exists.');
                
                // If the drug changes to another SYNC drug, tell the user to change the correpsonding record instead of this
                } 
                else if (productOld == 'SYNC' && productNew == 'SYNC' 
                    && (Trigger.old[i].Drug_gne__c != Trigger.new[i].Drug_gne__c)) 
                {
                    Trigger.new[i].addError('Rather than changing the Drug on this record to ' + Trigger.new[i].Drug_gne__c + ', please change the existing ' + Trigger.new[i].Drug_gne__c + ' record.');
                
                // If the drug is still a SYNC but other field(s) change(d), update the other SYNC records in the same manner
                } 
                else if (productOld == 'SYNC' && productNew == 'SYNC') 
                {
                    syncList = syncArray.get(tempKeyOld);
                    if(syncList !=null)
                    {
                        for (Integer j = 0; j < syncList.size(); j++) 
                        {                        
                            // If the SYNC record is not the one already being updated
                            if (syncList[j].id != Trigger.old[i].Id) 
                            {                            
                                // Update all of the fields to keep the records in sync
                                syncList[j].Access_Solutions_Online_ID_gne__c = Trigger.new[i].Access_Solutions_Online_ID_gne__c;
                                syncList[j].Prescriber_gne__c = Trigger.new[i].Prescriber_gne__c;
                                syncList[j].Address_gne__c = Trigger.new[i].Address_gne__c;
                                syncList[j].Counter_gne__c = Trigger.new[i].Counter_gne__c;
                                syncList[j].Date_Inactive_gne__c = Trigger.new[i].Date_Inactive_gne__c;
                                syncList[j].Record_Status_gne__c = Trigger.new[i].Record_Status_gne__c;
                                syncList[j].Release_gne__c = Trigger.new[i].Release_gne__c;
                                updateASOIs.add(syncList[j].clone(true));
                            }
                        }
                    }
                
                // The only remaining option is that it's changing from one non-SYNC to another - check to see if the combo exists  
                } 
                else 
                {
                    if (asoiKeys.contains(tempKeyNew)) 
                    {
                        Trigger.new[i].addError('This record cannot be updated because the new combination of Access Solutions ID, Prescriber, Address and Drug already exists.');
                    } 
                    else 
                    {
                        asoiKeys.remove(tempKeyOld);
                        asoiKeys.add(tempKeyNew);
                    }
                }
            }
            GNE_CM_AccessSolutionsOnlineHelper.setTriggerInProcess();
            insert additionalASOIs;
            delete deleteASOIs;
            update updateASOIs;
            
        // If the Trigger is not an Insert or an Update and is therefore a Delete
        } 
        else 
        {
            for (Access_Solution_Online_Info_gne__c asoiTemp : Trigger.old) 
            {
                productOld = (syncDrugs.contains(asoiTemp.Drug_gne__c) ? 'SYNC' : asoiTemp.Drug_gne__c);
                
                // If this was a SYNC record, delete the others
                if (productOld == 'SYNC') 
                {
                    tempKeyOld = asoiTemp.Access_Solutions_Online_ID_gne__c + asoiTemp.Prescriber_gne__c + productOld + asoiTemp.Address_gne__c;
                
                // If records for this unique key have not already been processed for this Delete
                    if (syncArray.containsKey(tempKeyOld)) 
                    {
                        // Get all of the related SYNC records
                        syncList = syncArray.get(tempKeyOld);

                        // Add those not already being deleted
                        for (Integer j = 0; j < syncList.size(); j++) 
                        {
                            if (!Trigger.oldMap.keySet().contains(syncList[j].Id)) 
                            {
                                deleteASOIs.add(syncList[j]);
                            }
                        }

                        syncArray.remove(tempKeyOld);
                    }
                }
            }
            
            // Set the Helper Class in process and delete the additional records
            GNE_CM_AccessSolutionsOnlineHelper.setTriggerInProcess();
            delete deleteASOIs;         
        }       
    }
}