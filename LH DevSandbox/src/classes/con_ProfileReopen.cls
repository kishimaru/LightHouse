global with sharing class con_ProfileReopen {

    private final Profile__c prf;

    // The extension constructor initializes the private member
    // variable prf by using the getRecord method from the standard
    // controller.
    
    private ApexPages.StandardController stdController; 
    // Declaring stdController so that standard controller save and cancel can be invoked in other methods below. 
    
    public con_ProfileReopen (ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.prf = (Profile__c)stdController.getRecord();
    }
    
    public String ReopenDetails{get; set;}   
    
    public PageReference save_and_archive(){    
        // Declare var sobject for Note and set its fields.        
              
        DateTime d = Date.Today() ;
        String dateStr =  d.format('dd/MM/yyyy') ;
        
        Note opNt = new Note();
        opNt.ParentId = prf.Id;
        opNt.Title = 'Reopened ' + dateStr + ' by ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        opNt.Body = ReopenDetails; 
        
        try {
            insert opNt;
        }
        catch(Exception ep)
        {
            ApexPages.addMessages(ep);
        }       

        
        try{
        // Clear out closed fields and update profile.
            prf.Date_Closed_Archived__c = null;
            prf.Closure_Details__c = null;
            // prf.Reason_for_Closure__c = null;
            update prf; 
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
   
        PageReference returnToProfile = stdController.save();
        returnToProfile.setRedirect(true);
        return returnToProfile;  
    
    }
}