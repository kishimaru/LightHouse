public class RecordMaintenance {

    // Other classes using these methods: UOSUpdateRecords (triggered when UOS updated/created/deleted); BatchableUpdateRecords (runs nightly); ConcatAllergy/ConcatEmergContact/ConcatMedTreatment.
    // The approach is: 
    // 1) CheckoutRecords: Attempt to check out the records needing to be updated;
    // 2) Check the results to see if the records were successfully checked out;
    // 3) Update the records that were successfully checked out and queue the records that were locked for editing.
    
    public static Map<Id, Record_Checkout__c> CheckedOutStatus(Set<Id> RecordIds)
    {
        // Looks up RecordCheckouts for RecordIds passed in to see if records are checked out.
        // If no RecordCheckout record exists, creates one with empty username (available).
        // Returns a map of the RecordIds and RecordCheckout record.
        
        Map<Id, Record_Checkout__c> RecIdsCheckedOutStatus = new Map<Id, Record_Checkout__c>();
        
        List<Record_Checkout__c> rcList = new List<Record_Checkout__c>([SELECT Id, RecordID__c, User__c, User_Name__c, Checkout_Timestamp__c, Queue_for_Authorization_update__c, Queue_for_Profile_update__c  
                                               FROM Record_Checkout__c
                                               WHERE RecordID__c IN : RecordIds FOR UPDATE]);
        
        // Loop through list of existing RecordCheckouts to build Map.
        for ( Record_Checkout__c thisRC : rcList ) 
        {
            RecIdsCheckedOutStatus.put(thisRC.RecordID__c, thisRC);
        }
        
        // Loop through RecordIds passed in.
        // If RecordIds not in Map (no RecordCheckout records exist), insert new RecordCheckouts and add to Map.
        for (Id thisId : RecordIds)
        {
            Record_Checkout__c rcTemp = new Record_Checkout__c(RecordID__c = thisId);
            
            // There are some records that have CheckoutRecord records.
            // Check to see if this record is already in map (and add if it's not)
            if (!RecIdsCheckedOutStatus.containsKey(thisId)) 
            {
                insert rcTemp;
                RecIdsCheckedOutStatus.put(thisId, rcTemp);
            }
        }
        
        return RecIdsCheckedOutStatus;
    }
    
    
    public static Map<Id, Record_Checkout__c> CheckoutRecords(Set<Id> RecordIds) 
    {
        
        // Checks status of records passed in.
        // For open or expired records, updates Record Checkout to check them out; otherwise does nothing.
        // At the end, retrieves RecordCheckoutStatus and returns the result: Map of RecordIDs and Record Checkout records.
        // Calling script can check to see if this user is the one who's got the record checked out;
        // If current user does not have record checked out, display message reflecting who is currently editing the record.
		// Note: It is technically possible for RecordCheckout to be null if the upsert operation for creating a new CheckoutRecord failed.
		// On the off-chance this happens (it would be a fluke), it is possible for someone else to come in and checkout the record.
		// The first person would be out of luck.  Likelihood is so small, can probably disregard.
        
        List<Record_Checkout__c> checkoutList = new List<Record_Checkout__c>();
        
        Datetime currentTimestamp = DateTime.now();
        Decimal hoursElapsed;
        Decimal maxHours = 4.0;
        String userid = UserInfo.getUserId();
        
        Record_Checkout__c rc = new Record_Checkout__c();
        
        // Retrieve status of record Ids passed in.
        Map<Id, Record_Checkout__c> statusMap = CheckedOutStatus(RecordIds);
        
        // Loop through keys and then use key to look up RecordCheckout rec.
        // If the status (Record Checkout) is null or not checked out -- or if the timestamp has 'expired', upsert (add or update) the Record Checkout to indicate it's being checked out.
        for(Id key : statusMap.keySet())
        {
            rc = statusMap.get(key);
            System.debug('User: '+rc.User__c);
           
            if (rc.User__c == null) // The existing Record Checkout is open.
            {
                checkoutList.add(new Record_Checkout__c (
                	Id = rc.Id,
                    RecordID__c = key,
                	User__c = userid,
                	Checkout_Timestamp__c = currentTimestamp
                ));
            }
            else if (rc.Checkout_Timestamp__c != null) // The record is checked out; allow someone else to checked it out if the time limit has expired.
            {
                hoursElapsed = decimal.valueof( (currentTimestamp.getTime() - rc.Checkout_Timestamp__c.getTime())/(1000*60*60)); // divide by miliseconds (1000), seconds (60) and minutes (60) to get hours
            	// System.debug('Hrs elapsed for '+ rc.RecordID__c+' : '+hoursElapsed);
                if (hoursElapsed > maxHours)
                {
               	 	// System.debug(rc.RecordID__c+': Max hours elapsed');
                    checkoutList.add(new Record_Checkout__c (
                		Id = rc.Id,
                    	RecordID__c = key,
                		User__c = userid,
                		Checkout_Timestamp__c = currentTimestamp
                	));
                }
            }
        }
        
        if (checkoutList.size() > 0) Database.upsert(checkoutList, false); 
        // False parameter allows for partial processing;
        // If something in the operation fails, the records that were successfully saved won't be rolled back.
        // Check record statuses and return results.
        
    	return CheckedOutStatus(RecordIds);
        
    }

    public static Map<Id, Record_Checkout__c> CheckinRecords(Set<Id> RecordIds) 
    {
        // Checks status of records passed in to make sure the records we're checking back in are checked out by this person.
        // At the end, retrieves RecordCheckoutStatus and returns the result: Map of RecordIDs and Record Checkout records.
        
        List<Record_Checkout__c> checkinList = new List<Record_Checkout__c>();
        
        String userid = UserInfo.getUserId();
        
        Record_Checkout__c rc = new Record_Checkout__c();
        
        // Retrieve status of record Ids passed in.
        Map<Id, Record_Checkout__c> statusMap = CheckedOutStatus(RecordIds);
        
        // Loop through keys and then use key to look up RecordCheckout rec.
        // If the user to whom record is checked out matches this user, clear the user and timestamp to check record back in.
        // Otherwise, don't do anything - user can't check a record in that doesn't have it checked out.
        for(Id key : statusMap.keySet())
        {
            rc = statusMap.get(key);
           
            if (rc.User__c == userid) // The existing Record Checkout is checked out by the right person.
            {
                checkinList.add(new Record_Checkout__c (
                	Id = rc.Id,
                    RecordID__c = key,
                	User__c = null,
                	Checkout_Timestamp__c = null
                ));
            }
            
        }
        
        if (checkinList.size() > 0) Database.upsert(checkinList, false); 
        // False parameter allows for partial processing;
        // If something in the operation fails, the records that were successfully saved won't be rolled back.
        // Check record statuses and return results.
        
    	return CheckedOutStatus(RecordIds);
    }
    
    public static void QueueForProfileUpdate(Set<Id> RecordIds) 
    {
        // Can't be called asynchronously (@future) because it needs to be invokable via batchable class, which doesn't allow asynchronous calls. 
        // queue records for profile updating by marking checkbox in those Record Checkouts.

        // Look up RecordCheckout status to retrieve (and create if needed!!) RecordCheckout records. 
        // Convert map that's returned into List.
        Map<Id, Record_Checkout__c> chMap = CheckedOutStatus(RecordIds);
        List<Record_Checkout__c> rcList = new List<Record_Checkout__c>();
        rcList.addAll(chMap.values());
        
        String sObjName;
        Id thisId;
        
        for(Record_Checkout__c thisRC : rcList)
        {
         	// Retrieve the object name to make sure IDs are Profile records.
            thisId = thisRC.RecordID__c;
            sObjName = thisId.getSObjectType().getDescribe().getName();
            // System.debug('sObjectName: '+sObjName);
            if (sObjName == 'Profile__c') thisRC.Queue_for_Profile_update__c = true;
        }
        
        /* for(Record_Checkout__c checkRC : rcList)
        {
            System.debug(checkRC.RecordID__c + ': ' + checkRC.Queue_for_Profile_update__c);
        }*/
        
        if (rcList.size()>0) update rcList;
        
    }
    
    public static void QueueForAuthorizationUpdate(Set<Id> RecordIds) 
    { 
        // queue records for authorization updating by marking checkbox in those Record Checkouts.

        // Look up RecordCheckout status to retrieve (and create if needed!!) RecordCheckout records. 
        // Convert map that's returned into List.
        Map<Id, Record_Checkout__c> chMap = CheckedOutStatus(RecordIds);
        List<Record_Checkout__c> rcList = new List<Record_Checkout__c>();
        rcList.addAll(chMap.values());
        
        String sObjName;
        Id thisId;
        
        for(Record_Checkout__c thisRC : rcList)
        {
         	// Retrieve the object name to make sure IDs are Authorization records.
            thisId = thisRC.RecordID__c;
            sObjName = thisId.getSObjectType().getDescribe().getName();
            // System.debug('sObjectName: '+sObjName);
            if (sObjName == 'Authorization__c') thisRC.Queue_for_Authorization_update__c = true;
        }
        
        /* for(Record_Checkout__c checkRC : rcList)
        {
            System.debug(checkRC.RecordID__c + ' (auth): ' + checkRC.Queue_for_Authorization_update__c);
        }*/
        
        if (rcList.size()>0) update rcList;
        
    }
    
    public static void QueueForParticipationUpdate(Set<Id> RecordIds) 
    {
        // queue records for participation updating by marking checkbox in those Record Checkouts.

        // Look up RecordCheckout status to retrieve (and create if needed!!) RecordCheckout records. 
        // Convert map that's returned into List.
        Map<Id, Record_Checkout__c> chMap = CheckedOutStatus(RecordIds);
        List<Record_Checkout__c> rcList = new List<Record_Checkout__c>();
        rcList.addAll(chMap.values());
        
        String sObjName;
        Id thisId;
        
        for(Record_Checkout__c thisRC : rcList)
        {
         	// Retrieve the object name to make sure IDs are Participation records.
            thisId = thisRC.RecordID__c;
            sObjName = thisId.getSObjectType().getDescribe().getName();
            // System.debug('sObjectName: '+sObjName);
            if (sObjName == 'Participation__c') thisRC.Queue_for_Participation_update__c = true;
        }
        
        if (rcList.size()>0) update rcList;
        
    }
    
    
    
    public static void ClearUpdateQueue(String objName) 
    {
        List<Record_Checkout__c> queueList = new List<Record_Checkout__c>();
        
        // Wipe out profile update queue checkboxes.
		if (objName == 'Profile')
        {
        	queueList = [SELECT Id, RecordID__c, Queue_for_Participation_update__c, Queue_for_Authorization_update__c, Queue_for_Profile_update__c  
                                               FROM Record_Checkout__c
                                               WHERE Queue_for_Profile_update__c = TRUE FOR UPDATE];            
        }
        else if (objName == 'Authorization')
        {
            queueList = [SELECT Id, RecordID__c, Queue_for_Participation_update__c, Queue_for_Authorization_update__c, Queue_for_Profile_update__c  
                                               FROM Record_Checkout__c
                                               WHERE Queue_for_Authorization_update__c = TRUE FOR UPDATE];  
        }
        else if (objName == 'Participation')
        {
            queueList = [SELECT Id, RecordID__c, Queue_for_Participation_update__c, Queue_for_Authorization_update__c, Queue_for_Profile_update__c  
                                               FROM Record_Checkout__c
                                               WHERE Queue_for_Participation_update__c = TRUE FOR UPDATE];  
        }

        for (Record_Checkout__c rc : queueList)
        {
            if (objName == 'Profile')
            {
                rc.Queue_for_Profile_update__c = FALSE;
            }
            else if (objName == 'Authorization')
            {
                rc.Queue_for_Authorization_update__c = FALSE;
            }
            else if (objName == 'Participation')
            {
                rc.Queue_for_Participation_update__c = FALSE;
            }
        }
                
        if (queueList.size()>0) update queueList;
        
    }
    
}