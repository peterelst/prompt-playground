# Prompt Playground

A beautiful iOS 26 app for developers to experiment with Apple Foundation Models prompts.

## Features

✨ **Prompt Management**
- Create and organize prompts with system and user prompts
- Adjust temperature and max tokens with visual estimates
- Tag system for easy organization
- Search functionality across all prompts

📁 **Project Organization**
- Bundle prompts into color-coded projects
- Optional project-based organization
- Quick project switching

☁️ **CloudKit Sync**
- Seamless sync across all your devices
- Private CloudKit database for security
- Automatic background sync

🤖 **Apple Intelligence Integration**
- Native Apple Foundation Models support (iOS 26+)
- On-device processing for privacy
- Real-time availability detection

💾 **Output Management**
- Save and favorite AI outputs
- Historical tracking of prompt results
- Associate outputs with specific prompt configurations

💰 **Support the Developer**
- Consumable IAP for tipping
- Support continued development

## Requirements

- iOS 26.0+ (when released)
- Xcode 16.0+
- CloudKit account
- Apple Intelligence capable device

## Setup

1. Open `PromptPlayground.xcodeproj` in Xcode
2. Configure your development team and bundle identifier
3. Set up CloudKit container in Apple Developer portal
4. Update entitlements with your CloudKit container ID
5. Configure IAP products in App Store Connect

## CloudKit Schema

The app uses three record types:

- **PromptModel**: Stores prompt configurations
- **ProjectModel**: Stores project organization
- **SavedOutputModel**: Stores AI outputs and results

## Apple Intelligence

The app integrates with Apple's Foundation Models API. When Apple Intelligence is unavailable, users can still create and organize prompts, but the Run button will be disabled.

## Architecture

Built with SwiftUI and follows MVVM pattern:

- **Models**: CloudKit-enabled data models
- **Services**: CloudKit, Apple Intelligence, and IAP managers
- **Views**: SwiftUI views with responsive design

## Future Enhancements

- Export/import functionality
- Prompt sharing between users
- Advanced analytics
- Template library
- Shortcuts integration

---

Built with ❤️ for the iOS developer community.
