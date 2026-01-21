/**
 * Service class for integrating with ElevenLabs API for voice processing
 */
public with sharing class VoiceAgentService {
    
    private static final String ELEVENLABS_API_URL = 'https://api.elevenlabs.io/v1';
    
    // Note: Speech-to-text is handled client-side using Web Speech API
    // This method is kept for potential future use with other services
    
    /**
     * Converts text to speech using ElevenLabs API
     * @param text Text to convert to speech
     * @param voiceId Voice ID from ElevenLabs (optional, uses default if not provided)
     * @return Base64 encoded audio data
     */
    @AuraEnabled
    public static String textToSpeech(String text, String voiceId) {
        try {
            String apiKey = getApiKey();
            
            HttpRequest req = new HttpRequest();
            String endpoint = ELEVENLABS_API_URL + '/text-to-speech/' + (String.isNotBlank(voiceId) ? voiceId : '21m00Tcm4TlvDq8ikWAM');
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('xi-api-key', apiKey);
            req.setHeader('Accept', 'audio/mpeg');
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('text', text);
            requestBody.put('model_id', 'eleven_monolingual_v1');
            
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                // Convert binary response to base64
                Blob audioBlob = res.getBodyAsBlob();
                return EncodingUtil.base64Encode(audioBlob);
            } else {
                throw new AuraHandledException('ElevenLabs API error: ' + res.getStatus() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error generating speech: ' + e.getMessage());
        }
    }
    
    /**
     * Processes conversation and generates a response using AI
     * @param conversationHistory List of conversation messages
     * @param accountId Account ID for context
     * @return AI-generated response
     */
    @AuraEnabled
    public static String processConversation(List<Map<String, String>> conversationHistory, String accountId) {
        try {
            // Get account context
            Account acc = [SELECT Id, Name, Industry, Type FROM Account WHERE Id = :accountId LIMIT 1];
            
            // Build context for AI
            String context = 'You are a helpful Salesforce assistant. ';
            context += 'The user is interacting with Account: ' + acc.Name;
            if (String.isNotBlank(acc.Industry)) {
                context += ' (Industry: ' + acc.Industry + ')';
            }
            context += '. Provide helpful, professional responses.';
            
            // For now, use a simple response. In production, integrate with OpenAI, Einstein, or similar
            // This is a placeholder - you would integrate with your preferred AI service here
            String lastMessage = conversationHistory.isEmpty() ? '' : conversationHistory[conversationHistory.size() - 1].get('text');
            
            // Simple echo response - replace with actual AI integration
            return 'I understand you said: "' + lastMessage + '". How can I help you with ' + acc.Name + '?';
        } catch (Exception e) {
            throw new AuraHandledException('Error processing conversation: ' + e.getMessage());
        }
    }
    
    /**
     * Generates a summary of the conversation
     * @param conversationHistory List of conversation messages
     * @return Summary text
     */
    @AuraEnabled
    public static String generateConversationSummary(List<Map<String, String>> conversationHistory) {
        try {
            if (conversationHistory == null || conversationHistory.isEmpty()) {
                return 'No conversation to summarize.';
            }
            
            // Build summary from conversation history
            String summary = 'Conversation Summary:\n\n';
            for (Map<String, String> message : conversationHistory) {
                String role = message.get('role');
                String text = message.get('text');
                summary += role + ': ' + text + '\n';
            }
            
            summary += '\n--- End of conversation ---';
            
            // In production, use AI to generate a more intelligent summary
            return summary;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating summary: ' + e.getMessage());
        }
    }
    
    /**
     * Gets the ElevenLabs API key from Named Credential or Custom Metadata
     * In production, use Named Credential for secure storage
     */
    private static String getApiKey() {
        // Option 1: Use Named Credential (recommended)
        // return 'callout:ElevenLabs_API';
        
        // Option 2: Use Custom Metadata Type
        // VoiceAgentSettings__mdt settings = VoiceAgentSettings__mdt.getInstance('Default');
        // return settings.API_Key__c;
        
        // Option 3: Use Custom Setting (less secure)
        // VoiceAgentSettings__c settings = VoiceAgentSettings__c.getInstance();
        // return settings.API_Key__c;
        
        // For now, throw an error to remind user to configure
        throw new AuraHandledException('Please configure ElevenLabs API key in Named Credential or Custom Metadata');
    }
}
