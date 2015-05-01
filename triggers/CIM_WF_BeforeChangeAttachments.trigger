trigger CIM_WF_BeforeChangeAttachments on Attachment (after delete, after update, before delete, before update) {
   // Get the current user's profile name
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    List<Attachment> atts;
    String action='';
    if(Trigger.isDelete){
        atts = Trigger.old;
        action = 'delete';
    }else if(Trigger.isUpdate){
        atts = Trigger.new;
        action = 'update';
    }
   
    if(atts!=null && atts.size()>0){
        for(Attachment a : atts){
            List<CIM_ParameterApproval__c> ompCR = [select id from CIM_ParameterApproval__c where id=:a.ParentId];
            if(ompCR!=null && ompCR.size()>0){
                if (!'System Administrator'.equalsIgnoreCase(prof.Name)&& (a.ownerId!=null && a.ownerid!=UserInfo.getUserId())) {
                    a.addError('You do not have permission to '+action+' this attachment.');
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