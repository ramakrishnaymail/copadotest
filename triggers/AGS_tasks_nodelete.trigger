trigger AGS_tasks_nodelete on Task (before insert,before delete,before update){

    // SFA2 bypass. Please not remove!
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('AGS_tasks_nodelete')) {
        return;
    }

try{
    
        //fetch case action prefix
        Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe() ;
        Schema.SObjectType s = m.get('AGS_Case_Action_gne__c') ;  
         Schema.DescribeSObjectResult r = s.getDescribe() ;  
         String Caseactionprefix = r.getKeyPrefix () ;
         
         //fetch case prefix
         Map<String, Schema.SObjectType> m1 = Schema.getGlobalDescribe() ;
        Schema.SObjectType s1 = m1.get('AGS_Case_gne__c') ;  
         Schema.DescribeSObjectResult r1 = s1.getDescribe() ;  
         String Caseprefix = r1.getKeyPrefix () ;
         
       /* List <AGS_Case_Action_gne__c> tempaction=[Select a.Id from AGS_Case_Action_gne__c a limit 1];
        List <AGS_Case_gne__c> tempcase=[Select a.Id from AGS_Case_gne__c a limit 1];*/
      
        if (trigger.isdelete)
            {    
             for (Task t:trigger.old)
                {
                if(t.whatid<>null && t.status<>null )
                   if ((string.valueof((t.whatid)).substring(0,3)==Caseactionprefix || string.valueof((t.whatid)).substring(0,3)==Caseprefix) &&
                        t.status=='Completed' )
                            t.addError('Activity History related to case or case actions cannot be deleted');
                }
            
              
            }   
        else
             if(trigger.isinsert) 
                 {     
                        Boolean soqlflag=False;
                        for (Task t:trigger.new)
                            {
                                if(t.whatid<>null && t.status<>null && (t.recordtype.name<>'CM Task' || t.recordtype.name<>'MCCO CFT Task'
                                || t.recordtype.name<>'MCCO FRM Task' || t.recordtype.name<>'MCCO PFT Task'))
                                    if (string.valueof((t.whatid)).substring(0,3)==Caseactionprefix
                                        && t.status=='Completed')
                                            soqlflag=True;
                                        
                                                
                            }
                            if (soqlflag==True)
                                {   recordtype trectype=[Select id from recordtype where name='AGS Task'];  
                                    for (Task t:trigger.new)
                                    {
                                        if(t.whatid<>null && t.status<>null &&  (t.recordtype.name<>'CM Task' || t.recordtype.name<>'MCCO CFT Task'
                                || t.recordtype.name<>'MCCO FRM Task' || t.recordtype.name<>'MCCO PFT Task'))
                                            if (string.valueof((t.whatid)).substring(0,3)==Caseactionprefix
                                                && t.status=='Completed')
                                                    t.recordtypeid=trectype.Id;
                                                        
                                                        
                                    }
                                
                                
                                }
                                    
                            
                }  
            else
                  { 
                         for(integer i=0;i<trigger.size;i++)
                        {
                            if(trigger.old[i].whatid<>null && trigger.old[i].status<>null )
                            {
                              system.debug(string.valueof((trigger.old[i].whatid)).substring(0,3));
                              system.debug(trigger.old[i].status);
                              system.debug(Caseprefix);
                               if ((string.valueof((trigger.old[i].whatid)).substring(0,3)==Caseactionprefix || string.valueof((trigger.old[i].whatid)).substring(0,3)==Caseprefix)
                               && trigger.old[i].status=='Completed')
                                   trigger.new[i].adderror('Activity History related to case or case actions cannot be edited');
                            }      
                        }
                   }     
                        
}
catch(Exception e)
{}
}