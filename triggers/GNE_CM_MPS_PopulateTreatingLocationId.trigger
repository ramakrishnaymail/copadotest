trigger GNE_CM_MPS_PopulateTreatingLocationId on GNE_CM_MPS_Practice_Agreement_Location__c (after insert, after update) {
	if(!GNE_SFA2_Util.isAdminMode() && !GNE_SFA2_Util.isMergeMode()){
	
		List<Patient_Enrollment_Request_gne__c> update_per=new List<Patient_Enrollment_Request_gne__c>();
		List<Patient_Enrollment_Request_gne__c> patient_value=new List<Patient_Enrollment_Request_gne__c>();
		List<GNE_CM_MPS_Practice_Agreement__c> practiceAgreementList;
		
		//AS Changes CMGTT-11 
		List<Address_vod__c> lstToUpdate = new List<Address_vod__c>();
		Set<Id> AddressId                = new Set<Id>();
		Set<Id> AddressIdUpdateTrue      = new Set<Id>();
		Set<Id> AddressIdUpdateFalse     = new Set<Id>();
		//AS Changes End
		
		Set<Id> mpsRegistrations = new Set<Id>();
		Set<Id> mpsPrescribers = new Set<Id>();
		Set<Id> mpsLocations = new Set<Id>();
		
		for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location : Trigger.new) 
		{
			if (practice_location.MPS_Registration__c != null)
			{
				mpsRegistrations.add(practice_location.MPS_Registration__c);
			}
			if (practice_location.Account__c != null)
			{
				mpsPrescribers.add(practice_location.Account__c);
			}
			if (practice_location.MPS_Location__c != null)
			{
				mpsLocations.add(practice_location.MPS_Location__c);
			}
		}
		
		Map<Id, Patient_Enrollment_Request_gne__c> patient_map = new Map<Id, Patient_Enrollment_Request_gne__c>([select id,Prescriber_gne__c, GNE_CM_MPS_RegId__c, GNE_CM_MPSLocationId__c,
				Treating_Location_ID_gne__c,Treating_Location_Name_gne__c, Prescriber_Street_Address_gne__c, 
				Prescriber_City_gne__c, Prescriber_State_gne__c, Prescriber_Zip_gne__c
				from Patient_Enrollment_Request_gne__c 
				where GNE_CM_MPS_RegId__c IN :mpsRegistrations AND Prescriber_gne__c IN :mpsPrescribers AND GNE_CM_MPSLocationId__c IN :mpsLocations]);
		//and Status__c = 'Draft']);     
		patient_value=patient_map.values();
		
		//there is not direct relation b/w Practice Agreement Location and PER object due to this we are using for loop in another for loop
		if(Trigger.isInsert)
		{	
			for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new)  // Triggered Records
			{
				for(Patient_Enrollment_Request_gne__c patient:patient_value)  // Trigger checks all PER records to match existing if condition if there is any records or relation found stamp address Id.
				{
					if (patient.Prescriber_gne__c==practice_location.Account__c && patient.GNE_CM_MPS_RegId__c==practice_location.MPS_Registration__c
							&& patient.GNE_CM_MPSLocationId__c==practice_location.MPS_Location__c && patient.Treating_Location_ID_gne__c==null)
					{
						patient.Treating_Location_ID_gne__c=practice_location.Address__c;
						patient.Treating_Location_Name_gne__c=practice_location.Address__r.name;
						update_per.add(patient);
					}
				}
			}    
			update update_per;
		}
		
		
		if(Trigger.isUpdate)
		{
			Map<Id, Id> treatinglocationId=new Map<Id,Id>();
			Id old_treating_id;
			for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.old)
			{
				treatinglocationId.put(practice_location.id,practice_location.Address__c);
			}
			for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new)  // Triggered Records
			{
				old_treating_id=treatinglocationId.get(practice_location.id);
				for(Patient_Enrollment_Request_gne__c patient:patient_value) 
				{
					if (patient.Prescriber_gne__c==practice_location.Account__c && patient.GNE_CM_MPS_RegId__c==practice_location.MPS_Registration__c
							&& patient.GNE_CM_MPSLocationId__c==practice_location.MPS_Location__c && patient.Treating_Location_ID_gne__c==old_treating_id)
					{
						patient.Treating_Location_ID_gne__c=practice_location.Address__c;
						patient.Treating_Location_Name_gne__c=practice_location.Address__r.name;
						update_per.add(patient);
					}
				}
				
			}   
			update update_per;
		}
		
		//AS Changes CMGTT-11
		if(Trigger.isInsert)
		{
			//looking for active addresses
			Map<Id,Id> palIdToAddressIdMap = new Map<Id,Id>();
			for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new)
			{
				if(practice_location.Address__c != null)
				{
					// AddressId.add(practice_location.Address__c);
					palIdToAddressIdMap.put(practice_location.id,practice_location.Address__c);
				}
			}
			System.debug('palIdToAddressIdMap---'+palIdToAddressIdMap);
			
			Map<Id,Address_vod__c> mapAddVod = new Map<Id,Address_vod__c>([Select id,Registered_for_MPS_gne__c from Address_vod__c where Inactive_vod__c=false and id in : palIdToAddressIdMap.values()]);
			System.debug('mapAddVod---'+mapAddVod);
			
			if(mapAddVod != null && mapAddVod.size() > 0)
			{
				String inactiveAddressErrorMessage = System.Label.There_must_be_at_least_one_active_primary_address_for_each_account;
				//Check if the address from the Practice Agreement Location is in the Map
				//If it is, then update the MPS Registration flag on the address. 
				//If the address from Practice Agreement Location isn't in the map, then display error.
				for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new){
					system.debug('mapAddVod.containsKey(' + practice_location.Address__c + '): ' + mapAddVod.containsKey(practice_location.Address__c));
					if(!mapAddVod.containsKey(practice_location.Address__c)){
						//Trigger.newMap.get(practice_location.Id).addError(inactiveAddressErrorMessage);
						Trigger.newMap.get(practice_location.Id).addError('Selected address is Inactive. Can not be mapped.');
					}else{
						Address_vod__c AddVod = mapAddVod.get(practice_location.Address__c);
						AddVod.Registered_for_MPS_gne__c = true;
						lstToUpdate.add(AddVod);
					}
				}
				
				/*for(Id addId :mapAddVod.keySet())
				{
					Address_vod__c AddVod = mapAddVod.get(addId);
					if(AddVod != null)
					{
						AddVod.Registered_for_MPS_gne__c = true;
						lstToUpdate.add(AddVod);
					}
				}*/
				
				//location status cannot be pending
				Map<Id,GNE_CM_MPS_Location__c> locations = new Map<Id,GNE_CM_MPS_Location__c>([select Id,Intake_Status__c from GNE_CM_MPS_Location__c where id in :mpsLocations]);
				for (GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new)
				{
					if (locations.containsKey(practice_location.MPS_Location__c) && locations.get(practice_location.MPS_Location__c).Intake_Status__c == 'Pending')
					{
						Trigger.newMap.get(practice_location.Id).addError('Selected Location is not approved. Cannot be mapped to an address.');
					}
				}
			
				System.debug('lstToUpdate---'+lstToUpdate);
				if(lstToUpdate != null && lstToUpdate.size() > 0)
				{
					update lstToUpdate;
				}
			}else{
				//Active addresses were not found for the Practice Agreement Locations. So we throw error at this point.
				for(GNE_CM_MPS_Practice_Agreement_Location__c pal: Trigger.new){
					//pal.addError(System.Label.There_must_be_at_least_one_active_primary_address_for_each_account);
					pal.addError('Selected address is Inactive. Can not be mapped.');
				}
			}//end if-else on mapAddVod
		}//end isInsert
		
		if(Trigger.isUpdate)
		{
			for(GNE_CM_MPS_Practice_Agreement_Location__c practice_location:Trigger.new)
			{
				if(practice_location.Prescriber_Location_Disabled_gne__c  != trigger.oldmap.get(practice_location.id).Prescriber_Location_Disabled_gne__c)
				{
					if(practice_location.Prescriber_Location_Disabled_gne__c == true)
					{
						if(practice_location.Address__c != null)
						AddressIdUpdateTrue.add(practice_location.Address__c);
					}
					else if(practice_location.Prescriber_Location_Disabled_gne__c == null || practice_location.Prescriber_Location_Disabled_gne__c == false)
					{
						if(practice_location.Address__c != null)
						AddressIdUpdateFalse.add(practice_location.Address__c);
					}
				}
			}
			Map<Id,Address_vod__c> mapAddVodTrue = new Map<Id,Address_vod__c>([Select id,Registered_for_MPS_gne__c from Address_vod__c where id in : AddressIdUpdateTrue]);
			Map<Id,Address_vod__c> mapAddVodFalse = new Map<Id,Address_vod__c>([Select id,Registered_for_MPS_gne__c from Address_vod__c where id in : AddressIdUpdateFalse]);
			List<Address_vod__c> lstAddressToUpdate = new List<Address_vod__c>();
			
			if(mapAddVodTrue != null && mapAddVodTrue.size() > 0)
			{
				for(Id addId :mapAddVodTrue.keySet())
				{
					Address_vod__c AddVod = mapAddVodTrue.get(addId);
					if(AddVod != null)
					{
						AddVod.Registered_for_MPS_gne__c = false;
						lstAddressToUpdate.add(AddVod);
					}
				}
			}
			if(mapAddVodFalse != null && mapAddVodFalse.size() > 0)
			{
				for(Id addId :mapAddVodFalse.keySet())
				{
					Address_vod__c AddVod = mapAddVodFalse.get(addId);
					if(AddVod != null)
					{
						AddVod.Registered_for_MPS_gne__c = true;
						lstAddressToUpdate.add(AddVod);
					}
				}
			}
			if(lstAddressToUpdate != null && lstAddressToUpdate.size() > 0)
			{
				update lstAddressToUpdate;
			}
		}
		//AS Changes
	}
}