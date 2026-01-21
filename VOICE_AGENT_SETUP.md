# Voice Agent Setup Guide

This Salesforce Voice Agent integrates with ElevenLabs API to provide voice-to-voice interaction and automatically saves conversation summaries to Account notes.

## Components Created

### Apex Classes
1. **VoiceAgentService.cls** - Handles ElevenLabs API integration for text-to-speech (speech-to-text is handled client-side)
2. **VoiceAgentController.cls** - Main controller for the Lightning Web Component, handles conversation flow and error handling
3. **AccountNoteService.cls** - Manages creating and retrieving ContentNote objects on Accounts

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
- The Apex classes (via Profile or Permission Set):
  - `VoiceAgentService`
  - `VoiceAgentController`
  - `AccountNoteService`
- Objects (via Profile or Permission Set):
  - `ContentNote` (read/create)
  - `ContentVersion` (read)
  - `ContentDocumentLink` (read/create)
  - `Account` (read/write)
- Field-level security for Account fields (Name, Industry, Type)

## Usage

1. Navigate to an Account record
2. Find the Voice Agent component on the page
3. Click **Start Recording** and speak
4. Click **Stop Recording** when finished
5. The agent will process your voice and respond
6. Click **Save Conversation** to store the summary in Account notes

## Features

- **Voice Input**: Record audio directly from the browser using Web Speech API
- **Speech-to-Text**: Converts your speech to text using browser's built-in Web Speech API (no API key needed, works offline)
- **AI Response**: Processes conversation and generates responses with account context
- **Text-to-Speech**: Converts AI responses back to audio using ElevenLabs (optional - conversation continues even if TTS fails)
- **Conversation History**: View the full conversation with user and assistant messages
- **Resilient Error Handling**: Conversation context is preserved even if audio generation fails
- **Auto-Save**: Save conversation summaries as ContentNote objects on the Account

## Important Notes

1. **ElevenLabs API**: The implementation uses ElevenLabs text-to-speech API. The API key is optional - if not configured, conversations will still work but without audio playback. Users will see a warning message.

2. **AI Integration**: The `processConversation` method currently uses a simple echo response. For production, integrate with:
   - OpenAI GPT API
   - Salesforce Einstein GPT
   - Other AI services

3. **Browser Support**: Web Speech API is supported in Chrome, Edge, and Safari. Firefox support is limited.

4. **Browser Permissions**: Users will need to grant microphone permissions when first using the component. HTTPS is required for microphone access.

5. **Speech Recognition**: Uses browser's built-in Web Speech API for speech-to-text (no additional API setup required, works offline).

6. **ContentNote Implementation**: Notes are stored as ContentNote objects (which extend ContentVersion). The implementation correctly queries ContentVersion to get ContentDocumentId for linking notes to Accounts.

7. **Error Handling**: 
   - Text-to-speech failures are non-fatal - conversations continue even if audio generation fails
   - Conversation history is always preserved, even if audio fails
   - Users will see a warning toast if audio is unavailable but conversation succeeded

## Recent Updates & Bug Fixes

### Version Updates
- **TTS Failure Handling**: Text-to-speech failures are now non-fatal. Conversations continue even if ElevenLabs API is unavailable or misconfigured.
- **Conversation History Preservation**: Fixed bug where conversation history was lost if audio generation failed. History is now always preserved.
- **ContentNote Implementation**: Fixed ContentNote linking by correctly querying ContentVersion for ContentDocumentId.
- **Error Messages**: Improved error handling with user-friendly warnings for audio failures.

## Troubleshooting

### Microphone Not Working
- Check browser permissions
- Ensure HTTPS is used (required for microphone access)
- Try a different browser

### API Errors (ElevenLabs)
- **Conversation still works**: If the ElevenLabs API key is missing or invalid, the conversation will continue without audio playback
- Verify your API key is correct in Named Credential/Custom Metadata
- Check Named Credential/Custom Metadata configuration
- Review Salesforce debug logs for detailed error messages
- Users will see a warning message if audio generation fails

### Notes Not Saving
- Verify user has access to ContentNote, ContentVersion, and ContentDocumentLink objects
- Check Account record permissions (read/write)
- Ensure ContentNote is enabled in your org (available in most orgs by default)
- Review debug logs for errors
- Note: The implementation correctly uses ContentVersion to get ContentDocumentId for linking

### Conversation History Lost
- This has been fixed! Conversation history is now preserved even if audio generation fails
- If you experience issues, check browser console for errors
- Ensure the component has proper error handling (already implemented)

## Architecture & Implementation Details

### Conversation Flow
1. User speaks → Browser Web Speech API transcribes to text (client-side)
2. Transcribed text sent to `VoiceAgentController.processVoiceInput()`
3. User message added to conversation history
4. AI processes conversation and generates response
5. AI response added to conversation history
6. Text-to-speech conversion attempted (non-blocking)
7. Response returned to client with conversation history and optional audio

### Error Handling
- **TTS Failures**: Wrapped in try-catch, don't fail the conversation
- **Conversation History**: Always preserved and returned, even on partial failures
- **Client-Side**: Shows warnings for audio failures but continues conversation

### ContentNote Implementation
- Uses `ContentNote` object (extends `ContentVersion`)
- After insert, queries `ContentVersion` to get `ContentDocumentId`
- Creates `ContentDocumentLink` to associate note with Account
- Returns `ContentDocumentId` for reference

## Next Steps

1. **Integrate with real AI service** for intelligent responses:
   - OpenAI GPT API
   - Salesforce Einstein GPT
   - Anthropic Claude API
2. Add support for multiple languages in speech recognition
3. Add voice selection options for ElevenLabs TTS
4. Implement conversation context awareness and memory
5. Add analytics and reporting on conversation metrics
6. Add support for custom voice models
7. Implement conversation export functionality
