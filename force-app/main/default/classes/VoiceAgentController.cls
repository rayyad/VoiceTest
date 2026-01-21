/**
 * Controller class for Voice Agent Lightning Web Component
 */
public with sharing class VoiceAgentController {
    
    /**
     * Main method to handle voice input, process conversation, and save summary
     * Note: Speech-to-text is handled client-side using Web Speech API
     * @param accountId Account ID
     * @param transcribedText Text transcribed from speech (client-side)
     * @param conversationHistory Current conversation history
     * @return Response containing AI response and audio
     */
    @AuraEnabled
    public static Map<String, Object> processVoiceInput(String accountId, String transcribedText, List<Map<String, String>> conversationHistory) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            // Step 1: Add user message to conversation history
            if (conversationHistory == null) {
                conversationHistory = new List<Map<String, String>>();
            }
            Map<String, String> userMessage = new Map<String, String>();
            userMessage.put('role', 'user');
            userMessage.put('text', transcribedText);
            userMessage.put('timestamp', String.valueOf(DateTime.now().getTime()));
            conversationHistory.add(userMessage);
            
            // Step 2: Process conversation and get AI response
            String aiResponse = VoiceAgentService.processConversation(conversationHistory, accountId);
            response.put('aiResponse', aiResponse);
            
            // Step 3: Add AI response to conversation history
            Map<String, String> aiMessage = new Map<String, String>();
            aiMessage.put('role', 'assistant');
            aiMessage.put('text', aiResponse);
            aiMessage.put('timestamp', String.valueOf(DateTime.now().getTime()));
            conversationHistory.add(aiMessage);
            response.put('conversationHistory', conversationHistory);
            
            // Step 4: Convert AI response to speech using ElevenLabs
            String audioResponse = VoiceAgentService.textToSpeech(aiResponse, null);
            response.put('audioResponse', audioResponse);
            
            response.put('success', true);
        } catch (Exception e) {
            response.put('success', false);
            response.put('error', e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Saves the conversation summary to account notes
     * @param accountId Account ID
     * @param conversationHistory Conversation history to summarize
     * @return Success status and note ID
     */
    @AuraEnabled
    public static Map<String, Object> saveConversationToAccount(String accountId, List<Map<String, String>> conversationHistory) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            // Generate summary
            String summary = VoiceAgentService.generateConversationSummary(conversationHistory);
            
            // Save to account notes
            String noteId = AccountNoteService.saveConversationSummary(accountId, summary);
            
            response.put('success', true);
            response.put('noteId', noteId);
            response.put('summary', summary);
        } catch (Exception e) {
            response.put('success', false);
            response.put('error', e.getMessage());
        }
        
        return response;
    }
}
