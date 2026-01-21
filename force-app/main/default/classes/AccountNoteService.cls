/**
 * Service class for managing account notes
 */
public with sharing class AccountNoteService {
    
    /**
     * Creates a ContentNote (Note) on an Account
     * @param accountId The Account ID
     * @param title Note title
     * @param content Note content
     * @return The created ContentNote ID
     */
    @AuraEnabled
    public static String createAccountNote(String accountId, String title, String content) {
        try {
            // Verify account access
            Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            
            // Create ContentNote
            ContentNote note = new ContentNote();
            note.Title = title;
            note.Content = Blob.valueOf(content);
            
            insert note;
            
            // Query ContentVersion to get the ContentDocumentId
            // ContentNote creates a ContentVersion, and we need to get the ContentDocumentId from it
            ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :note.Id LIMIT 1];
            
            // Link the note to the Account using ContentDocumentLink
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = accountId;
            link.ContentDocumentId = cv.ContentDocumentId;
            link.ShareType = 'V'; // Viewer access
            link.Visibility = 'AllUsers';
            
            insert link;
            
            return cv.ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating account note: ' + e.getMessage());
        }
    }
    
    /**
     * Saves conversation summary as a note on the account
     * @param accountId The Account ID
     * @param conversationSummary The summary text to save
     * @return The created ContentNote ID
     */
    @AuraEnabled
    public static String saveConversationSummary(String accountId, String conversationSummary) {
        try {
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            
            String title = 'Voice Conversation - ' + Datetime.now().format('MM/dd/yyyy HH:mm');
            String content = 'Account: ' + acc.Name + '\n\n' + conversationSummary;
            
            return createAccountNote(accountId, title, content);
        } catch (Exception e) {
            throw new AuraHandledException('Error saving conversation summary: ' + e.getMessage());
        }
    }
    
    /**
     * Gets recent notes for an account
     * @param accountId The Account ID
     * @param limitCount Number of notes to retrieve
     * @return List of note information
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAccountNotes(String accountId, Integer limitCount) {
        try {
            List<Map<String, Object>> notes = new List<Map<String, Object>>();
            
            // Query ContentDocumentLinks to get notes linked to the account
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate, 
                       ContentDocument.ContentSize, ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accountId
                  AND ContentDocument.FileType = 'SNOTE'
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT :limitCount
            ];
            
            for (ContentDocumentLink link : links) {
                Map<String, Object> noteInfo = new Map<String, Object>();
                noteInfo.put('id', link.ContentDocumentId);
                noteInfo.put('title', link.ContentDocument.Title);
                noteInfo.put('createdDate', link.ContentDocument.CreatedDate);
                noteInfo.put('size', link.ContentDocument.ContentSize);
                notes.add(noteInfo);
            }
            
            return notes;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account notes: ' + e.getMessage());
        }
    }
}
