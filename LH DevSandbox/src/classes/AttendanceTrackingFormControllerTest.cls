@isTest
public class AttendanceTrackingFormControllerTest {
    @isTest
    private static void testController() {
        TestDataCreator creator = new TestDataCreator();
        creator.execute();
        
        Id testWorkshopId = creator.workshopId;
        Id testComponentId = creator.componentId;
        System.currentPageReference().getParameters().put('workshopId', testWorkshopId);
        System.currentPageReference().getParameters().put('classId', testComponentId);
        
        Test.startTest();
        AttendanceTrackingFormController controller = new AttendanceTrackingFormController();
        
        System.assertEquals(testWorkshopId, controller.workshopId);
        System.assertEquals(testComponentId, controller.classId);
        System.assertEquals(2, controller.getWorkshopList().size());
        System.assertEquals(3, controller.componentsList.size());
        
        
        System.assert(controller.getHasUos());
        System.assertEquals(4, controller.uosList.size());
        System.assert(controller.getCancelReasonPicklistOptions().size() > 0);
        System.assert(controller.getTypeOfUnitsPicklistOptions().size() > 0);
        System.assert(controller.getWorkshopDetailPageUrl().contains(testWorkshopId));
        
        System.assertEquals('Sample', controller.uosList[0].rowType);
        System.assertEquals('Existing', controller.uosList[1].rowType);
        System.assertEquals('New', controller.uosList[2].rowType);
        System.assertEquals('New', controller.uosList[3].rowType);
        
        AttendanceTrackingFormController.UnitOfService editedUos1 = controller.uosList[1];
        editedUos1.ServiceProviderId = '';
        editedUos1.PaymentSourceId = '';
        editedUos1.AuthorizationId = '';
        editedUos1.ServiceDate = AttendanceTrackingFormController.dateToString(Date.today());
        AttendanceTrackingFormController.UnitOfService editedUos2 = controller.uosList[2];
        editedUos2.ServiceProviderId = '';
        editedUos2.PaymentSourceId = '';
        editedUos2.AuthorizationId = '';
        editedUos2.uosId = '';
        editedUos2.ServiceDate = AttendanceTrackingFormController.datetimeToString(Datetime.now());
        
        AttendanceTrackingFormController.BulkSaveResult upsertResult 
            = AttendanceTrackingFormController.upsertUosList(
            testWorkshopId, 
            testComponentId, 
            new AttendanceTrackingFormController.UnitOfService[] {editedUos1, editedUos2});
        
        System.assert(upsertResult.success, upsertResult.errorMessage + upsertResult.errorStackTrace);
        
        List<Unit_of_Service__c> savedNewUosList = [Select Profile__c, Profile__r.Name, Participant__r.Name from Unit_of_Service__c where Participant__c = :editedUos2.ParticipantId];
        System.assertEquals(1, savedNewUosList.size(), 'Expected new unit of service to be in database after calling upsertUosList');
        Unit_of_Service__c savedNewUos = savedNewUosList[0];
        System.assert(savedNewUos.Profile__c != null);
        System.assertEquals(savedNewUos.Profile__r.Name, savedNewUos.Participant__r.Name, 'Expected profile name to be same as participant name');
        
        Test.stopTest();
    }
    
    private class TestDataCreator {
        public Id workshopId;
        public Id componentId;
        public Id programId;
        
        public void execute() {
            createWorkshops();
            createComponents();
            createParticipantsWithEnrollment();
        }

        private void createWorkshops() {
            List<Program__c> programs = new List<Program__c>();
            programs.add(new Program__c(
                Name = 'Program1',
                Active__c = true
            ));
            insert programs;
            this.programId = programs[0].Id;
            
            List<Event_Workshop__c> workshops = new List<Event_Workshop__c>();
            workshops.add(new Event_Workshop__c(
                Name = 'Workshop1',
                Active__c = true,
                Program__c = programs[0].Id
            ));
            insert workshops;
            this.workshopId = workshops[0].Id;
        }
        
        private void createComponents() {
            List<Class_Component__c> classComponents = new List<Class_Component__c>();
            classComponents.add(new Class_Component__c(
                Name = 'Class Component 1',
                Hours__c = 4.0,
                Event_Workshop__c = this.workshopId
            ));
            classComponents.add(new Class_Component__c(
                Name = 'Class Component 2',
                Hours__c = 4.0,
                Event_Workshop__c = this.workshopId
            ));
            insert classComponents;
            this.componentId = classComponents[0].Id;
        }
    
        private void createParticipantsWithEnrollment() {
            String[] names = new List<String> {'Participant One', 'Participant Two', 'Participant Three'};
            List<Contact> contacts = new List<Contact>();
            for (Integer i = 0; i < names.size(); i ++) {
                String[] nameParts = names[i].split(' ');
                contacts.add(new Contact(
                    FirstName = nameParts[0],
                    LastName = nameParts[1]
                ));
            }
            insert contacts;
            
            List<Profile__c> profiles = new List<Profile__c>();
            for (Integer i = 0; i < contacts.size(); i ++) {
                profiles.add(new Profile__c(
                    Name = names[i],
                    Contact__c = contacts[i].Id,
                    Birthdate__c = Date.newInstance(1980, 11, 11)
                ));
            }
            insert profiles;
            
            Id programId = [Select Id from Program__c where Name = 'Program1'].Id;
            List<Participation__c> participants = new List<Participation__c>();
            for (Integer i = 0; i < profiles.size(); i ++) {
                participants.add(new Participation__c(
                    Name = names[i],
                    Profile__c = profiles[i].Id,
                    Program__c = programId
                ));
            }
            insert participants;
            
            List<Enrollment__c> enrollments = new List<Enrollment__c>();
            for (Integer i = 0; i < participants.size(); i ++) {
                enrollments.add(new enrollment__c(
                    Participant__c = participants[i].Id,
                    Class_Component__c = this.componentId,
                    Event_Workshop__c = this.workshopId
                ));
            }
            insert enrollments;
            
            Unit_Of_Service__c uosObject = new Unit_Of_Service__c();
            uosObject.Service_Date__c = Date.today();
            uosObject.Service_Time__c = 11.0;
            uosObject.Number_of_Additional_People__c = 1;
            uosObject.Billable_Units__c = 1;
            //uosObject.Type_of_Units__c = uos.TypeOfUnits;
            uosObject.Participant__c = participants[0].Id;
            uosObject.Event_Workshop__c = this.workshopId;
            uosObject.Class_Component__c = this.componentId;
            //uosObject.Delivery_of_Services__c = DEFAULT_DELIVERY_OF_SERVICES_PICKLIST_VAL;
            uosObject.Program__c = this.programId;
            insert uosObject;
            
        }
    }
    
}