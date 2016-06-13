@isTest
public with sharing class ConcatAllergyTest {
// This tests a trigger on Allergy__c that runs on insert, update and delete: Allergy_Concat.
// Trigger calls ConcatAllergy class method that updates all the related Profile records with concatenated Allergy info.     
    
    static testmethod void UpdateProfileTest ()
    {
        // Build test records
        List<Allergy__c> newALList = new List<Allergy__c>(InitTestRecords.InitTestAllergy(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (Allergy__c al : newALList)
        {
            prIds.add(al.Profile__c);
        }
        
        Test.startTest();
        if (newALList.size() > 0) insert newALList;
        Test.StopTest();
        ValidateALs(prIds, newALList);
        
    }
    
    static testmethod void UpdateProfileWithDeletesTest ()
    {
        // Build test records
        List<Allergy__c> newALList = new List<Allergy__c>(InitTestRecords.InitTestAllergy(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (Allergy__c al : newALList)
        {
            prIds.add(al.Profile__c);
        }
        
        Test.startTest();
        if (newALList.size() > 0) insert newALList;
		delete newALList;
        Test.StopTest();
        ValidateDeletedALs(prIds);
        
    }
    
    static void ValidateALs(Set<Id> pfIds, List<Allergy__c> lsAL)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Allergies_Abbreviated__c FROM Profile__c WHERE Id IN : pfIds]);
        system.AssertEquals(50, lsAL.size());
        for (Profile__c pr : testPrList)
        {
            System.debug('AL list validation inserts:'+pr.Allergies_Abbreviated__c);
            System.AssertEquals(True, pr.Allergies_Abbreviated__c.contains(pr.Name));
        }
    }
    
    static void ValidateDeletedALs(Set<Id> updatedpfIds)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Allergies_Abbreviated__c FROM Profile__c WHERE Id IN : updatedpfIds]);
        for (Profile__c pr : testPrList)
        {
            System.debug('AL list validation deletes:' + pr.Allergies_Abbreviated__c);
            System.AssertEquals(True, pr.Allergies_Abbreviated__c == null );
        }
    }
    
    
}