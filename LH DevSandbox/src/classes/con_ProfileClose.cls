global with sharing class con_ProfileClose {

    private final Profile__c prf;

    // The extension constructor initializes the private member
    // variable prf by using the getRecord method from the standard
    // controller.
    
    private ApexPages.StandardController stdController; 
    // Declaring stdController so that standard controller save and cancel can be invoked in other methods below. 
    
    public con_ProfileClose (ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.prf = (Profile__c)stdController.getRecord();
    }
     
    
    public PageReference save_and_archive(){    
        // Declare var sobject for Note and set its fields.
        
        if (prf.Date_Closed_Archived__c == null)
        {
            // String eMessage = 'Please enter Date Closed/Archived';
            // ApexPages.addMessages(eMessage);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.error,'Please enter Date Closed/Archived'));
            return null;
        }
        else 
        {
        
            DateTime dCl = prf.Date_Closed_Archived__c;
            String dateStr =  dCl.format('dd/MM/yyyy') ;
       
            Note clNt = new Note();
            clNt.ParentId = prf.Id;    // Get this profile id  
            clNt.Title = 'Closed ' + dateStr + ' by ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            clNt.Body = prf.Closure_Details__c;
            
            try {
                insert clNt;
            }
                catch(Exception e)
            {
                ApexPages.addMessages(e);
            } 
            
        }
      
        
           
        
        try{
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