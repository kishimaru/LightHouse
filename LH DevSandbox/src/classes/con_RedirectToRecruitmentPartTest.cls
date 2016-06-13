@isTest
public class con_RedirectToRecruitmentPartTest {

	public static testmethod void con_RedirectToRecruitmentPartTest() {

    //Insert Account
    Account acct = new Account(Name='TestClassAccount');
    insert acct;
    
    // Retrieve the new Account
    acct = [SELECT Id,Name FROM Account WHERE Id =:acct.Id];
    
    //Insert Contact
    Contact c = new Contact (Account=acct, FirstName='Test', LastName='Contact');
    insert c;
    
    //Insert Profile and Participation
    Profile__c pr = new Profile__c (Contact__c=c.Id, Name=c.Name, Location_Picklist__c='LightHouse Headquarters', Date_of_Intake__c = Date.today());
    insert pr;
    
    Program__c pg = new Program__c (Name = 'TestProgram1', Active__c = true);
    insert pg;
        
    Participation__c part = new Participation__c (Name=pr.Name, Profile__c=pr.Id, Program__c=pg.Id);
    insert part;

    Test.startTest();
    
    ApexPages.StandardController sc = new ApexPages.StandardController(c);
    con_RedirectToRecruitmentPart ec = new con_RedirectToRecruitmentPart(sc);
    
    PageReference FlowPageRef = Page.Contact_CreateRecruitmentPartLaunchFlow;
    Test.setCurrentPage(FlowPageRef);

    ec.getFinishPage();
    
	System.debug('ContactID: '+c.Id);
    System.debug('ProfileID: '+pr.Id);
    System.debug('Finish ID: '+ec.getId()); 

    Test.stopTest();
   
    
	}    
    
}