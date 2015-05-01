trigger SRW_TradingPartner_Trigger on SRW_Trading_Partner_Profile__c (after insert, after update) {
	
	List<SRW_Trading_Partner_Profile__c> tpsWithEffectiveDate = new List<SRW_Trading_Partner_Profile__c>();
	List<SRW_Trading_Partner_Profile__c> tpsWithoutEffectiveDate = new List<SRW_Trading_Partner_Profile__c>();
	Set<SRW_Trading_Partner_Profile__c> tpsWithUpdatedEffectiveDate = new Set<SRW_Trading_Partner_Profile__c>();	
	
	Map<String, Set<String>> existingMonthsMap = new Map<String, Set<String>>();	

	List<SRW_TP_Data_Months__c> tpDataMonthsToCreate = new List<SRW_TP_Data_Months__c>();
    
    System.debug('--- SRW_TradingPartner_Trigger start');
	if(Trigger.isInsert) {
		for(SRW_Trading_Partner_Profile__c tp : Trigger.New) {
			if(tp.Contract_Effective_Date_gne__c != null)
				tpsWithEffectiveDate.add(tp);
			else 
				tpsWithoutEffectiveDate.add(tp);
		}
	} else if(Trigger.isUpdate) {
		Set<String> tpIds = new Set<String>();
		for(SRW_Trading_Partner_Profile__c tp : Trigger.New) {
			if(tp.Contract_Effective_Date_gne__c != Trigger.oldMap.get(tp.id).Contract_Effective_Date_gne__c) {
				tpsWithUpdatedEffectiveDate.add(tp);
				tpIds.add(tp.Id);
			}
		}
		List<SRW_TP_Data_Months__c> tpDataMonths = [Select Id, Trading_Partner_gne__c, SRW_Data_Month_gne__c from SRW_TP_Data_Months__c where Trading_Partner_gne__c in : tpIds];
		for(SRW_TP_Data_Months__c tpDM : tpDataMonths) {
			if(!existingMonthsMap.containsKey(tpDM.Trading_Partner_gne__c)) {
				existingMonthsMap.put(tpDM.Trading_Partner_gne__c, new Set<String>());
			}
			existingMonthsMap.get(tpDM.Trading_Partner_gne__c).add(tpDm.SRW_Data_Month_gne__c);
		}
		/*	
		List<SRW_Sales_Data_gne__c> sdata = [select Prescriber_Organization_Location_gne__c, Product_gne__c, Quantity_gne__c, Set_Sequence_Number_gne__c, Sweep_Data_Month_gne__c, TP_Data_Month_gne__c, Trading_Partner_gne__c from SRW_Sales_Data_gne__c where Trading_Partner_gne__c in : tpIds];		
		for(SRW_Sales_Data_gne__c sd : sdata) {
			tpIds.remove(sd.Trading_Partner_gne__c);
		}
		for(SRW_Trading_Partner_Profile__c tp : tpsWithUpdatedEffectiveDate) {
			if(!tpIds.contains(tp.Id)) {
				tpsWithUpdatedEffectiveDate.remove(tp);
				if(Trigger.isBefore) {
					tp.Contract_Effective_Date_gne__c = Trigger.oldMap.get(tp.Id).Contract_Effective_Date_gne__c;
					tp.addError('Sale was already reported. Contract Effective Date cannot be updated.');
				}
			}	
		}
		if(Trigger.isAfter) {
			List<SRW_TP_Data_Months__c> tpDataMonthsToDelete = [Select Id, Trading_Partner_gne__c from SRW_TP_Data_Months__c where Trading_Partner_gne__c in : tpIds];
			System.debug('--- tpDataMonthsToDelete ' + tpDataMonthsToDelete);
			delete tpDataMonthsToDelete;
		} */
	}

	List<SRW_DataMonths__c> dataMonths = [select Data_Month_Cal_gne__c, Data_Month_gne__c, Data_Year_gne__c, Data_Month_Number_gne__c , Last_Sweep_Occurrence_Date_gne__c, Real_Sweep_Date_gne__c, Sweep_Custom_Date_gne__c, Sweep_Default_Date_gne__c, Sweep_Status_gne__c from SRW_DataMonths__c order by Sweep_Default_Date_gne__c desc];  
	SRW_DataMonths__c currentDataMonth;
	for(SRW_DataMonths__c dm : dataMonths) {
		if('Current'.equals(dm.Sweep_Status_gne__c)) {
			currentDataMonth = dm;
			break;
		}
	}
	System.debug('--- currentDataMonth ' + currentDataMonth);
	Date td = Date.today();
	String year = td.month() == 1 ? String.valueOf(td.year() - 1) : String.valueOf(td.year());
	String month = td.month() == 1 ? '12' : String.valueOf(td.month() - 1);
	if(currentDataMonth == null) {
		for(SRW_DataMonths__c dm : dataMonths) {
			if(dm.Data_Year_gne__c.equals(year) && String.valueOf(dm.Data_Month_Number_gne__c) == month) {
				currentDataMonth = dm;
				break;
			}

		}
	}
		
	if(currentDataMonth != null) {
		for(SRW_Trading_Partner_Profile__c tp : tpsWithoutEffectiveDate) {
			tpDataMonthsToCreate.add(new SRW_TP_Data_Months__c(SRW_Data_Month_gne__c = currentDataMonth.Id, Trading_Partner_gne__c = tp.Id, Data_Month_Status_gne__c = 'Open'));
		}
	}
	List<SRW_TP_Data_Months__c> tmpDataMonts;
	tpsWithEffectiveDate.addAll(tpsWithUpdatedEffectiveDate);
	for(SRW_Trading_Partner_Profile__c tp : tpsWithEffectiveDate) {
		tmpDataMonts = new List<SRW_TP_Data_Months__c>();
		for(SRW_DataMonths__c dm : dataMonths) {
			if(dm.Sweep_Default_Date_gne__c != null 
					&& dm.Sweep_Default_Date_gne__c > tp.Contract_Effective_Date_gne__c
					&& (dm.Sweep_Default_Date_gne__c.year() > tp.Contract_Effective_Date_gne__c.year() 
						|| (dm.Sweep_Default_Date_gne__c.year() == tp.Contract_Effective_Date_gne__c.year() && dm.Sweep_Default_Date_gne__c.month() > tp.Contract_Effective_Date_gne__c.month())
					)) {
				if(!existingMonthsMap.containsKey(tp.Id) || !existingMonthsMap.get(tp.Id).contains(dm.Id))
					tmpDataMonts.add(new SRW_TP_Data_Months__c(SRW_Data_Month_gne__c = dm.Id, Trading_Partner_gne__c = tp.Id, Data_Month_Status_gne__c = 'Open'));
			} else break;
		}
		//if(tmpDataMonts.size() > 1)
		//	tmpDataMonts.remove(tmpDataMonts.size()-1);

		tpDataMonthsToCreate.addall(tmpDataMonts);
	}
	System.debug('--- tpDataMonthsToCreate ' + tpDataMonthsToCreate);
	insert tpDataMonthsToCreate;
}