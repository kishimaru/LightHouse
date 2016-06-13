public with sharing class ConcatContactRoles {

    
    public static void UpdateContact (Set<Id> ctIds)
	{

		// Retrieve Contacts to update
		List<Contact> ctList = new List<Contact> (
		[SELECT Id, Relationship_to_LightHouse__c,
         	(SELECT Role__c, Current_or_Former__c FROM Contact_Roles__r)
         FROM Contact WHERE Id IN : ctIds]); 

		String concatTxt;
		String role;

		List<Contact> ctToUpdate = new List<Contact>();
	
		// For each contact in contact list concatenate contact roles for that contact (using child relationship name: Contact_Roles__r.
	
		for (Contact thisCT : ctList) {
            if (thisCT.Contact_Roles__r.size() > 0) {
				for (Contact_Role__c thisCR : thisCT.Contact_Roles__r) {
                    if (thisCR.Id != null) {
						role = ( thisCR.Current_or_Former__c != null ) ? thisCR.Current_or_Former__c + ' ' + thisCR.Role__c.tolowercase(): thisCR.Role__c;
            			concatTxt = ((concatTxt == null) ? '' : concatTxt + '\r\n' ) + role;
                        // Reset variables
                        role = '';
                    }
            	}
            } else {
                concatTxt = '';
            }
			thisCT.Relationship_to_LightHouse__c = concatTxt.trim();
            ctToUpdate.add (thisCT);
            concatTxt = ''; // reset!
		}
	
	if (ctToUpdate.size() > 0) update ctToUpdate;
    
    } 
    
}