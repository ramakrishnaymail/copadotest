trigger EM3_Update_Calendar_Events on Medical_Event_vod__c (after update, before delete) {
    if(trigger.isUpdate){
        List<Medical_Event_vod__c> to_update = new List<Medical_Event_vod__c>();
        
        set<DateTime> start_date_set = new set<Datetime>();
        set<DateTime> end_date_set = new set<datetime>();
        set<String> event_names = new set<String>();
        
        for(integer i=0;i<trigger.size;i++){
            if((trigger.new[i].Start_Date_vod__c != trigger.old[i].Start_Date_vod__c) || (trigger.new[i].name != trigger.old[i].Name)){
                to_update.add(trigger.new[i]);
                
                start_date_set.add(datetime.newInstance(trigger.old[i].Start_date_vod__c.year(), trigger.old[i].Start_date_vod__c.month(),
                trigger.old[i].start_date_vod__c.day()));
                
                end_date_set.add(datetime.newInstance(trigger.old[i].start_date_vod__c.year(), trigger.old[i].start_date_vod__c.month(),
                trigger.old[i].start_date_vod__c.day()));                                
                
                //end_date_set.add(datetime.newInstance(trigger.old[i].end_date_vod__c.year(), trigger.old[i].end_date_vod__c.month(),
                //trigger.old[i].end_date_vod__c.day()));                                
                
                event_names.add(trigger.old[i].Name);
            }
        }               
        
        List<Event_Attendee_vod__c> attendees = [select ID, Account_vod__c, User_vod__c from Event_Attendee_vod__c where Medical_Event_vod__c
        IN :to_update];
        //IN :to_update AND Account_vod__c != null AND User_vod__c = Null AND Contact_vod__c = Null];             
        
        set<ID> accs = new set<ID>();
        set<ID> ac_set = new set<ID>();
        set<ID> users_set = new set<ID>();
        for(Event_Attendee_vod__c attendee: attendees){
        	if(!(attendee.Account_vod__c == null)){
            	accs.add(attendee.account_vod__c);
            	ac_set.add(attendee.account_vod__c);        	
        	}else if (!(attendee.user_vod__c == null)){
        		users_set.add(attendee.User_vod__c);
        	}        	
        }               
        
        //List<Event> events_to_Update = [select ID, Medical_Event_ID__c from Event where WhatID IN :accs AND startDateTime 
        List<Event> events_to_Update = [select ID, Medical_Event_ID__c from Event where WhatID IN :ac_set AND startDateTime
            IN :start_date_set AND EndDateTime IN :end_date_set AND subject IN :event_names];				
        
        //list of events to update for users added as attendees
        List<Event> User_events_to_Update = [select ID, Medical_Event_ID__c from Event where OwnerID IN :users_set AND startDateTime
            IN :start_date_set AND EndDateTime IN :end_date_set AND subject IN :event_names];				
        
        List<event> final_update = new List<Event>();
        
        //Map to hold all accounts mapped to a list of there respective groupID
        Map<ID,List<ID>> accts_to_GroupID_map = EM3_Calendar_util.acc_to_grp(accs);
        
        //Map to hold Accounts to a list of it's related Groups(Territories)
        Map<ID, List<ID>> Accts_to_groups_map = EM3_Calendar_util.acc_to_terr();
        
        //Map to hold Territories to a list of related Users
        Map<ID, List<ID>> Terrty_to_Users_map = EM3_Calendar_util.terr_to_usrs();
        
        set<ID> ownerIDs = new set<ID>();
        
         for(ID cur_acc : accs){
        	if(!(accts_to_GroupID_map.get(cur_acc) == null)){
            	for(ID cur_groupIDS : accts_to_GroupID_map.get(cur_acc)){
            		if(!(accts_to_groups_map.get(cur_acc) == null)){
	            		for(ID cur_groups : accts_to_groups_map.get(cur_acc)){
	            			if(!(terrty_to_users_map.get(cur_groups) == null)){
		            			for(ID cur_user : terrty_to_users_map.get(cur_groups)){
		            				ownerIDs.add(cur_user);
		            				System.debug('GOT HERE');
		            			}
	            			}
	            		}
            		}
            	}
        	}
        }
        
        List<Event> rel_user_events_to_update = [select ID, Medical_Event_ID__c from Event where OwnerId IN :ownerIds AND startDateTime IN :start_date_set
        AND EndDateTime IN :end_date_set  AND subject IN :event_names];                   
        
        for(Medical_Event_vod__c evt : trigger.new){
            for(Event e : events_to_Update){
                if(e.medical_event_id__c == evt.id){
                    e.startDateTime = datetime.newInstance(evt.Start_date_vod__c.year(),evt.Start_date_vod__c.month(),
                    evt.Start_date_vod__c.day());
                    
                    //e.endDateTime = datetime.newInstance(evt.end_date_vod__c.year(), evt.end_date_vod__c.month(),
                    //evt.end_date_vod__c.day());
                    
                    e.endDateTime = datetime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                    evt.start_date_vod__c.day());
                    e.subject = evt.name;
                    final_update.add(e);
                }
            }
            system.debug(User_events_to_update+',Size:'+User_events_to_update.size());
            for(Event ev : User_events_to_Update){            	
            	if(ev.medical_event_id__c == evt.id){
            		system.debug(ev.medical_event_id__c+'=='+evt.id);                    
                    ev.startDateTime = datetime.newInstance(evt.Start_date_vod__c.year(),evt.Start_date_vod__c.month(),
                    evt.Start_date_vod__c.day());
                    
                    //e.endDateTime = datetime.newInstance(evt.end_date_vod__c.year(), evt.end_date_vod__c.month(),
                    //evt.end_date_vod__c.day());
                    
                    ev.endDateTime = datetime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                    evt.start_date_vod__c.day());
                    ev.subject = evt.name;
                    //final_update.add(e);
                }
            }
            
            for(Event eve : rel_user_events_to_update){            	
            	if(eve.medical_event_id__c == evt.id){
            		system.debug(eve.medical_event_id__c+'=='+evt.id);
                    eve.startDateTime = datetime.newInstance(evt.Start_date_vod__c.year(),evt.Start_date_vod__c.month(),
                    evt.Start_date_vod__c.day());
                    
                    //e.endDateTime = datetime.newInstance(evt.end_date_vod__c.year(), evt.end_date_vod__c.month(),
                    //evt.end_date_vod__c.day());
                    
                    eve.endDateTime = datetime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                    evt.start_date_vod__c.day());
                    eve.subject = evt.name;
                    //final_update.add(e);
                }
            }
        }
        
        //aggregate the user_events_to_update and rel_user_events_to_update list into the events_to_update list
        for(Event e : user_events_to_update){
        	events_to_update.add(e);
        }
        for(Event e : rel_user_events_to_update){
        	events_to_update.add(e);
        }
        
        try{        		        		
                update(events_to_update);
            }catch(DmlException e){System.debug(e.getMessage());}
        
    }
    
    if(trigger.isDelete){
        
        set<DateTime> start_date_set = new set<Datetime>();
        set<DateTime> end_date_set = new set<datetime>();
        set<String> event_names = new set<String>();
        set<ID> med_events = new set<ID>();                
        
        for(Medical_Event_vod__c events : trigger.old){
        	        	
            med_events.add(events.id);
            
            start_date_set.add(datetime.newInstance(events.Start_date_vod__c.year(), events.Start_date_vod__c.month(),
            events.start_date_vod__c.day()));
            
            end_date_set.add(datetime.newInstance(events.start_date_vod__c.year(), events.start_date_vod__c.month(),
            events.start_date_vod__c.day()));                        
            
            //end_date_set.add(datetime.newInstance(events.end_date_vod__c.year(), events.end_date_vod__c.month(),
            //events.end_date_vod__c.day()));                        
            
            event_names.add(events.Name);
        }
        
        set<ID> accs = new set<ID>();
        set<ID> ownerIDs = new set<ID>();
        boolean related = false;
        
        List<Event_Attendee_vod__c> attendees = [select ID,Account_vod__c, User_vod__c from Event_Attendee_vod__c where Medical_Event_vod__c IN :med_events];
        for(Event_Attendee_vod__c attend : attendees){
        	if(!(attend.account_vod__c == null)){
            	accs.add(attend.account_vod__c);
            	related = true;
        	}else if(!(attend.User_vod__c == null)){
        		ownerIDs.add(attend.User_vod__c);
        	}        	
        }
        
        List<Event> events_to_delete = [select ID, Medical_Event_ID__c from Event where WhatID IN :accs AND startDateTime 
            IN :start_date_set AND EndDateTime IN :end_date_set AND subject IN :event_names];
        
        
        if(related){
            
	        //Map to hold all accounts mapped to a list of there respective groupID
	        Map<ID,List<ID>> accts_to_GroupID_map = EM3_Calendar_util.acc_to_grp(accs);
	        
	        //Map to hold Accounts to a list of it's related Groups(Territories)
	        Map<ID, List<ID>> Accts_to_groups_map = EM3_Calendar_util.acc_to_terr();
	        
	        //Map to hold Territories to a list of related Users
	        Map<ID, List<ID>> Terrty_to_Users_map = EM3_Calendar_util.terr_to_usrs();	        	        
	        
	        for(ID cur_acc : accs){
            	if(!(accts_to_GroupID_map.get(cur_acc) == null)){
	            	for(ID cur_groupIDS : accts_to_GroupID_map.get(cur_acc)){
	            		if(!(accts_to_groups_map.get(cur_acc) == null)){
		            		for(ID cur_groups : accts_to_groups_map.get(cur_acc)){
		            			if(!(terrty_to_users_map.get(cur_groups) == null)){
			            			for(ID cur_user : terrty_to_users_map.get(cur_groups)){
			            				ownerIDs.add(cur_user);
			            				System.debug('GOT HERE');
			            			}
		            			}
		            		}
	            		}
	            	}
            	}
            }
        }                
        
        List<Event> user_events_to_delete = [select ID from Event where OwnerId IN :ownerIds AND startDateTime IN :start_date_set
        AND EndDateTime IN :end_date_set  AND subject IN :event_names];
                
        for(Event e: user_events_to_delete){
        	events_to_delete.add(e);
        }     		 		            
            
        try{
                delete(attendees);
                //delete(events_to_delete);
                delete(user_events_to_delete);
            }catch(DmlException e){System.debug(e.getMessage());}    
    }
    
}