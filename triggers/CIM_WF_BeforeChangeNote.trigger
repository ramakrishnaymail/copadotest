trigger CIM_WF_BeforeChangeNote on Note (after delete, after update, before delete, before update) {
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    List<Note> notes;
    String action='';
    if(Trigger.isDelete){
        notes = Trigger.old;
        action = 'delete';
    }else if(Trigger.isUpdate){
        notes = Trigger.new;
        action ='update';
    }
    
    if(notes!=null && notes.size()>0){
        for(Note a : notes){
            List<CIM_ParameterApproval__c> ompCR = [select id from CIM_ParameterApproval__c where id=:a.ParentId];
            if(ompCR!=null && ompCR.size()>0 ){
                if (!'System Administrator'.equalsIgnoreCase(prof.Name)&& (a.ownerId!=null && a.ownerid!=UserInfo.getUserId())) {

                    a.addError('You do not have permission to '+action+' this Note.');
                }
            }else {
            	List<CIM_UserApproval__c> userCR = [select id from CIM_UserApproval__c where id=:a.ParentId];
            	if(userCR!=null && userCR.size()>0){
            		if (!'System Administrator'.equalsIgnoreCase(prof.Name)&& (a.ownerId!=null && a.ownerid!=UserInfo.getUserId())) {
                    	a.addError('You do not have permission to '+action+' this attachment.');
                	}
            	}
            }
        } 
    }
}