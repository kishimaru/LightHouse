@isTest(SeeAllData=true)
public class LH_TEST_Program {
	static testMethod void LH_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Program__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Program__c()
            );
        }
    	Database.upsert(sourceList);
    }
}