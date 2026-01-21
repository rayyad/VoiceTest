import { LightningElement, api, track } from 'lwc';
import processVoiceInput from '@salesforce/apex/VoiceAgentController.processVoiceInput';
import saveConversationToAccount from '@salesforce/apex/VoiceAgentController.saveConversationToAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VoiceAgent extends LightningElement {
    @api recordId; // Account ID
    
    @track conversationHistory = [];
    @track isRecording = false;
    @track isProcessing = false;
    @track currentTranscription = '';
    @track currentResponse = '';
    
    recognition;
    isSpeechSupported = false;
    
    connectedCallback() {
        // Initialize conversation history
        this.conversationHistory = [];
        
        // Check if Web Speech API is supported
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            this.isSpeechSupported = true;
            this.initializeSpeechRecognition();
        } else {
            this.showToast('Not Supported', 'Your browser does not support speech recognition. Please use Chrome or Edge.', 'warning');
        }
    }
    
    /**
     * Initialize Web Speech API
     */
    initializeSpeechRecognition() {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        this.recognition = new SpeechRecognition();
        this.recognition.continuous = false;
        this.recognition.interimResults = false;
        this.recognition.lang = 'en-US';
        
        this.recognition.onstart = () => {
            this.isRecording = true;
            this.showToast('Recording started', 'Speak now...', 'info');
        };
        
        this.recognition.onresult = async (event) => {
            const transcript = event.results[0][0].transcript;
            this.currentTranscription = transcript;
            await this.processTranscription(transcript);
        };
        
        this.recognition.onerror = (event) => {
            console.error('Speech recognition error:', event.error);
            this.isRecording = false;
            this.isProcessing = false;
            if (event.error === 'no-speech') {
                this.showToast('No Speech', 'No speech detected. Please try again.', 'warning');
            } else {
                this.showToast('Error', 'Speech recognition error: ' + event.error, 'error');
            }
        };
        
        this.recognition.onend = () => {
            this.isRecording = false;
        };
    }
    
    /**
     * Start recording audio using Web Speech API
     */
    startRecording() {
        if (!this.isSpeechSupported) {
            this.showToast('Not Supported', 'Speech recognition is not supported in your browser.', 'error');
            return;
        }
        
        try {
            this.currentTranscription = '';
            this.currentResponse = '';
            this.recognition.start();
        } catch (error) {
            console.error('Error starting recognition:', error);
            this.showToast('Error', 'Could not start speech recognition.', 'error');
        }
    }
    
    /**
     * Stop recording audio
     */
    stopRecording() {
        if (this.recognition && this.isRecording) {
            this.recognition.stop();
            this.isRecording = false;
        }
    }
    
    /**
     * Process transcribed text and get AI response
     */
    async processTranscription(transcribedText) {
        this.isProcessing = true;
        
        try {
            // Call Apex to process voice input
            const result = await processVoiceInput({
                accountId: this.recordId,
                transcribedText: transcribedText,
                conversationHistory: this.conversationHistory
            });
            
            if (result.success) {
                this.currentResponse = result.aiResponse || '';
                this.conversationHistory = result.conversationHistory || [];
                
                // Play audio response if available
                if (result.audioResponse) {
                    this.playAudioResponse(result.audioResponse);
                }
            } else {
                throw new Error(result.error || 'Unknown error occurred');
            }
        } catch (error) {
            console.error('Error processing voice:', error);
            this.showToast('Error', 'Failed to process voice input: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isProcessing = false;
        }
    }
    
    /**
     * Play audio response from base64
     */
    playAudioResponse(base64Audio) {
        try {
            const audio = new Audio('data:audio/mpeg;base64,' + base64Audio);
            audio.play().catch(error => {
                console.error('Error playing audio:', error);
            });
        } catch (error) {
            console.error('Error creating audio element:', error);
        }
    }
    
    /**
     * Save conversation summary to account notes
     */
    async saveConversation() {
        if (!this.conversationHistory || this.conversationHistory.length === 0) {
            this.showToast('No Conversation', 'Please have a conversation before saving.', 'warning');
            return;
        }
        
        try {
            const result = await saveConversationToAccount({
                accountId: this.recordId,
                conversationHistory: this.conversationHistory
            });
            
            if (result.success) {
                this.showToast('Success', 'Conversation saved to account notes!', 'success');
                // Optionally clear conversation history
                // this.conversationHistory = [];
            } else {
                throw new Error(result.error || 'Unknown error occurred');
            }
        } catch (error) {
            console.error('Error saving conversation:', error);
            this.showToast('Error', 'Failed to save conversation: ' + (error.body?.message || error.message), 'error');
        }
    }
    
    /**
     * Clear conversation history
     */
    clearConversation() {
        this.conversationHistory = [];
        this.currentTranscription = '';
        this.currentResponse = '';
        this.showToast('Cleared', 'Conversation history cleared.', 'info');
    }
    
    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
    
    /**
     * Get conversation history for display
     */
    get hasConversation() {
        return this.conversationHistory && this.conversationHistory.length > 0;
    }
    
    /**
     * Check if buttons should be disabled
     */
    get shouldDisableButtons() {
        return this.isProcessing || !this.hasConversation;
    }
    
    /**
     * Get formatted conversation for display
     */
    get formattedConversation() {
        if (!this.hasConversation) {
            return [];
        }
        
        return this.conversationHistory.map((msg, index) => {
            const isUser = msg.role === 'user';
            const isAssistant = msg.role === 'assistant';
            let messageClass = 'slds-box ';
            if (isUser) {
                messageClass += 'slds-theme_default user-message';
            } else {
                messageClass += 'slds-theme_shade assistant-message';
            }
            
            return {
                id: index,
                role: msg.role,
                text: msg.text,
                isUser: isUser,
                isAssistant: isAssistant,
                messageClass: messageClass,
                senderLabel: isUser ? 'You' : 'Agent',
                timestamp: msg.timestamp || ''
            };
        });
    }
}
