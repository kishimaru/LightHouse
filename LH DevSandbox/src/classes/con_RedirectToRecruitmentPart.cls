public class con_RedirectToRecruitmentPart {

    private final Contact ct;

    // The extension constructor initializes the private member
    // variable prf by using the getRecord method from the standard
    // controller.
    
    private ApexPages.StandardController stdController; 
    // Declaring stdController so that standard controller save and cancel can be invoked in other methods below. 
    
    public con_RedirectToRecruitmentPart (ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.ct = (Contact)stdController.getRecord();
    }
    
public Flow.Interview.Contact_NewRecruitmentParticipation aFlow {get; set;}

    public String getID() {
        if (aFlow==null) return '';
        else if (aFlow.var_NewRecruitmentID!=null) return aFlow.var_NewRecruitmentID;
        else if (aFlow.sobj_ExistingProfile!=null) return aFlow.sobj_ExistingProfile.Id;
        else return ct.Id;
    }

    public PageReference getFinishPage(){
        PageReference p = new PageReference('/' + getID() );
        p.setRedirect(true);
        return p;
    }

}