@isTest
public with sharing class ConcatMedTreatmentTest {
// This tests a trigger on Medication_Treatment__c that runs on insert, update and delete: Medication_Concat.
// Trigger calls ConcatMedTreatment class method that updates all the related Profile records with concatenated Medication/Treatment info.     
    
    static testmethod void UpdateProfileTest ()
    {
        // Build test records
        List<Medication_Treatment__c> newMTList = new List<Medication_Treatment__c>(InitTestRecords.InitTestMedTreatment(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (Medication_Treatment__c mt : newMTList)
        {
            prIds.add(mt.Profile__c);
        }
        
        Test.startTest();
        if (newMTList.size() > 0) insert newMTList;
        Test.StopTest();
        ValidateMTs(prIds, newMTList);
        
    }
    
    static testmethod void UpdateProfileWithDeletesTest ()
    {
        // Build test records
        List<Medication_Treatment__c> newMTList = new List<Medication_Treatment__c>(InitTestRecords.InitTestMedTreatment(10, 5));
        Set<Id> prIds = new Set<Id>();
        for (Medication_Treatment__c mt : newMTList)
        {
            prIds.add(mt.Profile__c);
        }
        
        Test.startTest();
        if (newMTList.size() > 0) insert newMTList;
		delete newMTList;
        Test.StopTest();
        ValidateDeletedMTs(prIds);
        
    }
    
    static void ValidateMTs(Set<Id> pfIds, List<Medication_Treatment__c> lsMT)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Medications_Abbreviated__c FROM Profile__c WHERE Id IN : pfIds]);
        system.AssertEquals(50, lsMT.size());
        for (Profile__c pr : testPrList)
        {
            System.debug('MT list validation inserts:'+pr.Medications_Abbreviated__c);
            System.AssertEquals(True, pr.Medications_Abbreviated__c.contains(pr.Name));
        }
    }
    
    static void ValidateDeletedMTs(Set<Id> updatedpfIds)
    {
        List<Profile__c> testPrList = new List<Profile__c>([SELECT Name, Medications_Abbreviated__c FROM Profile__c WHERE Id IN : updatedpfIds]);
        for (Profile__c pr : testPrList)
        {
            System.debug('MT list validation deletes:' + pr.Medications_Abbreviated__c);
            System.AssertEquals(True, pr.Medications_Abbreviated__c == null );
        }
    }
    
    
}