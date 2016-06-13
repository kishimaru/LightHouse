public with sharing class UOSUpdateRecords {

    /* OLD CODE COMMENTED OUT
    public static void UpdateAuth (Set<Id> authIds) 
    {
		// Retrieve Authorization records to update
        List<Authorization__c> authList = new List<Authorization__c> (
        [SELECT Id, Units_of_Service_Provided__c,
            (SELECT Id, Billable_Units__c FROM Units_Of_Service__r)
         FROM Authorization__c WHERE Id IN : authIds]); 
                
        List<Authorization__c> authsToUpdate = new List<Authorization__c>();
        
        // Check out Authorization records for editing in RecordCheckout.
        Map<Id, Record_Checkout__c> chAMap = RecordMaintenance.CheckoutRecords(authIds);
        
        Set<Id> authIdsToQueue = new Set<Id>();
        Set<Id> authIdsToCheckIn = new Set<Id>();
        
        String userid = UserInfo.getUserId();
        
        Decimal sumUnits;
        
        // For each Authorization in list, recalculate number of units remaining.
        If (authList.size() > 0) 
        {
			for (Authorization__c thisAuth : authList) {
                // Retrieve RecordCheckout to see if this record is locked for editing.
                Record_Checkout__c rcThisAuth = chAMap.get(thisAuth.Id);
            	sumUnits = 0.0;
            	// System.debug('Num of units of service for this authID: '+thisAuth.Id+': '+thisAuth.Units_of_Service__r.size());
            	if (thisAuth.Units_of_Service__r.size() > 0) {
                	// System.debug('Inside test for summing units of service provided.');
                	// Loop through each child UOS record and sum Billable Units
                	for (Unit_of_Service__c thisUOS : thisAuth.Units_of_Service__r) {
                        if (thisUOS.Billable_Units__c > 0) 
                        {
                        	sumUnits = thisUOS.Billable_Units__c + sumUnits;
                            if ( rcThisAuth.User__c == userid || rcThisAuth.User__c == null)
            				{
            					authsToUpdate.add(thisAuth); 
                                System.debug('authsToUpdate and check in ID: '+thisAuth.Id);
                				authIdsToCheckIn.add(thisAuth.Id);
            				}
            				else
            				{
                                // Record is locked for editing.  Add to queue for batch nightly update.
                				authIdsToQueue.add(thisAuth.Id);
                                System.debug('authIdsToQueue: '+thisAuth.Id);
            				}
                        }
                	}
                }
            }           
            
            if ( authsToUpdate.size() > 0 ) 
            {
                // Update authorizations that we've checked out and then check them back in.
                update authsToUpdate; // ERROR
            	RecordMaintenance.CheckinRecords(authIdsToCheckIn);
        	}
        
        	// Queue locked records for updating during batch update.
        	if ( authIdsToQueue.size() > 0 ) RecordMaintenance.QueueForAuthorizationUpdate(authIdsToQueue);    
        		
    	}
    } */


    public static void UpdateAuth (Set<Id> authIds)
    {
        
        Map<Id, Decimal> sUnitsMap = new Map<Id, Decimal>();
        Decimal sumUnits;
        
        // Use aggregate function to sum Billable Units by Authorization.
        AggregateResult[] sumUnitsByAuth = 
            [SELECT Authorization__c, SUM(Billable_Units__c)sUnits 
             FROM Unit_of_Service__c 
             WHERE Authorization__c IN : authIds
             GROUP BY Authorization__c];
        
        // Create Map of AuthID and sum of BillableUnits.
        for (AggregateResult sU : sumUnitsByAuth)  {
            // Note: Result of aggregate function is type Object. Need to convert to correct data type.
        	sumUnits = (decimal)sU.get('sUnits');
            Id aId = (Id)sU.get('Authorization__c');
            sUnitsMap.put(aId,sumUnits);
        }
        
        // Retrieve Authorization records to update.
        List<Authorization__c> authList = new List<Authorization__c> (
        		[SELECT Id, Units_of_Service_Provided__c
         		FROM Authorization__c WHERE Id IN : authIds]); 
        
        List<Authorization__c> authsToUpdate = new List<Authorization__c>();

        // Check out Authorization records for editing in RecordCheckout.
        Map<Id, Record_Checkout__c> chAMap = RecordMaintenance.CheckoutRecords(authIds);
        
        Set<Id> authIdsToQueue = new Set<Id>();
        Set<Id> authIdsToCheckIn = new Set<Id>();
        
        String userid = UserInfo.getUserId();
        
        for (Authorization__c thisAuth : authList) {
        	// Retrieve RecordCheckout to see if this record is locked for editing.
        	Record_Checkout__c rcThisAuth = chAMap.get(thisAuth.Id);
            
            // Set UnitsProvided with aggregated sum of billable units.
            thisAuth.Units_of_Service_Provided__c = sUnitsMap.get(thisAuth.Id);

            if ( rcThisAuth.User__c == userid || rcThisAuth.User__c == null)
            {
            	// Record successfully checked out for updating.
                authsToUpdate.add(thisAuth); 
                authIdsToCheckIn.add(thisAuth.Id);
            }
            else
            {
                // Record locked for editing.  Add to queue to update during nightly batch.
                authIdsToQueue.add(thisAuth.Id);
            }

        }

        if ( authsToUpdate.size() > 0 ) 
        {
            // Update Authorizations that we've checked out and then check them back in.
            update authsToUpdate;
            RecordMaintenance.CheckinRecords(authIdsToCheckIn);
        }
        
        // Queue locked records for updating during batch update.
        if ( authIdsToQueue.size() > 0 ) RecordMaintenance.QueueForAuthorizationUpdate(authIdsToQueue);  
        
    }

    
    
	public static void UpdateProfile (Set<Id> profIds) 
	{
		// Retrieve Profile records to update.
		// Updates First/Last Service Dates AND Name (in the case of batch updating).
		// The weakness here is that the subquery depends on the Units of Service having a direct link to the Profile.
		// (And we're trying to address cases where the Profile might be blank via a workflow - 
		// not sure of the ordering in which things fire.)

        System.debug('Inside UpdateProfile method');
        
        Map<Id, Date> firstSerDateMap = new Map<Id, Date>();
        Map<Id, Date> lastSerDateMap = new Map<Id, Date>();
        
        Date firstSerDate;
        Date lastSerDate;
        
        // Use Aggregate Function to get the first and last service dates by Profile.
        AggregateResult[] serDatesByProf = 
            [SELECT Profile__c, MAX(Service_Date__c)lD, MIN(Service_Date__c)fD 
             FROM Unit_of_Service__c 
             WHERE Canceled__c != True AND Profile__c IN : profIds
             GROUP BY Profile__c];
        
        System.debug('right after aggregate function');
        
        for (AggregateResult arP : serDatesByProf)  {
            // Create maps of ProfileID to first date/last date.
            // Note: Result of aggregate function is type Object. Need to convert to correct data type.
            System.debug('Inside aggregate for loop');
        	firstSerDate = (date)arP.get('fD');
            lastSerDate = (date)arP.get('lD');
            Id profId = (Id)arP.get('Profile__c');

            firstSerDateMap.put(profId,firstSerDate);
            lastSerDateMap.put(profId,lastSerDate);
            
            System.debug('Min date: '+arP.get('fD'));
            System.debug('Max date: '+arP.get('lD'));

        }
        
		// Declare list of Profiles to update.
        List<Profile__c> profToUpdate = new List<Profile__c>();
        
        // Retrieve Profiles to update.
        List<Profile__c> profList = new List<Profile__c> (
        [SELECT Id, Name, Contact__r.Name_with_nickname__c, Date_of_First_Service__c, Date_of_Last_Service__c
         FROM Profile__c WHERE Id IN : profIds]); 
        
        // Check out Profile records for editing in RecordCheckout.
        Set<Id> pfIds = (new Map<Id,Profile__c>(profList)).keySet();
        Map<Id, Record_Checkout__c> chPrMap = RecordMaintenance.CheckoutRecords(pfIds);
        
        Set<Id> prIdsToQueue = new Set<Id>();
        Set<Id> prIdsToCheckIn = new Set<Id>();
        
        String userid = UserInfo.getUserId();
                
        for (Profile__c thisProf : profList) {
            Record_Checkout__c rcThisProf = chPrMap.get(thisProf.Id);
            System.Debug('Inside prof loop');
        	// For each Profile in list, look up first and last service dates in Map.            
            thisProf.Date_of_First_Service__c = firstSerDateMap.get(thisProf.Id);
            thisProf.Date_of_Last_Service__c = lastSerDateMap.get(thisProf.Id);
            thisProf.Name = thisProf.Contact__r.Name_with_nickname__c;
            if ( rcThisProf.User__c == userid || rcThisProf.User__c == null)
            {
            	profToUpdate.add(thisProf); 
                prIdsToCheckIn.add(thisProf.Id);
            }
            else
            {
                prIdsToQueue.add(thisProf.Id);
            }

        }

        if ( profToUpdate.size() > 0 ) 
        {
            // Update profiles that we've checked out and then check them back in.
            update profToUpdate;
            RecordMaintenance.CheckinRecords(prIdsToCheckIn);
        }
        
        // Queue locked records for updating during batch update.
        if ( prIdsToQueue.size() > 0 ) RecordMaintenance.QueueForProfileUpdate(prIdsToQueue);    
        
    }
    
    public static void UpdateParticipation (Set<Id> partIds) 
    {
        // Retrieve Participation records to update
        List<Participation__c> ptList = new List<Participation__c> (
        [SELECT Id, Name, Profile__r.Name, Program__r.Short_Name__c, Date_Closed__c
         FROM Participation__c WHERE Id IN : partIds]); 
                
        List<Participation__c> ptToUpdate = new List<Participation__c>();
        
        // Check out Participation records for editing in RecordCheckout.
        Set<Id> ptIds = (new Map<Id,Participation__c>(ptList)).keySet();
        Map<Id, Record_Checkout__c> chPtMap = RecordMaintenance.CheckoutRecords(ptIds);
        
        Set<Id> ptIdsToQueue = new Set<Id>();
        Set<Id> ptIdsToCheckIn = new Set<Id>();
        
        String userid = UserInfo.getUserId();
        
        // For each Participation in list, update its name.
        If (ptList.size() > 0) 
        {
			for (Participation__c thisPt : ptList) {
                Record_Checkout__c rcThisPt = chPtMap.get(thisPt.Id);
				// Update name
				String cl = (thisPt.Date_Closed__c != null) ? ' (Closed)' : '';
    	        thisPt.Name = thisPt.Profile__r.Name + ' - ' + thisPt.Program__r.Short_Name__c + cl;
            	if ( rcThisPt.User__c == userid || rcThisPt.User__c == null)
            	{
            		ptToUpdate.add(thisPt); 
                	ptIdsToCheckIn.add(thisPt.Id);
            	}
            	else
            	{
                	ptIdsToQueue.add(thisPt.Id);
            	}
            }
        
            if ( ptToUpdate.size() > 0 ) 
        	{
            	// Update participations that we've checked out and then check them back in.
            	update ptToUpdate;
            	RecordMaintenance.CheckinRecords(ptIdsToCheckIn);
        	}
        
        	// Queue locked records for updating during batch update.
        	if ( ptIdsToQueue.size() > 0 ) RecordMaintenance.QueueForParticipationUpdate(ptIdsToQueue);
        }
    }
    
        
    
}