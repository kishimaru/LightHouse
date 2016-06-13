@isTest
public with sharing class ConcatEmergContactTest {
// This tests a trigger on EmergencyContact__c that runs on insert, update and delete: EmergContact_Concat.
// Trigger calls ConcatEmergContact class method that updates all the related Profile records with concatenated Emergency Contact info.     
    
    static testmethod void UpdateProfileTest ()
    {
        // Build test records
        List<EmergencyContact__c> newECList = new List<EmergencyContact__c>(InitTestRecords.InitTestEmerContacts(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (EmergencyContact__c ec : newECList)
        {
            prIds.add(ec.Profile__c);
        }
        
        Test.startTest();
        if (newECList.size() > 0) insert newECList;
        Test.StopTest();
        ValidateECs(prIds, newECList);
        
    }
    
    static testmethod void UpdateProfileWithDeletesTest ()
    {
        // Build test records
        List<EmergencyContact__c> newECList = new List<EmergencyContact__c>(InitTestRecords.InitTestEmerContacts(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (EmergencyContact__c ec : newECList)
        {
            prIds.add(ec.Profile__c);
        }
        
        Test.startTest();
        if (newECList.size() > 0) insert newECList;
		delete newECList;
        Test.StopTest();
        ValidateDeletedECs(prIds);
        
    }
    
    static void ValidateECs(Set<Id> pfIds, List<EmergencyContact__c> lsEC)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Emergency_Contacts_Abbreviated__c FROM Profile__c WHERE Id IN : pfIds]);
        system.AssertEquals(50, lsEC.size());
        for (Profile__c pr : testPrList)
        {
            System.debug('EC list validation inserts:'+pr.Emergency_Contacts_Abbreviated__c);
            System.AssertEquals(True, pr.Emergency_Contacts_Abbreviated__c.contains(pr.Name));
        }
    }
    
    static void ValidateDeletedECs(Set<Id> updatedpfIds)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Emergency_Contacts_Abbreviated__c FROM Profile__c WHERE Id IN : updatedpfIds]);
        for (Profile__c pr : testPrList)
        {
            System.debug('EC list validation deletes:' + pr.Emergency_Contacts_Abbreviated__c);
            System.AssertEquals(True, pr.Emergency_Contacts_Abbreviated__c == null );
        }
    }
    
    
}