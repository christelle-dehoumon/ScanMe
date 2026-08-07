# Security Policy for ScanMe

## Data Security

### Encryption

#### At Rest
- Phone numbers, transaction data stored encrypted using AES-256
- Hive local database uses Hive encryption
- Firebase Firestore uses HTTPS with encryption

#### In Transit
- All Firebase communications use TLS 1.2+
- API calls use HTTPS only
- OTP codes are sent via Firebase (not SMS directly)

#### Implementation
```dart
import 'package:scanme_app/core/utils/encryption.dart';

// Encrypt sensitive data before storing
final encrypted = EncryptionService.encrypt(phoneNumber);
await hiveBox.put('phone', encrypted);

// Decrypt when needed
final decrypted = EncryptionService.decrypt(encrypted);
```

### Authentication

- Firebase Authentication with phone OTP
- Session tokens stored securely in encrypted Hive
- Automatic logout after 30 minutes of inactivity
- No credentials stored in plain text

### Privacy Controls

- Users control who can access their contacts
- Can revoke access at any time
- Account deletion removes all data permanently
- No tracking or unnecessary data collection

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Subcollections inherit parent rules
      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Shared contacts have explicit sharing logic
    match /shared_contacts/{document=**} {
      allow read: if resource.data.sharedWith.contains(request.auth.uid);
      allow write: if request.auth.uid == resource.data.ownerId;
    }
  }
}
```

## Best Practices

### For Users
1. **Keep your phone secure** - The app is protected by your device's security
2. **Use strong authentication** - Set a PIN/biometric on your device
3. **Review permissions** - Check who has access to your contacts
4. **Delete account if needed** - All data will be permanently deleted
5. **Report suspicious activity** - Contact support immediately

### For Developers
1. **Never log sensitive data** - Use appropriate log levels
2. **Use encryption by default** - All personal data should be encrypted
3. **Validate inputs** - Prevent injection attacks
4. **Keep dependencies updated** - Regular security updates
5. **Use HTTPS only** - All external API calls must use HTTPS

## Compliance

### GDPR (General Data Protection Regulation)
-  Users can request and delete their data
-  Data is minimized (only necessary info collected)
-  Privacy policy available in the app
-  Consent obtained for data processing

### Privacy by Design
- Data encryption by default
- No unnecessary data collection
- User control over data access
- Transparent data usage

## Reporting Security Issues

**Do not** create public GitHub issues for security vulnerabilities.

Instead:
1. Email: security@scanme.example.com
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if applicable)

3. Allow 48 hours for response
4. Do not disclose publicly until fix is released

## Security Checklist

- [ ] All user data is encrypted at rest
- [ ] HTTPS is used for all external communications
- [ ] Firestore rules are properly configured
- [ ] No sensitive data in logs
- [ ] Input validation implemented
- [ ] Authentication is required for sensitive operations
- [ ] Session timeout implemented
- [ ] Error messages don't leak information
- [ ] Dependencies are up to date
- [ ] Security tests pass

## Incident Response

1. **Identify** - Detect and confirm the security issue
2. **Isolate** - Prevent further damage
3. **Eradicate** - Remove the vulnerability
4. **Recover** - Restore normal operations
5. **Review** - Analyze what happened and improve
6. **Notify** - Inform affected users if necessary
