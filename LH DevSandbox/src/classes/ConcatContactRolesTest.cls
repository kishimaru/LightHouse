@isTest
public with sharing class ConcatContactRolesTest {
// This tests a trigger on Contact_Role__c that runs on insert, update and delete: ContactRoleConcat.
// Trigger calls ConcatContactRoles class method that updates all the related Contact records with concatenated Contact Role info.     
    
    static testmethod void UpdateContactTest ()
    {
        // Build test records
        List<Contact_Role__c> newCRList = new List<Contact_Role__c>(InitTestRecords.InitTestContactRoles(10, 5));
        Set<Id> ctIds = new Set<Id>();
        for (Contact_Role__c cr : newCRList)
        {
            ctIds.add(cr.Contact__c);
        }
        
        Test.startTest();
        if (newCRList.size() > 0) insert newCRList;
        Test.StopTest();
        ValidateCRs(ctIds, newCRList);
        
    }
    
    static testmethod void UpdateContactWithDeletesTest ()
    {
        // Build test records
        List<Contact_Role__c> newCRList = new List<Contact_Role__c>(InitTestRecords.InitTestContactRoles(10, 5));
        Set<Id> ctIds = new Set<Id>();
        for (Contact_Role__c cr : newCRList)
        {
            ctIds.add(cr.Contact__c);
        }
        
        Test.startTest();
        if (newCRList.size() > 0) insert newCRList;
        delete newCRList;
        Test.StopTest();
        ValidateDeletedCRs(ctIds);
        
    }
    
    static void ValidateCRs(Set<Id> ctIds, List<Contact_Role__c> lsCR)
    {
        List<Contact> testCtList = new List<Contact>([SELECT Name, Relationship_to_LightHouse__c FROM Contact WHERE Id IN : ctIds]);
        system.AssertEquals(50, lsCR.size());
        for (Contact ct : testCtList)
        {
            System.debug('CR list validation inserts:'+ct.Relationship_to_LightHouse__c);
            System.AssertEquals(True, ct.Relationship_to_LightHouse__c.contains('Student'));
        }
    }
    
    static void ValidateDeletedCRs(Set<Id> updatedctIds)
    {
        List<Contact> testCtList = new List<Contact>([SELECT Name, Relationship_to_LightHouse__c FROM Contact WHERE Id IN : updatedctIds]);
        for (Contact ct : testCtList)
        {
            System.debug('CR list validation deletes:' + ct.Relationship_to_LightHouse__c);
            System.AssertEquals(True, ct.Relationship_to_LightHouse__c == null );
        }
    }
    
    
}