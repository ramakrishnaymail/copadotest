trigger GNE_CM_Close_Case_Trigger on Case (before update) 
{
    private static final String PAE_LIVE_SUBJECT = 'Reported Potential Adverse Event - Live';
    private static final String PAE_VM_SUBJECT = 'Reported Potential Adverse Event - VM';
    private static final String PAE_REMINDER_SUBJECT = 'Reminder to Report Potential Adverse Event';

    if (GNE_CM_MPS_TransferWizard.isDisabledTrigger)
    {
        return;
    }
    
    private static Set<ID> getWhatIds(List<Task> tasks, String status)
    {
        Set<ID> result = new Set<ID>();
        
        for(Task task : tasks)
        {
            if(task.Status == status)
            {
                result.add(task.WhatId);               
            }
        }
        return result;
    }
    
    private static List<Task> getTaskIds(List<Task> tasks, String status)
    {
        List<Task> result2 = new List<Task>();
        
        for (Task task2 : tasks)
        {
            if(task2.Status == status)
            {
                result2.add(task2);               
            }
        }
        return result2;
    }
    
    List<Case> casesToRun = new List<Case>();
    
    for (Case c : Trigger.new)
    {
        if (c.Status != Trigger.oldMap.get(c.ID).Status)
        {
            casesToRun.add(c);
        }
    }
    
    System.debug('casesToRun = '+ casesToRun);
    
    if (!casesToRun.isEmpty())
    {
        List<ID> casesWithClosedStatus = new List<ID>();
        for(Case caze : casesToRun)
        {
            if(caze.Status != null && (caze.Status.contains('Closed. Adverse Reaction') || caze.Status.contains('Closed. Patient Deceased')) 
                && !Trigger.oldMap.get(caze.ID).Status.contains('Closed'))
            {
                casesWithClosedStatus.add(caze.ID);
            }
        }
        
        List<ID> casesWithAnyOtherClosedStatus = new List<ID>();
        for(Case caze : casesToRun){
            if(caze.Status != null && (!caze.Status.contains('Closed. Adverse Reaction') && !caze.Status.contains('Closed. Patient Deceased')) 
            && !Trigger.oldMap.get(caze.ID).Status.contains('Closed')){
                casesWithAnyOtherClosedStatus.add(caze.ID);
            }
        }
        
        if(casesWithClosedStatus.size() > 0){
            Map<ID, Case> casesPatients = new Map<ID, Case>([SELECT Patient_gne__r.pat_patient_deceased_gne__c FROM Case WHERE ID in :casesWithClosedStatus AND Patient_gne__c != null]);
            List<ID> patientsIds = new List<ID>();
            for(ID cazeId : casesPatients.keySet()){
                patientsIds.add(casesPatients.get(cazeId).Patient_gne__c);
            }

            Set<Id> patientsWithCompletePAETask = new Set<Id>();
            Set<Id> patientsWithoutNecessaryPAETask = new Set<Id>();

            for (Task task : [SELECT WhatId, Subject, Status FROM Task WHERE WhatId in :patientsIds AND Status = 'Completed'
                                AND (Subject = :PAE_LIVE_SUBJECT OR Subject = :PAE_VM_SUBJECT
                                OR (Subject = :PAE_REMINDER_SUBJECT AND (Anticipated_Next_Step_gne__c = 'Patient did not start therapy' OR Anticipated_Next_Step_gne__c = 'Potential Adverse Event in Document Viewer')))])
            {
                if (task.Subject == PAE_VM_SUBJECT || task.Subject == PAE_LIVE_SUBJECT)
                {
                    patientsWithCompletePAETask.add(task.WhatId);
                }
                else if (task.Subject == PAE_REMINDER_SUBJECT)
                {
                    patientsWithoutNecessaryPAETask.add(task.WhatId);
                }
            }

            /*List<Task> tasksReportedOnPatient = [SELECT WhatId, Subject, Status FROM Task WHERE WhatId in :patientsIds 
                AND (Subject = 'Reported Potential Adverse Event - Live' OR Subject = 'Reported Potential Adverse Event - VM')];
            Set<ID> notStartedTasks = getWhatIds(tasksReportedOnPatient, 'Not Started');
            List<Task> notStartedTaskCount = getTaskIds(tasksReportedOnPatient, 'Not Started');
            Integer openTasksCount = tasksReportedOnPatient.size() - notStartedTaskCount.size() - getTaskIds(tasksReportedOnPatient, 'Completed').size();*/
       
            for (ID cazeId : casesWithClosedStatus)
            {
                // A case cannot be closed when:
                // - there are no tasks on patient with subject 'Reported Potential Adverse Event - Live' or 'Reported Potential Adverse Event - VM'
                // - there are such tasks but their status is not "Completed"
                Id patientId = casesPatients.get(cazeId).Patient_gne__c;
                if (!patientsWithCompletePAETask.contains(patientId) && !patientsWithoutNecessaryPAETask.contains(patientId))
                {
                    Trigger.newMap.get(cazeId).addError('Case cannot be closed. Please complete a Potential Adverse Event Reported activity on patient screen prior to closing the case');
                } 
            }
        }
        
        if(casesWithAnyOtherClosedStatus.size() > 0){
            Map<ID, Case> casesAnyPatients = new Map<ID, Case>([SELECT Patient_gne__r.pat_patient_deceased_gne__c FROM Case WHERE ID in :casesWithAnyOtherClosedStatus AND Patient_gne__c != null]);
            List<ID> patientsIds = new List<ID>();
            for(ID cazeId : casesAnyPatients.keySet()){
                patientsIds.add(casesAnyPatients.get(cazeId).Patient_gne__c);
            }
            List<Task> tasksReportedOnPatient = [SELECT WhatId, Subject, Status FROM Task WHERE whatId in :patientsIds 
                AND (Subject = 'Reported Potential Adverse Event - Live' OR Subject = 'Reported Potential Adverse Event - VM')];
            Set<ID> notStartedTasks = getWhatIds(tasksReportedOnPatient, 'Not Started');
            List<Task> notStartedTaskCount = getTaskIds(tasksReportedOnPatient, 'Not Started');
            //Integer openTasksCount = tasksReportedOnPatient.size() - notStartedTasks.size() - getWhatIds(tasksReportedOnPatient, 'Completed').size();
            Integer openTasksCount = tasksReportedOnPatient.size() - notStartedTaskCount.size() - getTaskIds(tasksReportedOnPatient, 'Completed').size();
          
            for(ID cazeId : casesWithAnyOtherClosedStatus){
                if(casesAnyPatients.get(cazeId).Patient_gne__r.pat_patient_deceased_gne__c == 'Yes'){
                    if(tasksReportedOnPatient.size() == 0 || notStartedTasks.contains(casesAnyPatients.get(cazeId).Patient_gne__c) || openTasksCount > 0){ 
                        Trigger.newMap.get(cazeId).addError('Case cannot be closed. Please complete a Potential Adverse Event Reported activity on patient screen prior to closing the case');
                    }            
                 }           
            }
        }
    }
}