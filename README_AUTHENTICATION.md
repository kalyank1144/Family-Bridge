# FamilyBridge Authentication System

## Overview

This document describes the complete authentication system implemented for FamilyBridge, a multi-generational family care coordination app. The authentication system provides secure user management, role-based access control, family group management, and accessibility features tailored for different user types.

## Architecture

### Core Components

1. **AuthService** (`lib/core/services/auth_service.dart`)
   - Handles all authentication operations with Supabase
   - Manages secure storage and biometric authentication
   - Provides family group creation and management
   - Implements offline unlock capabilities

2. **AuthProvider** (`lib/features/auth/providers/auth_provider.dart`)
   - App-wide authentication state management
   - Session persistence and inactivity management
   - Role-based routing and navigation
   - Integration with Flutter lifecycle

3. **User Models** (`lib/core/models/user_model.dart`, `lib/core/models/family_model.dart`)
   - Type-safe data models for users and families
   - Comprehensive user profile with accessibility preferences
   - Family group structure with role-based permissions

## Authentication Flow

### 1. Onboarding (`/onboarding`)
- Welcome screen with app overview
- Role selection (Elder, Caregiver, Youth)
- Feature preview based on selected role
- Personalized setup guidance

### 2. Authentication Screens

#### Login Screen (`/login`)
- Email/password authentication
- Social login (Google, Apple)
- Biometric authentication support
- Forgot password recovery
- Large text support for elderly users
- Voice announcements for accessibility

#### Signup Screen (`/signup`)
- Email/password registration with validation
- Role-based signup flow
- Terms of service and privacy policy acceptance
- Email verification flow
- Accessibility-first design

#### Forgot Password (`/forgot-password`)
- Email-based password reset
- Security question recovery option
- Voice-guided process for elderly users
- Multiple recovery methods

### 3. Profile Setup (`/profile-setup`)
- Personal information collection
- Profile photo upload
- Medical conditions tracking (for elders)
- Emergency contact setup
- Accessibility preferences configuration
- Privacy consent management

### 4. Family Group Management

#### Family Setup (`/family-setup`)
- Create new family group or join existing
- Generate shareable family codes
- Role assignment within family
- Secure invitation system

#### Family Members (`/family-members`)
- View all family members and roles
- Manage permissions and access levels
- Send family member invitations
- Remove members with proper authorization

## Security Features

### 1. Supabase Integration
- Row Level Security (RLS) policies
- Encrypted data storage
- Email verification and password reset
- Social authentication providers
- Multi-device session management

### 2. Local Security
- Flutter Secure Storage for sensitive data
- Biometric authentication (fingerprint, face ID)
- Auto-logout after inactivity
- Secure token storage
- Offline authentication capabilities

### 3. Privacy Compliance
- HIPAA-compliant health data handling
- User consent management
- Data retention policies
- Encrypted medical information
- Granular privacy controls

## Database Schema

### Core Tables

```sql
-- Extended user profiles
public.user_profiles
- user_id (UUID, FK to auth.users)
- photo_url (TEXT)
- medical_conditions (TEXT[])
- accessibility (JSONB)
- consent (JSONB)
- security_question (TEXT)
- security_answer_hash (TEXT)

-- Family groups
public.family_groups
- id (UUID, PK)
- name (TEXT)
- code (TEXT, unique)
- created_by (UUID, FK to auth.users)

-- Family memberships
public.family_members
- family_id (UUID, FK to family_groups)
- user_id (UUID, FK to auth.users)
- role (TEXT: primary-caregiver, secondary-caregiver, elder, youth)
- permissions (TEXT: owner, admin, member, viewer)

-- Family invitations
public.family_invites
- family_id (UUID, FK to family_groups)
- email (TEXT)
- role (TEXT)
- code (TEXT, unique)
- expires_at (TIMESTAMPTZ)
```

### Security Policies

All tables use Row Level Security (RLS):
- Users can only access their own data
- Family members can access family group data based on permissions
- Secure invitation and join processes
- Encrypted storage for sensitive information

## User Roles and Permissions

### Elder
- **Focus**: Health monitoring, medication reminders, family communication
- **UI**: Large text, high contrast, voice guidance
- **Permissions**: View own data, communicate with family, manage own health info
- **Features**: Emergency contacts, medication tracking, daily check-ins

### Caregiver
- **Focus**: Health monitoring for family, appointment coordination, care management
- **UI**: Professional layout, data visualization, management tools
- **Permissions**: View family health data (with consent), manage appointments, coordinate care
- **Features**: Health monitoring dashboard, alert management, family oversight

### Youth
- **Focus**: Family communication, staying connected
- **UI**: Modern interface, social features
- **Permissions**: Family communication, limited health data access
- **Features**: Chat, family updates, school-time restrictions

## Accessibility Features

### For Elderly Users
- Large text and high contrast themes
- Voice guidance and announcements
- Simple navigation and error messaging
- Biometric authentication for ease
- Emergency contact quick access
- Voice-guided password recovery

### Universal Design
- Screen reader compatibility
- Keyboard navigation support
- Multiple authentication methods
- Clear visual hierarchy
- Touch-friendly interface elements

## API Endpoints and Functions

### Authentication Functions
```sql
-- Join family by code
join_family_by_code(p_code TEXT, p_role TEXT)

-- Reset password via security answer
reset_password_via_security_answer(p_email TEXT, p_answer TEXT)

-- Set security question
set_security_question(p_question TEXT, p_answer TEXT)
```

### Storage Buckets
- `profile-photos`: User profile images
- `medication-photos`: Medication confirmation images
- `voice-notes`: Voice recordings for check-ins

## Integration Points

### 1. Router Guards
- Authentication-aware routing
- Role-based navigation
- Onboarding flow integration
- Session management

### 2. Theme Integration
- Role-based themes (elder vs. standard)
- Accessibility preferences
- Dynamic text scaling
- High contrast support

### 3. Voice Service Integration
- Voice announcements for auth actions
- Screen change announcements
- Error message vocalization
- Accessibility guidance

## Development Setup

### 1. Environment Configuration
```bash
# Create .env file
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. Database Setup
```sql
-- Run in order:
1. supabase/schema.sql (base tables)
2. supabase/migrations/20250919_auth_system.sql (auth system)
```

### 3. Storage Configuration
- Create storage buckets in Supabase dashboard
- Apply storage policies for secure access
- Configure public/private bucket settings

### 4. Authentication Providers
- Configure Google OAuth in Supabase
- Set up Apple Sign-In (iOS)
- Configure email templates
- Set up redirect URLs

## Testing Strategy

### Unit Tests
- Authentication service methods
- User model validation
- Family group operations
- Security policy enforcement

### Integration Tests
- Complete authentication flows
- Family group creation and joining
- Profile setup and management
- Multi-device session handling

### Accessibility Tests
- Screen reader compatibility
- Voice guidance functionality
- Large text rendering
- High contrast themes
- Biometric authentication

### Security Tests
- RLS policy validation
- Data encryption verification
- Session management testing
- Permission boundary checks

## Deployment Considerations

### Security
- Environment variable security
- SSL/TLS configuration
- Database connection security
- API key protection

### Performance
- Authentication caching
- Database query optimization
- Image compression for profiles
- Offline capability management

### Monitoring
- Authentication success/failure rates
- Session duration analytics
- User onboarding completion rates
- Accessibility feature usage

## Troubleshooting

### Common Issues

1. **RLS Permission Denied**
   - Verify user profile exists in `public.users`
   - Check RLS policies are applied
   - Ensure proper user ID context

2. **Biometric Auth Fails**
   - Verify device support
   - Check permissions
   - Test on physical device

3. **Family Code Issues**
   - Ensure codes are unique
   - Check expiration times
   - Verify family group exists

4. **Voice Service Problems**
   - Check microphone permissions
   - Verify TTS configuration
   - Test on physical device

### Debug Tools
- Supabase dashboard for database issues
- Flutter inspector for UI problems
- Device logs for authentication errors
- Network inspector for API calls

## Future Enhancements

### Planned Features
- Multi-factor authentication
- Advanced biometric options
- SSO integration for healthcare systems
- Enhanced family permission granularity
- Improved offline capabilities

### Security Improvements
- Hardware security module integration
- Advanced threat detection
- Audit logging enhancements
- Zero-trust architecture components

### Accessibility Enhancements
- Additional voice commands
- Smart home integration
- Emergency alert improvements
- AI-powered assistance features

## Support and Documentation

- **Technical Support**: See GitHub issues
- **Security Issues**: security@familybridge.app
- **Accessibility Feedback**: accessibility@familybridge.app
- **API Documentation**: Generated from code comments
- **User Guides**: Role-specific documentation available