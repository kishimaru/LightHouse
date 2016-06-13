public with sharing class attachBillingRequest {

    public attachBillingRequest(ApexPages.StandardController controller) {

    }    

    public PageReference attachBillingRequest() {

    //Get the Service Reporting record Id and name
    Service_Reporting__c srRec = [SELECT id, name FROM Service_Reporting__c WHERE Id = :System.currentPageReference().getParameters().get('id')]; 
  
    //Initialize standard controller for Service Reporting
    ApexPages.StandardController controller = new ApexPages.StandardController(srRec);
    
    // Create PDF from VF page ServiceReport
    PageReference pdf = new PageReference('/apex/ServiceBillingRequest?id=' + srRec.id);

    // Reference the page, pass in a parameter to force PDF
    /* getParameter returns a map of the query string parameters that are included in the page URL (id and the actual id value). The key string contains the name of the parameter, while the value string contains the value of the parameter. Don't know the purpose of the getParameters line.*/
    pdf.getParameters().put('p','p'); 

    /* If set to true, a redirect is performed through a client side redirect. This type of redirect performs an HTTP GET request, and flushes the view state, which uses POST. If set to false, the redirect is a server-side forward that preserves the view state if and only if the target page uses the same controller and contains the proper subset of extensions used by the source page. */
    pdf.setRedirect(true); 

    // Grab the PDF! 
    Blob b =  Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : pdf.getContent(); // Need to do this because testmethod won't work with getContent call.
    
    // Create the attachment
    Attachment a = new Attachment(ParentId = srRec.Id, name=srRec.name +'-'+'ServiceBillingRequest.pdf', body = b);
    // insert the attachment
    insert a; 
       
    // Send the user back to the Service Reporting detail page
    return controller.view(); 
    }
}