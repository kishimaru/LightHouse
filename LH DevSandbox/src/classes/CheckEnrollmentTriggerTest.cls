@isTest
public class CheckEnrollmentTriggerTest {
    
    @isTest
    public static void testTrigger_NewEnrollmentCreated() {
        String workshopId = createTestWorkshop();
        List<String> classComponentIds = createTestComponents();
        List<String> participantIds = createTestParticipantsWithoutEnrollment();
        
        Unit_of_Service__c uos = new Unit_Of_Service__c(
            Participant__c = participantIds[0],
            Event_Workshop__c = workshopId,
            Class_Component__c = classComponentIds[0],
            Service_Time__c = 4.0
        );
        
        Test.startTest();
        insert uos;
        Test.stopTest();
        
        List<Enrollment__c> outEnrollments = [Select Id, Event_Workshop__c from Enrollment__c where Participant__c = :participantIds[0] and Class_Component__c = :classComponentIds[0]];
        System.assertEquals(1, outEnrollments.size());
        System.assertEquals(workshopId, outEnrollments[0].Event_Workshop__c);
    }

    @isTest
    public static void testTrigger_NewEnrollmentNotCreatedForUosWithoutClassId() {
        String workshopId = createTestWorkshop();
        List<String> classComponentIds = createTestComponents();
        List<String> participantIds = createTestParticipantsWithoutEnrollment();
        
        Unit_of_Service__c uos = new Unit_Of_Service__c(
            Participant__c = participantIds[0],
            Service_Time__c = 4.0
        );
        
        Test.startTest();
        insert uos;
        Test.stopTest();
        
        List<Enrollment__c> outEnrollments = [Select Id, Event_Workshop__c from Enrollment__c where Participant__c = :participantIds[0]];
        System.assertEquals(0, outEnrollments.size());
    }

    @isTest
    public static void testTrigger_ExistingEnrollmentNotCreated() {
        String workshopId = createTestWorkshop();
        List<String> classComponentIds = createTestComponents();
        List<String> participantIds = createTestParticipantsWithEnrollment();
        
        Unit_of_Service__c uos = new Unit_Of_Service__c(
            Participant__c = participantIds[0],
            Event_Workshop__c = workshopId,
            Class_Component__c = classComponentIds[0],
            Service_Time__c = 4.0
        );
        
        Test.startTest();
        insert uos;
        Test.stopTest();
        
        List<Enrollment__c> outEnrollments = [Select Id, Event_Workshop__c from Enrollment__c where Participant__c = :participantIds[0] and Class_Component__c = :classComponentIds[0]];
        System.assertEquals(1, outEnrollments.size());
    }

    public static String createTestWorkshop() {
        List<Program__c> programs = new List<Program__c>();
        programs.add(new Program__c(
            Name = 'TestProgram1',
            Active__c = true
        ));
        insert programs;
        
        List<Event_Workshop__c> workshops = new List<Event_Workshop__c>();
        workshops.add(new Event_Workshop__c(
            Name = 'TestWorkshop1',
            Active__c = true,
            Program__c = programs[0].Id
        ));
        insert workshops;
        return workshops[0].Id;
    }
    
    public static List<String> createTestComponents() {
        Id workshopId1 = [Select Id from Event_Workshop__c where Name = 'TestWorkshop1'].Id;
        List<Class_Component__c> classComponents = new List<Class_Component__c>();
        classComponents.add(new Class_Component__c(
            Name = 'TestClassComponent1',
            Hours__c = 4.0,
            Event_Workshop__c = workshopId1
        ));
        classComponents.add(new Class_Component__c(
            Name = 'TestClassComponent2',
            Hours__c = 4.0,
            Event_Workshop__c = workshopId1
        ));
        insert classComponents;
        return new List<String> {classComponents[0].Id, classComponents[1].Id};
    }

    private static List<String> createTestParticipantsWithEnrollment() {
        return createTestParticipants(true);
    }
        
    private static List<String> createTestParticipantsWithoutEnrollment() {
        return createTestParticipants(false);
    }

    private static List<String> createTestParticipants(Boolean createEnrollments) {
        String[] names = new List<String> {'John Smith', 'Mike Miller'};
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
        for (Integer i = 0; i < names.size(); i ++) {
            profiles.add(new Profile__c(
                Name = names[i],
                Contact__c = contacts[i].Id,
                Birthdate__c = Date.newInstance(1980, 11, 11)
            ));
        }
        insert profiles;
        
        Id programId = [Select Id from Program__c where Name = 'TestProgram1'].Id;
        List<Participation__c> participants = new List<Participation__c>();
        for (Integer i = 0; i < names.size(); i ++) {
            participants.add(new Participation__c(
                Name = names[i],
                Profile__c = profiles[i].Id,
                Program__c = programId
            ));
        }
        insert participants;
        
        if (createEnrollments) {
            Id workshopId1 = [Select Id from Event_Workshop__c where Name = 'TestWorkshop1'].Id;
            Id classComponentId1 = [Select Id from Class_Component__c where Name = 'TestClassComponent1'].Id;
            
            List<Enrollment__c> enrollments = new List<Enrollment__c>();
            for (Integer i = 0; i < names.size(); i ++) {
                enrollments.add(new enrollment__c(
                    Participant__c = participants[i].Id,
                    Class_Component__c = classComponentId1,
                    Event_Workshop__c = workshopId1
                ));
            }
            insert enrollments;
        }
        
        List<Id> returnIds = new List<Id>();
        for (Participation__c participant: participants) {
            returnIds.add(participant.Id);
        }
        return returnIds;
    }
}