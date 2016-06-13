public class InitTestRecords {

    public static List<Contact> InitTestContacts(Integer NumberOfContacts) {
		List<Contact> newcts = new List<Contact>();
        for (Integer x=0; x<NumberOfContacts; x++)
        {
            newcts.add (new Contact (
            	FirstName = 'John' + String.valueOf(x),
            	LastName = 'Smith' + String.valueOf(x)
            ));
        }
        System.debug('new contacts: '+ newcts.size());
        return newcts;
    }
    
    public static List<Contact_Role__c> InitTestContactRoles(Integer NumberOfContacts, Integer NumberOfCRsPerContact)
    {
        List<Contact_Role__c> newcrs = new List<Contact_Role__c>();
        List<Contact> cts = new List<Contact>(InitTestContacts(NumberOfContacts));
        if (cts.size() > 0) insert cts;
        for (Contact c : cts) {
            for(Integer x=0; x< NumberOfCRsPerContact; x++)   
            {
                newcrs.add (new Contact_Role__c (
                	Role__c = 'Student',
                    Contact__c = c.Id
                ));
            }
        }
        return newcrs;
    }
    
    public static List<Profile__c> InitTestProfiles(Integer NumberOfProfiles) {
        date bdate = date.parse('7/9/1977');
        List<Profile__c> newpfs = new List<Profile__c>();
        List<Contact> cts = new List<Contact>(InitTestContacts(NumberOfProfiles));
        if (cts.size() > 0) insert cts;
        for (Contact ct : cts)
        {
            newpfs.add (new Profile__c (
            	Name = ct.LastName,
            	Contact__c=ct.Id,
            	Birthdate__c=bdate,
                EmergencyContactList__c = ''
            ));
        }
        return newpfs;
    }
    
    public static List<EmergencyContact__c> InitTestEmerContacts(Integer NumberOfProfiles, Integer NumberOfECsPerProfile)
    {
        List<EmergencyContact__c> newecs = new List<EmergencyContact__c>();
        List<Profile__c> pfs = new List<Profile__c>(InitTestProfiles(NumberOfProfiles));
        if (pfs.size() > 0) insert pfs;
        for (Profile__c pf : pfs) {
            for(Integer x=0; x< NumberOfECsPerProfile; x++) 
            {
                newecs.add (new EmergencyContact__c (
                	Name = pf.Name +String.valueOf(x),
                    Relationship__c = 'Rel'+String.valueOf(x),
                	Profile__c = pf.Id,
                    PrimaryPhone__c = '5554331212',
                    SecondaryPhone__c = '5514331212',
                    Email__c = 'jsmith'+String.valueOf(x)+'@gmail.com',
                    Comments__c = 'These are the notes for '+String.valueOf(x)
                ));
            }
            System.debug('Creating emergency contacts. ProfileId ='+pf.Id+' '+pf.Name);
        }
        return newecs;
    }
    
    public static List<Medication_Treatment__c> InitTestMedTreatment(Integer NumberOfProfiles, Integer NumberOfMTsPerProfile)
    {
        List<Medication_Treatment__c> newmts = new List<Medication_Treatment__c>();
        List<Profile__c> pfs = new List<Profile__c>(InitTestProfiles(NumberOfProfiles));
        if (pfs.size() > 0) insert pfs;
        for (Profile__c pf : pfs) {
            for(Integer x=0; x< NumberOfMTsPerProfile; x++) 
            {
                newmts.add (new Medication_Treatment__c (
                	Name = 'Medication for ' + pf.Name +String.valueOf(x),
                    Type__c = 'Medication',
                	Profile__c = pf.Id,
                    Indications__c = 'High blood pressure',
                    Dosage_and_Side_Effects__c = '2 tsps',
                    Comments__c = 'These are the notes for '+String.valueOf(x)
                ));
            }
            System.debug('Creating medication treatments. ProfileId ='+pf.Id+' '+pf.Name);
        }
        return newmts;
    }

    public static List<Allergy__c> InitTestAllergy(Integer NumberOfProfiles, Integer NumberOfALsPerProfile)
    {
        List<Allergy__c> newals = new List<Allergy__c>();
        List<Profile__c> pfs = new List<Profile__c>(InitTestProfiles(NumberOfProfiles));
        if (pfs.size() > 0) insert pfs;
        for (Profile__c pf : pfs) {
            for(Integer x=0; x< NumberOfALsPerProfile; x++) 
            {
                newals.add (new Allergy__c (
                	Name = 'Allergy for ' + pf.Name +String.valueOf(x),
                    Type__c = 'Food',
                	Profile__c = pf.Id,
                    Allergic_Reaction_and_Treatment__c = 'hives; treat with epipen',
                    Comments__c = 'These are the notes for '+String.valueOf(x)
                ));
            }
            System.debug('Creating allergies. ProfileId ='+pf.Id+' '+pf.Name);
        }
        return newals;
    }
   
    public static List<Program__c> InitTestProgram() {
        List<Program__c> programs = new List<Program__c>();
        programs.add(new Program__c(
            Name = 'TestProgram1',
            Active__c = true
        ));
        return programs;
    }
    

    
    public static List<Participation__c> InitTestPart(Integer NumberOfProfiles)
    {
        List<Profile__c> pfs = new List<Profile__c>(InitTestProfiles(NumberOfProfiles));
        if (pfs.size() > 0) insert pfs;
        List<Participation__c> newpts = new List<Participation__c>();
        List<Program__c> pg = new List<Program__c>(InitTestProgram());
        if ( pg.size() > 0 ) insert pg;
        for (Profile__c pf : pfs) {
            newpts.add (new Participation__c (
                name = pf.Name+'-'+pg[0],
                Profile__c = pf.Id,
                Program__c = pg[0].Id
            ));
        }
        return newpts;
    }
    
    public static List<Equipment_Inventory__c> InitTestEquipment(Integer NumberOfEquipment)
    {
        List<Equipment_Inventory__c> equip = new List<Equipment_Inventory__c>();
        
        for(Integer x=0; x< NumberOfEquipment; x++) 
        {
        	equip.add(new Equipment_Inventory__c(
            	Name = 'TestEquipment'+x
        	));
        }
        
        return equip;        
    }
        

    public static List<Equipment_Loan_Grant__c> InitTestEqLoanGrant(Integer NumRecs)
    {
        // For simplicity sake, just making one variable for the number of all records: Participants, Equipment and EqLoanGrants
        List<Equipment_Inventory__c> equip = new List<Equipment_Inventory__c>(InitTestEquipment(NumRecs));
        if ( equip.size() > 0 ) insert equip;
        List<Participation__c> pts = new List<Participation__c>(InitTestPart(NumRecs));
        if ( pts.size() > 0 ) insert pts;
        List<Equipment_Loan_Grant__c> eqLGs = new List<Equipment_Loan_Grant__c>();
		Integer remainder;
        
        for ( Participation__c thisPart : pts ) 
        {
			for(Integer x=0; x < NumRecs; x++)
        	{
                remainder = math.mod(x, 2);
                eqLGs.add( new Equipment_Loan_Grant__c(
            		Equipment_Inventory__c = equip[x].Id,
                    Participation__c = thisPart.Id,
                    LoanGranted__c = (remainder == 0) ? 'Granted' : 'On loan' // Switch between Granted and On loan.
            	));
                System.debug(eqLGs);
            }
        }
        
        return eqLGs;    
    }
   
    
    public static List<Authorization__c> InitTestAuth(Integer NumAuths)
    {
        List<Participation__c> pts = new List<Participation__c>(InitTestPart(NumAuths));
        if ( pts.size() > 0 ) insert pts;
                    
        List<Authorization__c> newauths = new List<Authorization__c>();
        
        date authdate = date.parse('2/11/2016');
        date startdate = date.parse('2/1/2016');
        date enddate = date.parse('2/28/2016');
        
        for ( Participation__c thisPart : pts ) 
        {
			newauths.add(new Authorization__c(
            	Name = 'TestAuth'+thisPart.Id,
                Participation__c = thisPart.Id,
                Profile__c = thisPart.Profile__c,
                Authorization_Date__c = authdate,
                Location_Picklist__c = 'LightHouse Headquarters',
                Program__c = thisPart.Program__c,
                Authorization_Service_Start_Date__c = startdate,
                Authorization_Service_End_Date__c = enddate,
                Authorized_Units__c = 1000000
        	));
            
        }
        // System.debug('new auths: '+ newauths.size());
        return newauths;  
        
    }
    
    
    public static List<Unit_of_Service__c> InitTestUOSAuthsAndNoAuths(Integer NumAuths, Integer NumUOSPerAuth)
    { 
        
        List<Authorization__c> auths = new List<Authorization__c>(InitTestAuth(NumAuths));
        if ( auths.size() > 0 ) insert auths;
                    
        List<Unit_of_Service__c> uosrecs = new List<Unit_of_Service__c>();
        
        date servdate = date.parse('2/11/2016');
        Integer remainder;
        Service__c srv = new Service__c (
            Name = 'TestService',
            Active__c = true,
            Program__c = auths[0].Program__c
        );
        insert srv;
        
        Payment_Source__c pymt = new Payment_Source__c(
        	Name = 'Test Payment Source',
            Active__c = true
        );
        
        insert pymt;
        
        for ( Authorization__c thisAuth : auths ) 
        {
			for(Integer x=0; x < NumUOSPerAuth; x++)
        	{
                remainder = math.mod(x, 2);
    			Date servnewdate = servdate.addDays(x); 
                uosrecs.add( new Unit_of_Service__c(
            		Service_Date__c = servnewdate,
                    Participant__c = thisAuth.Participation__c,
                    Profile__c = thisAuth.Profile__c,
                    Authorization__c =(remainder == 0) ? thisAuth.Id : NULL, // Switch between having an auth and not.
            		Service__c = srv.Id,
                    Service_Time__c = 1,
                    Billable_Units__c = .25,
                    Payment_Source__c = pymt.Id
                ));
                // String debugAuth = (remainder == 0) ? thisAuth.Id : NULL;
                // System.debug('Adding UOS Authorization: '+debugAuth);
                //System.debug('unitsofservice Authorization: '+thisAuth.Id);
            }
            
        }
        
        // System.debug('new uos: '+ uosrecs.size());
        return uosrecs;  
        
    }
    
    
    
}