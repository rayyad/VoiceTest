# Voice Agent Setup Guide

This Salesforce Voice Agent integrates with ElevenLabs API to provide voice-to-voice interaction and automatically saves conversation summaries to Account notes.

## Components Created

### Apex Classes
1. **VoiceAgentService.cls** - Handles ElevenLabs API integration for speech-to-text and text-to-speech
2. **VoiceAgentController.cls** - Main controller for the Lightning Web Component
3. **AccountNoteService.cls** - Manages creating and retrieving notes on Accounts

### Lightning Web Component
- **voiceAgent** - User interface for voice interaction

## Setup Instructions

### 1. Configure ElevenLabs API Key

You need to configure your ElevenLabs API key. Choose one of the following methods:

#### Option A: Named Credential (Recommended - Most Secure)

1. In Salesforce Setup, go to **Named Credentials**
2. Create a new Named Credential:
   - **Label**: ElevenLabs API
   - **Name**: ElevenLabs_API
   - **URL**: https://api.elevenlabs.io
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: Password Authentication
   - **Username**: (your ElevenLabs API key)
   - **Password**: (leave blank or use a dummy value)
   - **Generate Authorization Header**: Checked
   - **Header Name**: xi-api-key
   - **Header Value**: {!$Credential.Username}

3. Update `VoiceAgentService.cls`:
   - Uncomment the line: `return 'callout:ElevenLabs_API';`
   - Comment out or remove the throw statement

#### Option B: Custom Metadata Type

1. Create a Custom Metadata Type:
   - **Label**: Voice Agent Settings
   - **API Name**: VoiceAgentSettings__mdt
   - Add a field:
     - **Label**: API Key
     - **API Name**: API_Key__c
     - **Type**: Text (255)

2. Create a Custom Metadata record:
   - **Label**: Default
   - **API Name**: Default
   - **API Key**: (your ElevenLabs API key)

3. Update `VoiceAgentService.cls`:
   - Uncomment the Custom Metadata lines
   - Comment out the throw statement

#### Option C: Custom Setting (Less Secure)

1. Create a Custom Setting:
   - **Label**: Voice Agent Settings
   - **API Name**: VoiceAgentSettings__c
   - **Setting Type**: Hierarchy
   - Add a field:
     - **Label**: API Key
     - **API Name**: API_Key__c
     - **Type**: Text (255)

2. Create a Custom Setting record for your user or organization
3. Update `VoiceAgentService.cls` accordingly

### 2. Get Your ElevenLabs API Key

1. Sign up or log in to [ElevenLabs](https://elevenlabs.io)
2. Navigate to your profile/settings
3. Copy your API key
4. Use it in the configuration method you chose above

### 3. Deploy Components

Deploy all components to your Salesforce org:

```bash
sfdx force:source:deploy -p force-app/main/default/classes
sfdx force:source:deploy -p force-app/main/default/lwc/voiceAgent
```

### 4. Add Component to Account Page

1. Go to Setup → Object Manager → Account → Lightning Record Pages
2. Edit the Account record page (or create a new one)
3. Add the **Voice Agent** component to the page
4. Save and activate the page

### 5. Grant Permissions

Ensure your users have access to:
- The Apex classes (via Profile or Permission Set)
- ContentNote and ContentDocumentLink objects
- Account object (read/write)

## Usage

1. Navigate to an Account record
2. Find the Voice Agent component on the page
3. Click **Start Recording** and speak
4. Click **Stop Recording** when finished
5. The agent will process your voice and respond
6. Click **Save Conversation** to store the summary in Account notes

## Features

- **Voice Input**: Record audio directly from the browser using Web Speech API
- **Speech-to-Text**: Converts your speech to text using browser's built-in Web Speech API (no API key needed)
- **AI Response**: Processes conversation and generates responses
- **Text-to-Speech**: Converts AI responses back to audio using ElevenLabs
- **Conversation History**: View the full conversation
- **Auto-Save**: Save conversation summaries as notes on the Account

## Important Notes

1. **ElevenLabs API Endpoints**: The current implementation uses placeholder endpoints. You may need to adjust the API endpoints based on ElevenLabs' actual API documentation.

2. **AI Integration**: The `processConversation` method currently uses a simple echo response. For production, integrate with:
   - OpenAI GPT API
   - Salesforce Einstein
   - Other AI services

3. **Browser Support**: Web Speech API is supported in Chrome, Edge, and Safari. Firefox support is limited.

4. **Browser Permissions**: Users will need to grant microphone permissions when first using the component.

5. **Speech Recognition**: Uses browser's built-in Web Speech API for speech-to-text (no additional API setup required).

5. **ContentNote**: Notes are stored as ContentNote objects, which are the modern way to store notes in Salesforce.

## Troubleshooting

### Microphone Not Working
- Check browser permissions
- Ensure HTTPS is used (required for microphone access)
- Try a different browser

### API Errors
- Verify your API key is correct
- Check Named Credential/Custom Metadata configuration
- Review Salesforce debug logs for detailed error messages

### Notes Not Saving
- Verify user has access to ContentNote and ContentDocumentLink
- Check Account record permissions
- Review debug logs for errors

## Next Steps

1. Integrate with a real AI service for intelligent responses
2. Add support for multiple languages
3. Add voice selection options
4. Implement conversation context awareness
5. Add analytics and reporting
