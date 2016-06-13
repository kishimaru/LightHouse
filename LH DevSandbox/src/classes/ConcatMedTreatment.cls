public with sharing class ConcatMedTreatment {
    
    public static void UpdateProfileMT (Set<Id> prIds)
	{

		// Retrieve Profiles to update
		List<Profile__c> prList = new List<Profile__c> (
		[SELECT Id, Medications_Abbreviated__c,
         	(SELECT Indications__c, Type__c, Dosage_and_Side_Effects__c, Comments__c, Name FROM Medications_Treatments__r)
         FROM Profile__c WHERE Id IN : prIds]); 

		String concatTxt;
		String type;
		String ind;
        String dose;
		String cmts;
		List<Profile__c> prToUpdate = new List<Profile__c>();
        
        // Check out Profiles in RecordCheckout for editing.
        Map<Id, Record_Checkout__c> chPrMap = RecordMaintenance.CheckoutRecords(prIds);
        
        Set<Id> prIdsToQueue = new Set<Id>();
        Set<Id> prIdsToCheckIn = new Set<Id>();
        String userid = UserInfo.getUserId();
	
		// For each profile in profile list concatenate medications for that profile (using child relationship name: Medications_Treatments__r).
	
		for (Profile__c thisPR : prList) {
            if (thisPR.Medications_Treatments__r.size() > 0) {
				for (Medication_Treatment__c thisMT : thisPR.Medications_Treatments__r) {
                    if (thisMT.Id != null) {
						type = ( thisMT.Type__c != null ) ? ' (' + thisMT.Type__c + ')' : '';
                    	ind = ( thisMT.Indications__c != null ) ? ' Indications: ' + thisMT.Indications__c + ';' : '';
                        dose = ( thisMT.Dosage_and_Side_Effects__c != null ) ? ' Dosage/side-effects: ' + thisMT.Dosage_and_Side_Effects__c.trim() + ';' : '';
            			cmts = ( thisMT.Comments__c != null ) ? ' Comments: ' + thisMT.Comments__c.trim() : '';
            			concatTxt = ((concatTxt == null) ? '' : concatTxt + '\r\n' ) + thisMT.Name.trim() + ' - ' + type + ind + dose + cmts;
                        // Reset variables
                        ind = '';
                        dose = '';
                        type = '';
                        cmts = '';
                    }
            	}
            } else {
                concatTxt = '';
            }
            String txt = concatTxt;
            String txtCleaned = txt.stripHtmlTags();
            Integer len = txtCleaned.length();   
            String concatExcerpt = (len > 255) ? txtCleaned.subString(0,252)+'...' : txtCleaned; 
            thisPR.Medications_Abbreviated__c = concatExcerpt.trim();

            // Retrieve RecordCheckout to see if this record is locked for editing.
        	Record_Checkout__c rcThisProf = chPrMap.get(thisPR.Id);
            
            if ( rcThisProf.User__c == userid || rcThisProf.User__c == null)
            {
            	// Record successfully checked out for updating.
            	prToUpdate.add (thisPR);
                prIdsToCheckIn.add(thisPR.Id);
            }
            else
            {
                // Record locked for editing.  Add to queue to update during nightly batch.
                prIdsToQueue.add(thisPR.Id);
            }

            concatTxt = ''; // reset!
		}
	
        if (prToUpdate.size() > 0)
    	{

        	// Update Profiles that we've checked out and then check them back in.
        	update prToUpdate;
        	RecordMaintenance.CheckinRecords(prIdsToCheckIn);
    	}
        
		// Queue locked records for updating during batch update.
    	if ( prIdsToQueue.size() > 0 ) RecordMaintenance.QueueForProfileUpdate(prIdsToQueue);  
    
    } 

}