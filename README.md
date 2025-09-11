# Prompt Playground

A clean, simplified macOS app for creating and organizing AI prompts.

## Features

- **Simple Prompt Management**: Create, edit, and organize your prompts
- **Local Storage**: All data is stored locally using UserDefaults
- **Clean Interface**: Traditional macOS split-view design
- **Prompt Parameters**: Configure system prompt, user prompt, temperature, and maximum tokens
- **Search**: Find prompts by title or content
- **Sample Prompts**: Includes helpful starter prompts

## Getting Started

1. Open the app
2. Select a sample prompt from the sidebar or create a new one
3. Configure your prompt with:
   - **System Prompt**: Instructions for the AI's behavior and role
   - **User Prompt**: The actual query or task
   - **Temperature**: Controls randomness (0.0 = focused, 1.0 = creative)
   - **Maximum Tokens**: Limits response length

## Architecture

The app follows SwiftUI best practices with:

- `PromptModel`: Simple data model for prompts
- `PromptStore`: Local storage manager using UserDefaults
- `ContentView`: Main split-view interface
- `SidebarView`: Prompt list and search
- `PromptDetailView`: Prompt editing interface

## Requirements

- macOS 14.0+ (for SwiftUI features)
- Xcode 15.0+
