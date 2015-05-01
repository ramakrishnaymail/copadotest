trigger EM3_Attendee_Calendar_Functionality on Event_Attendee_vod__c (before insert, after insert, before delete, after delete) {

    // SFA2 bypass
    if(GNE_SFA2_Util.isAdminMode() || GNE_SFA2_Util.isAdminMode('EM3_Attendee_Calendar_Functionality')) {
        return;
    }
    
        if(trigger.isAfter){
            if(trigger.isDelete){
                for(Event_Attendee_vod__c ea : trigger.old){
                    system.debug('DELETED:'+ea);
                }               
            }
            
            if(trigger.isInsert){                       
                //Set to hold all unique account ids
                set<ID> accountID_set = new set<ID>();
                
                //Set to hold all unique medical events
                set<ID> medEvent_set = new set<ID>();
                
                //Gathers up all account attendees                      
                for(Event_Attendee_vod__c attendee : trigger.new){              
                    medEvent_set.add(attendee.Medical_Event_vod__c);
                    
                    if(!(attendee.Account_vod__c == null) && (attendee.Contact_vod__c == null && attendee.User_vod__c == null)){
                        
                        //add the account to the accountID_set                  
                        accountID_set.add(attendee.Account_vod__c);                             
                    }
                }                                                                                               
                
                //Map to hold all accounts mapped to a list of there respective groupID
                Map<ID,List<ID>> acc_to_GroupID_map = EM3_Calendar_util.acc_to_grp(AccountID_set);
                
                //Map to hold Accounts to a list of it's related Groups(Territories)
                Map<ID, List<ID>> Acc_to_groups_map = EM3_Calendar_util.acc_to_terr();
                
                //Map to hold Territories to a list of related Users
                Map<ID, List<ID>> Terr_to_Users_map = EM3_Calendar_util.terr_to_usrs();
                
                //Set to hold all users related to accounts
                set<ID> rel_users_set = new set<ID>();
                
                //Loops through all list of users who pertain to an account
                for(List<ID> usr : terr_to_users_map.values()){
                    for(ID userID : usr){
                        rel_users_set.add(userID);
                    }                   
                }
                
                List<Event> existing_events = [select ID, WhatID, OwnerID, Medical_Event_ID__c from Event where WhatID IN :medEvent_set AND ownerID IN :rel_users_set];
                system.debug('EXISTING EVENTS:'+existing_events);                                                                          
                
                //gather up all Events and put them into a map 
                set<ID> events = new set<ID>();
                
                Map<ID, List<Event_Attendee_vod__c>> event_to_attendee_map = new Map<ID,List<Event_Attendee_vod__c>>();                     
                
                for(Event_Attendee_vod__c attendee : trigger.new){                                                 
                    events.add(attendee.Medical_Event_vod__c);                      
                    if(!event_to_attendee_map.containsKey(attendee.Medical_Event_vod__c)){
                        event_to_attendee_map.put(attendee.Medical_Event_vod__c, new List<Event_Attendee_vod__c>());
                    }
                
                    event_to_attendee_map.get(attendee.Medical_event_vod__c).add(attendee);                                 
                }
                
                //creates a list of all events related to this trigger
                List<Medical_Event_vod__c> events_list = [select ID, Name, start_date_vod__c, 
                end_date_vod__c, Event_Type_gne__c from Medical_Event_vod__c 
                where ID IN :events];
                
                //This list will hold all event attendees for particular medical events that are Account attendees
                List<Event_Attendee_vod__c> acc_count_list = [select ID, Medical_Event_vod__c from Event_Attendee_vod__c where Medical_Event_vod__c IN :medEvent_set AND Account_Vod__c != null order by Medical_Event_vod__c];
                
                //Map to hold each event to it's count of account attendees
                Map<ID, integer> event_acc_count_map = new Map<ID, integer>();
                
                //Loops through the previously created acc_count_list the outer loop is used to keep track of Medical Events, the second
                //is to count the account attendees
                for(Event_Attendee_vod__c ea : acc_count_list){
                    integer evCount = 0;
                    for(Event_Attendee_vod__c ea2 : acc_count_list){
                        if(ea.Medical_Event_vod__c == ea2.Medical_Event_vod__c ){
                            evCount++;                          
                            event_acc_count_map.put(ea.Medical_Event_vod__c,evCount);                           
                        }
                    }
                }                                                
                            
                List<Event> events_to_insert = new List<Event>();
                List<Event> evts_insert = new List<Event>();                        
                
                //List to hold all queues related to event types                
                List<Group> queueList = new List<Group>([select id from Group where Type='Queue' and (Name = 'Advisory Boards Queue' or Name = 'Investigator Meetings Queue' or Name = 'Speaker Program Queue' or Name = 'Speaker Training Queue') order by Name]);
                
                for(Medical_Event_vod__c evt : events_list){
                    Event event = new Event();                  
                    for(Event_Attendee_vod__c attendee : event_to_attendee_map.get(evt.id)){
                        event = new Event();
                        if(!(attendee.Account_vod__c == null) && (attendee.Role_gne__c.contains('Attendee') || attendee.Role_gne__c.contains('Speaker'))){
                            event.WhatID = attendee.Account_vod__c;
                            event.Medical_Event_ID__c = attendee.Medical_Event_vod__c;
                            event.StartDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                            evt.start_date_vod__c.day());
                            event.EndDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                            evt.start_date_vod__c.day());                                                       
                                                                    
                            event.subject = evt.name;                                                                           
                            events_to_insert.add(event);
                                                            
                            //system.debug('boolean:'+attendee_to_boolean);                                                     
                            List<ID> users = new List<ID>();
                            List<ID> Territories = acc_to_groups_map.get(attendee.Account_vod__c);
                            if(!(Territories == null)){
                                if(Territories.size() > 0){
                                    for(ID terr : Territories){
                                    //added a containsKey statement here for 2645
                                        if(terr_to_users_map.containsKey(terr)){
                                            users = terr_to_users_map.get(terr);
                                        }
                                        if(!(users == null)){
                                            if(users.size() > 0){
                                                for(ID user : users){                                               
                                                    boolean create_event = true;                                                
                                                    
                                                    //Iterate through the existing_events list and look for events with a matching medical
                                                    //event ids + the same user and if one is found then skip the event creation, otherwise 
                                                    //create an event.
                                                    for(Event e : existing_events){                         
                                                        if(e.WhatID == attendee.Medical_Event_vod__c){
                                                            //added a containsKey statement here for 2645
                                                            List<ID> grps = new List<ID>();
                                                            if(Acc_to_groups_map.containsKey(attendee.Account_vod__c)){
                                                                grps = Acc_to_groups_map.get(attendee.Account_vod__c);
                                                            }
                                                            for(ID groups : grps ){
                                                            //added a containsKey statement here for 2645
                                                                if(terr_to_users_map.containsKey(groups)){
                                                                    for(ID usr : terr_to_users_map.get(groups)){    
                                                                        //breaking out of all loops because user was found                                  
                                                                        if(usr == e.OwnerID){                                                                       
                                                                            create_event = false;
                                                                            system.debug('CREATE_EVENT FALSE!:'+usr+','+e.OwnerID);                                                                 
                                                                            break;
                                                                        }                                       
                                                                    }
                                                                }//added for 2645
                                                            }                                                       
                                                        }                           
                                                    }
                                                    
                                                    //If the create event boolean is set to true then create an event for the current user
                                                    //otherwise do nothing
                                                    system.debug('COUNT:'+event_acc_count_map.get(attendee.Medical_Event_vod__c)+',CREATE_EVENT:'+create_event);
                                                    if(create_event && (event_acc_count_map.get(attendee.Medical_Event_vod__c) == 1)){
                                                        system.debug('CREATE_EVENT');
                                                        event = new Event();
                                                        event.OwnerId = user;
                                                        //event.WhatID = user;
                                                        event.WhatID = attendee.Medical_Event_vod__c;
                                                        event.Medical_Event_ID__c = attendee.Medical_Event_vod__c;
                                                        event.StartDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                                                        evt.start_date_vod__c.day());
                                                        event.EndDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                                                        evt.start_date_vod__c.day());                                                                                                                           
                                                        event.subject = evt.name;                                                                       
                                                        events_to_insert.add(event);                                    
                                                    }
                                                }
                                            }                                                      
                                        }                                           
                                    }       
                                }
                            }                       
                        }
                        if(!(attendee.User_vod__c == null)){
                            event.OwnerID = attendee.User_vod__c;
                            event.WhatID = attendee.Medical_Event_vod__c;
                            event.Medical_Event_ID__c = attendee.Medical_Event_vod__c;
                            event.StartDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                            evt.start_date_vod__c.day());
                            event.EndDateTime = dateTime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                            evt.start_date_vod__c.day());                                                                   
                            event.subject = evt.name;
                            
                            events_to_insert.add(event);
                        }                                                                
                    }
                }
                
                try{
                    system.debug('FOR INSERT:'+events_to_insert);                                       
                    insert(events_to_insert);                          
                }catch(DmlException e){System.debug(e.getMessage());}                           
            }
        }
        
        //Checks for dupes before inserting a record
        if(trigger.isBefore){           
            
            //Build a set of relevant fields
            if(trigger.isInsert){
                set<ID> medEvent_set = new set<ID>();
                set<ID> acc_set = new set<ID>();
                set<ID> cont_set = new set<ID>();
                set<ID> user_set = new set<ID>();
                                
                for(Event_Attendee_vod__c ea : trigger.new){
                    medEvent_set.add(ea.Medical_event_vod__c);
                    if(ea.Account_vod__c != null){
                        acc_set.add(ea.Account_vod__c);
                    }else if(ea.Contact_vod__c != null){
                        cont_set.add(ea.Contact_vod__c);
                    }else if(ea.User_vod__c != null){
                        user_set.add(ea.User_vod__c);
                    }                                       
                }                               

                //Retrieve all related Event Attendees, related via the fields corresponding to the sets we just created                                
                List<Event_Attendee_vod__c> existing_attendees = [select ID, Account_vod__c, Contact_vod__c,  User_vod__c, Medical_Event_vod__c from Event_Attendee_vod__c where Medical_Event_vod__c IN :medEvent_set 
                AND (Account_vod__c IN :acc_set OR Contact_vod__c IN :cont_set OR User_vod__c IN :user_set)];                                                           
                
                //check for duplicates and throw an error if found
                for(Event_Attendee_vod__c ea : existing_attendees){
                    for(Event_Attendee_vod__c ea_trigger : trigger.new){
                        if(ea.Medical_event_vod__c == ea_trigger.Medical_event_vod__c && ea.Account_vod__c == ea_trigger.Account_vod__c
                        && ea.contact_vod__c == ea_trigger.contact_vod__c && ea.user_vod__c == ea_trigger.user_vod__c){
                            ea_trigger.addError('Cannot Insert Duplicate Attendees');                           
                        }
                    }
                }
            }
            if(trigger.isDelete){
                system.debug('TRIGGER NEW:'+trigger.new);
                //gather up all Events and put them into a map 
                set<ID> ac_events = new set<ID>();
                
                set<ID> user_events = new set<ID>();
                
                Map<ID, List<Event_Attendee_vod__c>> event_to_attendee_map = new Map<ID,List<Event_Attendee_vod__c>>();
                set<ID> acc_conts = new set<ID>();
                set<ID> accs = new set<ID>();
                set<ID> ownerIDs = new set<ID>();
                set<id> acc_evt = new set<ID>();
                set<ID> deleted_ids = new set<ID>();
                for(Event_Attendee_vod__c attendee : trigger.old){              
                    //this statement makes sure that all attendees added are account attendees
                    if((attendee.Account_vod__c != null || attendee.Contact_vod__c != null) && attendee.User_vod__c == null){
                        if(!(attendee.Account_vod__c == null)){
                            acc_evt.add(attendee.Medical_event_vod__c);
                            accs.add(attendee.Account_vod__c);
                            acc_conts.add(attendee.Account_vod__c);                         
                        }
                        ac_events.add(attendee.Medical_Event_vod__c);                       
                        if(!event_to_attendee_map.containsKey(attendee.Medical_Event_vod__c)){
                            event_to_attendee_map.put(attendee.Medical_Event_vod__c, new List<Event_Attendee_vod__c>());
                        }
                    
                        event_to_attendee_map.get(attendee.Medical_event_vod__c).add(attendee);             
                    }else if(!(attendee.User_vod__c == null) && (attendee.Account_vod__c == null && attendee.Contact_vod__c == null)){
                        //enter code here to remove only user related attendees
                        ac_events.add(attendee.Medical_Event_vod__c);
                        ownerIDs.add(Attendee.User_vod__c);
                    }
                }               
                
                //creates a list of all events related to this trigger
                List<Medical_Event_vod__c> events_list = [select ID, Name, start_date_vod__c, end_date_vod__c from Medical_Event_vod__c 
                where ID IN :ac_events];                                                                                                            
                
                set<DateTime> start_date_set = new set<Datetime>();
                set<DateTime> end_date_set = new set<datetime>();
                set<String> event_names = new set<String>();
                for(Medical_Event_vod__c evt : events_list){
                    start_date_set.add(datetime.newInstance(evt.Start_date_vod__c.year(), evt.Start_date_vod__c.month(),
                    evt.start_date_vod__c.day()));
                    
                    end_date_set.add(datetime.newInstance(evt.start_date_vod__c.year(), evt.start_date_vod__c.month(),
                    evt.start_date_vod__c.day()));                                          
                    
                    event_names.add(evt.Name);
                }
                
                List<Event> events_to_delete = [select ID from Event where WhatID IN :acc_conts AND startDateTime 
                IN :start_date_set AND EndDateTime IN :end_date_set AND subject IN :event_names];                        
                
               /* List<Event> user_att_events_to_delete = [select ID from Event where OwnerId IN :u_set AND startDateTime 
                IN :start_date_set AND EndDateTime IN :end_date_set AND subject IN :event_names];*/
                
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
                System.debug('MAPS:'+accts_to_GroupID_map+'\n'+accts_to_groups_map+'\n'+terrty_to_users_map);
                System.debug('USERS:'+ownerIDs);
                
                List<Event> user_events_to_delete = [select ID from Event where OwnerId IN :ownerIds AND startDateTime IN :start_date_set
                AND EndDateTime IN :end_date_set  AND subject IN :event_names];
                
                for(Event e: user_events_to_delete){
                    events_to_delete.add(e);
                }                               
                  
                try{                    
                    System.debug('to delete[events_to_delete]:'+events_to_delete);                  
                    delete(events_to_delete);                   
                }catch(DmlException e){System.debug(e.getMessage());}
               
            }
        }               
    }