@isTest
    public class attachBillingRequestTest {

        public static testMethod void testARController() {
            
            //Create test Service Report record
            date mydate = date.parse('12/27/2009');
            date startdate = date.parse('1/1/2010');
            date enddate = date.parse('1/31/2010');
 
            Service_Reporting__c sr = new Service_Reporting__c(Name='MySR', Date_of_Report__c=mydate, Reporting_Period_Start_Date__c=startdate, Reporting_Period_End_Date__c=enddate);
            insert sr;
            System.Debug(sr.Id);

            Test.startTest();
            
            // Set current page to AttachServiceBillingRequest VisualForce page (confirmation page that executes action)
            String pageURLwithID = '/apex/AttachServiceBillingRequest?id=' + sr.Id;
            PageReference pageRef = new PageReference(pageURLwithID);
            System.Debug(pageURLwithID);
            
            Test.setCurrentPage(pageRef);
            
            // Create a new instance of controller extension attachReport
            ApexPages.StandardController conSR = new ApexPages.StandardController(sr);
            attachBillingRequest ext = new attachBillingRequest(conSR);
            
            // Invoke attachReport method
            String detailServiceReportingURL = ext.attachBillingRequest().getUrl();
            
            // Verify that attachment exists
            List<Attachment> attachments=new List<Attachment>();
            attachments = [select id, name from Attachment where parent.id=:sr.id];
            System.assertEquals(1, attachments.size());
            
            Test.stopTest();
        }
    }