trigger LWO_IMS_Optin_Trigger on LWO_IMS_OptIn__c (before insert, before update, before delete) {
  LWO_IMS_OptIn__c[] opts;
  LWO_IMS_OptIn__c opt;
  
  //disable deletion for CustOp user
  if(Trigger.isDelete){
    opts=Trigger.old;
    if(opts!=null && opts.size()>0)     opt=opts[0];
  
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
    if(!('System Administrator'.equalsIgnoreCase(prof.Name) || 'GNE-SYS-Support'.equalsIgnoreCase(prof.Name) || 'GNE-SFA-InternalUser'.equalsIgnoreCase(prof.Name) )){
        opt.addError('The record here cannot be deleted.  Please use the edit action to make changes to the record.');
    }
    
  }else {
    opts=Trigger.new;
    if(opts!=null && opts.size()>0)     opt=opts[0];
  
    //Autom set FPM email base on the selection for FPM
    LWO_FPM__c fpm=[select name, email__c from LWO_FPM__c where id=:opt.FPM__c limit 1];
    opt.FPMEmail__c = fpm.email__c;
  
    //Autom set external system email base on the selection for external system
    LWO_IMS_Loopup__c ims=[select Opt_In_Email__c, Opt_Out_Email__c from LWO_IMS_Loopup__c where id=:opt.IMS__c];
    if(opt.action__c =='Opt-In')   opt.IMS_Email__c = ims.Opt_In_Email__c;
    else opt.IMS_Email__c =ims.Opt_Out_Email__c;
    
    //set Data Feed Status Timestamp
    opt.action_timestamp__c=System.now();
    
    //set email pending falg for insert and change opt-in/out edit action
    if(Trigger.isInsert){
        opt.Email_Pending__c=true;
    }else if(Trigger.isUpdate && Trigger.old !=null){
        LWO_IMS_OptIn__c old=Trigger.old[0];
        if(opt.action__c!=old.action__c) {
            opt.Email_Pending__c=true;
            opt.Email_body_ready__c = false;
            
            //remove records from the LWO_OptIn_Orders_Lookup__c object if change from opt-in to opt-out
            if(opt.action__c=='Opt-Out' && old.action__c=='Opt-In'){
            	List<LWO_OptIn_Orders_Lookup__c> orders=[select id, External_System_Name__c, Opt_In__c, SAP_Account_ID__c, SAP_Order_Id__c from LWO_OptIn_Orders_Lookup__c 
            												where External_System_Name__c=:opt.External_System__c and SAP_Account_ID__c=:opt.SAP_Account_ID__c];
            	if(orders!=null && orders.size()>0) delete orders;
            }
        }
    }
 
    //Check duplicate opt-In or Opt-Out records when create or update record
    if(Trigger.isInsert) {
        LWO_IMS_OptIn__c[] dup=[select id from LWO_IMS_OptIn__c where UniqueKey__c=:opt.UniqueKey__c];
        if(dup!=null && dup.size()>0) {
            opt.addError('A record for this External System already exists.  This change cannot be saved.');
        }
    }
    
    if(Trigger.isUpdate){
        LWO_IMS_OptIn__c[] dup=[select id from LWO_IMS_OptIn__c where UniqueKey__c=:opt.UniqueKey__c and id!=:opt.id];
        if(dup!=null && dup.size()>0) {
            opt.addError('A record for this External System already exists.  This change cannot be saved.');
        }
                        
    }
    
  }
  

}