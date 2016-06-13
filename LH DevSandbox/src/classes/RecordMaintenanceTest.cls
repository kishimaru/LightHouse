@isTest
public with sharing class RecordMaintenanceTest {

    static testmethod void RecordCheckoutTest ()
    {
        String userid = UserInfo.getUserId();
        
        // Create test records
        List<Profile__c> pfs = new List<Profile__c>(InitTestRecords.InitTestProfiles(5));
    	if (pfs.size() > 0) insert pfs;
		Set<Id> pfIds = (new Map<Id,Profile__c>(pfs)).keySet();
        
        List<Authorization__c> auths = new List<Authorization__c>(InitTestRecords.InitTestAuth(4));
        if (auths.size() > 0) insert auths;
        Set<Id> authIds = (new Map<Id,Authorization__c>(auths)).keySet();
        
        List<Participation__c> parts = new List<Participation__c>(InitTestRecords.InitTestPart(5));
    	if (parts.size() > 0) insert parts;
		Set<Id> ptIds = (new Map<Id,Participation__c>(parts)).keySet();
        
        List<Record_Checkout__c> rchList = new List<Record_Checkout__c>();
        for (Profile__c p : pfs)
        {
            rchList.add(new Record_Checkout__c (
                RecordID__c = p.Id, Queue_for_Profile_update__c = true));
        }
        if (rchList.size() > 0) insert rchList;
        
        List<Record_Checkout__c> rcAList = new List<Record_Checkout__c>();
        Integer firstAuth = 1;
        for (Authorization__c a : auths)
        {
            if (firstAuth == 1)
            {
                rcAList.add(new Record_Checkout__c (
                	RecordID__c = a.Id, Queue_for_Authorization_update__c = true));
            }
            firstAuth++;
        }
        if (rcAList.size() > 0) insert rcAList;
        
        Test.startTest();
        
        List<Record_Checkout__c> pCheck = new List<Record_Checkout__c>([SELECT Id FROM Record_Checkout__c WHERE Queue_for_Profile_update__c = True]);
        System.AssertEquals(pfs.size(),pCheck.size());
        
		// Clear out Profile queue
		RecordMaintenance.ClearUpdateQueue('Profile');

		List<Record_Checkout__c> rcProfileQueued = new List<Record_Checkout__c>([SELECT Id FROM Record_Checkout__c WHERE Queue_for_Profile_update__c = True]);
		System.AssertEquals(0, rcProfileQueued.size());        

        // Clear out Authorization queue
		RecordMaintenance.ClearUpdateQueue('Authorization');

		List<Record_Checkout__c> rcAuthQueued = new List<Record_Checkout__c>([SELECT Id FROM Record_Checkout__c WHERE Queue_for_Authorization_update__c = True]);
		System.AssertEquals(0, rcAuthQueued.size()); 
        
        // Look up check-out status of contacts.
        Map<Id, Record_Checkout__c> statusMap = new Map<Id, Record_Checkout__c>(RecordMaintenance.CheckedoutStatus(pfIds));
        
        // We passed in five IDs, so we should now have a Map with five key-value pairs.
        System.AssertEquals(5,statusMap.size());
        
        Record_Checkout__c rc = new Record_Checkout__c();
        Integer counter = 1;
        Set<Id> checkoutId = new Set<Id>();
        
        Map<Id, Record_Checkout__c> checkedoutStatus = new Map<Id, Record_Checkout__c>();
        Record_Checkout__c rcCheckedOut = new Record_Checkout__c();
        
        Map<Id, Record_Checkout__c> checkedoutagainStatus = new Map<Id, Record_Checkout__c>();
        Record_Checkout__c rcCheckOutAgain = new Record_Checkout__c();
        
        Map<Id, Record_Checkout__c> checkinStatus = new Map<Id, Record_Checkout__c>();
        Record_Checkout__c rcCheckIn = new Record_Checkout__c();
        
        for(Id key : statusMap.keySet())
        {
            rc = statusMap.get(key);
            System.debug(rc.RecordID__c);
            if (counter == 1)
            {
                // Check out this first record.
                System.AssertEquals(null, rc.User__c);
                checkoutId.add(key);
                checkedoutStatus = RecordMaintenance.CheckoutRecords(checkoutId);
                rcCheckedOut = checkedoutStatus.get(key);
                System.AssertEquals(userid, rcCheckedOut.User__c);
                
                // Now try to check it out again to test the process of checking time expiration.
                checkedoutagainStatus = RecordMaintenance.CheckoutRecords(checkoutId);
                rcCheckOutAgain = checkedoutagainStatus.get(key);
                System.AssertEquals(userid, rcCheckOutAgain.User__c);
                
                // Finally, check the record back in.
                checkinStatus = RecordMaintenance.CheckinRecords(checkoutId);
                rcCheckIn = checkinStatus.get(key);
                System.AssertEquals(null, rcCheckIn.User__c);
            }
            else
            {
                System.AssertEquals(null, rc.User__c);
            }
            counter++;
        }
        
        // Invoke method to queue for profile update.
        RecordMaintenance.QueueForProfileUpdate(pfIds);
        
        // Invoke method to queue for authorization update.
        RecordMaintenance.QueueForAuthorizationUpdate(authIds);
        
        // Invoke method to queue for authorization update.
        RecordMaintenance.QueueForParticipationUpdate(ptIds);
        
        // Stop test needs to come before assertions;
        // Future methods are only run synchronously at the point when test is stopped.
        Test.StopTest();         
        
        // Look up RecordCheckouts for profile recordsIDs
        List<Record_Checkout__c> rcList = new List<Record_Checkout__c>([SELECT Id, RecordID__c, Queue_for_Profile_update__c 
                                               FROM Record_Checkout__c
                                               WHERE RecordID__c IN : pfIds]);
        
        for (Record_Checkout__c thisRC : rcList)
        {
            System.AssertEquals(true, thisRC.Queue_for_Profile_update__c);
        }
        
        // Look up RecordCheckouts for participation recordsIDs
        List<Record_Checkout__c> rcptList = new List<Record_Checkout__c>([SELECT Id, RecordID__c, Queue_for_Participation_update__c 
                                               FROM Record_Checkout__c
                                               WHERE RecordID__c IN : ptIds]);
        
        for (Record_Checkout__c thisRC : rcptList)
        {
            System.AssertEquals(true, thisRC.Queue_for_Participation_update__c);
        }
        
        // Look up RecordCheckouts for authorization recordsIDs
        List<Record_Checkout__c> rcauthList = new List<Record_Checkout__c>([SELECT Id, RecordID__c, Queue_for_Authorization_update__c 
                                               FROM Record_Checkout__c
                                               WHERE RecordID__c IN : authIds]);
        
        for (Record_Checkout__c thisRC : rcauthList)
        {
            System.AssertEquals(true, thisRC.Queue_for_Authorization_update__c);
        }
        
        
    }

}