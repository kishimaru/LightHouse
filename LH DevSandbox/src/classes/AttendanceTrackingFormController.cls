public class AttendanceTrackingFormController {
    
    private static String DEFAULT_DELIVERY_OF_SERVICES_PICKLIST_VAL = 'Group';
    Map<Id, String> eventMap;
    public Id workshopId {get; set;}
    public Id classId {get; set;}
    
    // TODO: Make some of them transient if they don't have to be part of view state.
    public List<SelectOption> componentsList {get; private set;}
    public List<UnitOfService> uosList {get; private set;}
    
    public List<DropDownRecord> classParticipants {get; private set;}
    public List<DropDownRecord> programParticipants {get; private set;}
    public List<DropDownRecord> paymentSources {get; private set;}
    public List<User> serviceProviders {get; private set;}
    public Map<Id, List<Authorization__c>> authorizationsMap {get; private set;}
    
    // Added 6/16/2016 KI to fix 1000 max limit on <apex:repeat>
    // Added limitWrapper object and edited populateProgramParticipants method.
    public limitWrapper[] thousandBlocks {get; private set;}
    
    public AttendanceTrackingFormController() {
        
        this.classParticipants = new List<DropDownRecord>();
        this.programParticipants = new List<DropDownRecord>();
        this.authorizationsMap = new Map<Id, List<Authorization__c>>();
        String inWorkshopId = ApexPages.currentPage().getParameters().get('workshopId');
        String inClassId = ApexPages.currentPage().getParameters().get('classId');
        
        if (inWorkshopId != null) {
            this.workshopId = inWorkshopId;
            updateClassComponentsList();
            if (inClassId != null) {
                this.classId = inClassId;
                populatePageForSelectedClassComponent();
            }
        }
        else {
            this.componentsList = new List<SelectOption>();
            this.componentsList.add(new SelectOption('', ''));
        }
    }
    
    
    public List<SelectOption> getWorkshopList() {
        Map<Id, String> workshops = loadAllEvents();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        for (String workshopId: workshops.keySet()) {
            String workshopName = workshops.get(workshopId);
            options.add(new SelectOption(workshopId, workshopName));
        }
        return options;
    }
    public void updateClassComponentsList() {
        Map<Id, String> classComponents = loadClassComponents();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));

        for (String classComponentId: classComponents.keySet()) {
            String className = classComponents.get(classComponentId);
            options.add(new SelectOption(classComponentId, className));
        }
        this.componentsList = options;
        this.classId = null;
    }
    
    public void populatePageForSelectedClassComponent() {
        populateClassParticipants();
        populateProgramParticipants();
        populatePaymentSources();
        populateUnitsOfService();
        populateServiceProviders();
    }
    
    private void populateUnitsOfService() {
        List<Unit_of_Service__c> uosObjectList = AttendanceTrackingFormQueryService.queryUosForClassComponent(this.classId);
        Event_Workshop__c workshop = AttendanceTrackingFormQueryService.queryWorkshop(this.workshopId);
        Class_Component__c classComponent = AttendanceTrackingFormQueryService.queryClassComponent(this.classId);

        this.uosList = new List<UnitOfService>();
        uosList.add(constructSampleUos(classComponent));
        Set<String> participantIdsWithUos = new Set<String>();
        Set<String> populatedParticipantIds = new Set<String>();
        
        for (Unit_Of_Service__c uosObject: uosObjectList) {
            UnitOfService uos = new UnitOfService();
            uos.sample = false;
            uos.serviceProviderId = uosObject.Service_Provider__c;
            uos.ServiceDate = dateToString(uosObject.Service_Date__c);
            uos.ServiceTime = uosObject.Service_Time__c;
            uos.ParticipantName = uosObject.Participant__r.Name;
            uos.ParticipantId = uosObject.Participant__c;
            participantIdsWithUos.add(uosObject.Participant__c);
            populatedParticipantIds.add(uosObject.Participant__c);
            uos.uosId = uosObject.Id;
            uos.numberOfAdditionalPeople = (uosObject.Number_of_Additional_People__c == null ? 0 : Integer.valueOf(uosObject.Number_of_Additional_People__c));
            // KI 5/10/2016: updated from uos.BillableUnits = (uosObject.Billable_Units__c == null ? 0 : Integer.valueOf(uosObject.Billable_Units__c)); to line below
            // Changed uos.BillableUnits from Integer to Decimal.
            uos.BillableUnits = (uosObject.Billable_Units__c == null ? 0 : uosObject.Billable_Units__c);
            uos.TypeOfUnits = uosObject.Type_of_Units__c;
            uos.cancelReason = uosObject.Cancellation_Reason__c;
            uos.paymentSourceId = uosObject.Payment_Source__c;
            uos.AuthorizationId = uosObject.Authorization__c;
            uos.ProgressLessonNotes = (uosObject.Progress_Lesson_Notes__c == null ? '':uosObject.Progress_Lesson_Notes__c.unescapeHtml4());
            this.uosList.add(uos);
        }
        
        for (DropDownRecord participant: classParticipants) {
            if (!participantIdsWithUos.contains(participant.Id)) {
                /**
                 * Add blank unit of service record for class participants with missing
                 * unit of service record.
                **/
                UnitOfService uos = new UnitOfService();
                uos.sample = false;
                
                //KI 4/6/2016 disabled the following line and added the line immediately after to fix ServiceProvider.
                // uos.serviceProviderId = classComponent.Service__c;
                uos.serviceProviderId = classComponent.Service_Provider__c;
                
                // TODO: Is begin date the right dateTime for defaulting? check with Karen.
                uos.ServiceDate = datetimeToString(classComponent.Begin_Datetime__c);
                uos.ServiceTime = classComponent.Hours__c;
                uos.ParticipantName = participant.Name;
                uos.ParticipantId = participant.Id;
                populatedParticipantIds.add(participant.Id);
                uos.uosId = null;
                uos.numberOfAdditionalPeople = 0;
                uos.BillableUnits = 0;
                uos.TypeOfUnits = null;
                uos.cancelReason = null;
                uos.ProgressLessonNotes = null;
                this.uosList.add(uos);
            }
        }
        populateAuthorizationsMap(populatedParticipantIds);
        
    }

    private void populateAuthorizationsMap(Set<String> participantIds) {
        List<Authorization__c> authorizations = AttendanceTrackingFormQueryService.queryAuthorizations(participantIds);
        Map<Id, List<Authorization__c>> authMap = new Map<Id, List<Authorization__c>>();
        for (Authorization__c auth: authorizations) {
            if (!authMap.containsKey(auth.Participation__c)) {
                authMap.put(auth.Participation__c, new List<Authorization__c>());
            }
            authMap.get(auth.Participation__c).add(auth);
        }
        this.authorizationsMap = authMap;
    }
    
    @RemoteAction
    public static List<Map<String, String>> fetchAuthorizations(String participantId) {
        Set<String> participantIds = new Set<String>();
        participantIds.add(participantId);
        List<Authorization__c> authorizations = AttendanceTrackingFormQueryService.queryAuthorizations(participantIds);
        List<Map<String, String>> returnList = new List<Map<String, String>>();
        for (Authorization__c auth: authorizations) {
            Map<String, String> authRecordMap = new Map<String, String>();
            authRecordMap.put('id', auth.Id);
            authRecordMap.put('value', auth.Name);
            returnList.add(authRecordMap);
        }
        return returnList;
    }

    public static String datetimeToString(Datetime d) {
        if (d == null) return '';
        // Use MM/dd/yyyy format.
        return d.month() + '/' + d.day() + '/' + d.year();
    }
    
    
    public static String dateToString(Date d) {
        if (d == null) return '';
        // Use MM/dd/yyyy format.
        return d.month() + '/' + d.day() + '/' + d.year();
    }
    
    private UnitOfService constructSampleUos(Class_Component__c classComponent) {
        UnitOfService uos = new UnitOfService();
        uos.sample = true;
        
        // KI 4/6/2016 disabled following line and added line immediately after
        // uos.serviceProviderId = null;
        uos.serviceProviderId = classComponent.Service_Provider__c;
        
        uos.ServiceDate = datetimeToString(classComponent.Begin_Datetime__c);
        uos.ServiceTime = classComponent.Hours__c;
        uos.ParticipantName = '';
        uos.ParticipantId = null;
        uos.uosId = null;
        uos.numberOfAdditionalPeople = 0;
        uos.BillableUnits = 0;
        uos.TypeOfUnits = null;
        uos.cancelReason = null;
        uos.ProgressLessonNotes = null;
        return uos;
    }
   
    
    /** Commented out 6/16/2016 KI to make edits below.
    private void populateProgramParticipants() {
        this.programParticipants = new List<DropDownRecord>();
        List<Participation__c> participants = AttendanceTrackingFormQueryService.queryProgramParticipants(workshopId);
        for (Participation__c participant: participants) {
            DropDownRecord p = new DropDownRecord(participant.Id, participant.Name);
            this.programParticipants.add(p);
        }
    }**/
    
    
    public class limitWrapper {
    // Inner class
    	public List<DropDownRecord>() participants {get;set;}
    	public integer blockNumber {get;set;}
    	public limitWrapper(List<DropDownRecord>() p, integer i)
    	{
        	participants = p;
        	blockNumber = i;
    	}
	}
    
private void populateProgramParticipants() {
    {
        
        integer listLimit = 1000;
        integer counter = 0;
        integer loopCount = 0;

        this.thousandBlocks = new limitWrapper[]{};
        this.programParticipants = new List<DropDownRecord>();
        
        List<Participation__c> participants = AttendanceTrackingFormQueryService.queryProgramParticipants(workshopId);
        for (Participation__c participant: participants) {
            if(counter < listLimit) // While this iteration is less than the 1000th
            {
                
                DropDownRecord p = new DropDownRecord(participant.Id, participant.Name);
                this.programParticipants.add(p);  // add this participant's id and name to the list of drop-down recs
                counter++;
            }
            else
            {
                loopCount++;
                this.thousandBlocks.add(new limitWrapper(this.programParticipants,loopCount));
                this.programParticipants = new List<DropDownRecord>();
                this.programParticipants.add(p);
                counter = 0;
            }
        }
        
    	if(thousandBlocks.size() == 0 )
    	{
        	loopCount++;
        	this.thousandBlocks.add(new limitWrapper(this.ProgramParticipants,loopCount));
    	}

    }
    
    
    
    
    private void populateClassParticipants() {
        this.classParticipants = new List<DropDownRecord>();
        List<Participation__c> participants = AttendanceTrackingFormQueryService.queryClassParticipants(this.workshopId);
        for (Participation__c participant: participants) {
            DropDownRecord p = new DropDownRecord(participant.Id, participant.Name);
            this.classParticipants.add(p);
        }
    }
    
    private void populatePaymentSources() {
        this.paymentSources = new List<DropDownRecord>();
        List<Payment_Source__c> paymentSourcesList = AttendanceTrackingFormQueryService.queryPaymentSources();
        for (Payment_Source__c paymentSource: paymentSourcesList) {
            DropDownRecord p = new DropDownRecord(paymentSource.Id, paymentSource.Name);
            this.paymentSources.add(p);
        }
    }

    private void populateServiceProviders() {
        this.serviceProviders = AttendanceTrackingFormQueryService.queryServiceProviders();
    }

    
    public Boolean getHasUos() {
        return (this.uosList != null && this.uosList.size() > 0);
    }
    
    public List<String> getCancelReasonPicklistOptions() {
        return readPicklistValues(Unit_of_Service__c.Cancellation_Reason__c.getDescribe());
    }
    
    public List<String> getTypeOfUnitsPicklistOptions() {
        return readPicklistValues(Unit_of_Service__c.Type_of_Units__c.getDescribe());
    }
    
    private List<String> readPicklistValues(Schema.DescribeFieldResult picklistFieldDescribeResult) {
        List<String> values = new List<String>();
        List<Schema.PicklistEntry> picklistValues = picklistFieldDescribeResult.getPicklistValues();
        for( Schema.PicklistEntry f : picklistValues) {
            values.add(f.getValue());
        }  
        return values;
    }
    
    private Map<Id, String> loadAllEvents() {
        // TODO: Make this a type-ahead to avoid getting all workshops?
        List<Event_Workshop__c> events = AttendanceTrackingFormQueryService.queryWorkshops();
        eventMap = new Map<Id, String>();
        for (Event_Workshop__c event: events) {
            eventMap.put(event.Id, event.Name);
        }
        return eventMap;
    }
    
    public Map<Id, String> loadClassComponents() {
        List<Class_Component__c> classComponents = AttendanceTrackingFormQueryService.queryClassComponentsForWorkshop(this.workshopId);
        Map<Id, String> classComponentMap = new Map<Id, String>();
        for (Class_Component__c classComponent: classComponents) {
            classComponentMap.put(classComponent.Id, classComponent.Name);
        }
        return classComponentMap;
    }
    
    @RemoteAction
    public static void deleteUos(String uosId) {
        delete new Unit_Of_Service__c(Id = uosId);
    }
    
    @RemoteAction
    public static BulkSaveResult upsertUosList(String workshopId, String classComponentId, List<UnitOfService> editedUosList) {
        BulkSaveResult result;
        Savepoint beforeUpsertSavepoint = Database.setSavepoint();
        try {
            result = doUpsertUosList(workshopId, classComponentId, editedUosList);
        }
        catch (Exception e) {
            result = new BulkSaveResult();
            result.success = false;
            result.hasRowLevelErrors = false;
            result.errorMessage = e.getMessage();
            result.errorStackTrace = e.getStackTraceString();
        }
        if (!result.success) {
            Database.rollback(beforeUpsertSavepoint);
        }
        return result;
    }

    private static BulkSaveResult doUpsertUosList(String workshopId, String classComponentId, List<UnitOfService> editedUosList) {
        Event_Workshop__c workshop = AttendanceTrackingFormQueryService.queryWorkshop(workshopId);
        Class_Component__c classComponent = AttendanceTrackingFormQueryService.queryClassComponent(classComponentId);
        
        List<Unit_Of_Service__c> uosObjectList = new List<Unit_Of_Service__c>();
        List<String> newParticipantIds = new List<String>();
        List<String> participantNames = new List<String>();
        for (Integer index = 0; index < editedUosList.size(); index ++) {
            UnitOfService uos = editedUosList[index];
            participantNames.add(uos.participantName);
            Unit_Of_Service__c uosObject = new Unit_Of_Service__c();
            if (!uos.serviceProviderId.equals('')) {
                uosObject.Service_Provider__c = uos.serviceProviderId;
            }
            uosObject.Service_Date__c = Date.parse(uos.ServiceDate);
            uosObject.Service_Time__c = uos.ServiceTime;
            uosObject.Number_of_Additional_People__c = uos.numberOfAdditionalPeople;
            uosObject.Billable_Units__c = uos.BillableUnits;
            uosObject.Type_of_Units__c = uos.TypeOfUnits;
            uosObject.Cancellation_Reason__c = uos.CancelReason;
            if (!uos.paymentSourceId.equals('')) {
                uosObject.Payment_Source__c = uos.paymentSourceId;
            }
            if (!uos.authorizationId.equals('')) {
                uosObject.Authorization__c = uos.authorizationId;
            }
            uosObject.Progress_Lesson_Notes__c = uos.ProgressLessonNotes;
            
            //KI added 4/6/2016:  NOTE: Error - attempt to dereference null object.  Enclosed setting of field inside If statement.
            if (uos.ProgressLessonNotes != NULL && uos.ProgressLessonNotes != '') {
                uosObject.Progress_Notes_Preview__c = (uos.ProgressLessonNotes.length() > 100) ? uos.ProgressLessonNotes.subString(0,100)+'...' : uos.ProgressLessonNotes;
            }
            
            if (uos.uosId.equals('')) {
                uosObject.Participant__c = uos.ParticipantId;
                uosObject.Event_Workshop__c = workshopId;
                uosObject.Class_Component__c = classComponentId;
                uosObject.Delivery_of_Services__c = DEFAULT_DELIVERY_OF_SERVICES_PICKLIST_VAL;
                uosObject.Program__c = workshop.Program__c;
                uosObject.Service__c = classComponent.Service__c;
                uosObject.Location_Picklist__c = classComponent.Location_Picklist__c; 
                // KI added Location_Picklist__c 4/22/2016 to populate Location in UOS based on Class/Component location. 
                newParticipantIds.add(uos.ParticipantId);
            }
            else {
                 uosObject.Id = uos.uosId;
            }
            uosObjectList.add(uosObject);
        }
        
        /**
         * Copy profile id from participant record before saving new units of service
         **/
        Map<Id, Participation__c> newParticipantMap = new Map<Id, Participation__c>(
            [Select Id, Profile__c from Participation__c where Id in :newParticipantIds]
        );
        for (Unit_Of_Service__c uosObject: uosObjectList) {
            if (uosObject.Id == null) {
                uosObject.Profile__c = newParticipantMap.get(uosObject.Participant__c).Profile__c;
            }
        }
        
        Database.UpsertResult[] upsertResults = Database.upsert(uosObjectList, Unit_Of_Service__c.Fields.Id, false);
        boolean allSuccess = true;
        BulkSaveResult bulkResult = new BulkSaveResult();
        List<UosSaveResult> uosResultList = new List<UosSaveResult>();
        for (Integer index = 0; index < upsertResults.size(); index ++) {
            Database.UpsertResult upsertResult = upsertResults[index];
            UosSaveResult saveResult = new UosSaveResult();
            if (upsertResult.isSuccess()) {
                saveResult.success = true;
            }
            else {
                saveResult.success = false;
                allSuccess = false;
                saveResult.errorMessage = getErrorMessageAsString(upsertResult.getErrors());
                saveResult.participantName = participantNames[index];
            }
            saveResult.uosId = upsertResult.getId();
            uosResultList.add(saveResult);
        }
        bulkResult.uosResultList = uosResultList;
        bulkResult.success = allSuccess;
        if (!allSuccess) {
            bulkResult.hasRowLevelErrors = true;
        }
        return bulkResult;
    }
    
    private static String getErrorMessageAsString(List<Database.Error> errors) {
        String message = '';
        Boolean firstError = true;
        for (Database.Error err: errors) {
            if (!firstError) {
                message += ', ';
            }
            if (err.getFields() != null && err.getFields().size() > 0) {
                if (err.getFields().size() == 1) {
                    message += '' + err.getFields()[0] + ': ';
                }
                else {
                    message += '[';
                    for (String field: err.getFields()) {
                        message += field + ' ';
                    }
                    message += ']: ';
                }
            }
            message += err.getMessage();
            /**
            if (err.getStatusCode() != null) {
                message += ', Status code: ' + err.getStatusCode();
            }
            **/
            firstError = false;
        }
        return message;
    }
    
    public String getWorkshopDetailPageUrl() {
        return '/' + workshopId;
    }
    
    public class UnitOfService {
        // TODO: All setters need to be private?
        public Boolean sample {get; set;}
        public String serviceProviderId {get; set;}
        public String serviceDate {get; set;}
        public Decimal serviceTime {get; set;}
        public String cancelReason {get; set;}
        public Integer numberOfAdditionalPeople {get; set;}
        
        // KI 5/10/2016: Changed billableUnits from type Integer to Decimal.
        public Decimal billableUnits {get; set;}
        public String typeOfUnits {get; set;}
        public String participantName {get; set;}
        public String participantId {get; set;}
        public String uosId {get; set;}
        public String progressLessonNotes {get; set;}
        public String paymentSourceId {get; set;}
        public String authorizationId {get; set;}
        
        public String rowType {
            get {
                return (sample ? 'Sample': (uosId == null ? 'New':'Existing'));
            }
        }

        public String rowTypeClass {
            get {
                return (sample ? 'tr-sample': (uosId == null ? 'tr-new':'tr-existing'));
            }
        }
    }
    
    public class BulkSaveResult {
        public Boolean success {get; private set;}
        public Boolean hasRowLevelErrors {get; private set;}
        public String errorMessage {get; private set;}
        public String errorStackTrace {get; private set;}
        public List<UosSaveResult> uosResultList{get; private set;}
    }
    
    public class UosSaveResult {
        public String uosId {get; private set;}
        public String participantName {get; private set;}
        public Boolean success {get; private set;}
        public String errorMessage {get; private set;}
    }
    
    public class DropDownRecord {
        public String id {get; private set;}
        public String name {get; private set;}
        
        public DropDownRecord(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
    
}