# ScanMe

ScanMe est une application Flutter conçue pour faciliter le partage de contacts, la gestion de QR codes et les demandes d’accès à des profils sociaux. L’objectif est de proposer une expérience simple, rapide et sécurisée, avec un fort accent sur la confidentialité et le consentement.

## 🎯 Fonctionnalités principales

- Partage de contacts via QR code
- Scanner universel de QR codes
- Partage de proximité (Tap Share)
- Gestion des QR personnels
- Gestion des demandes d’accès et des profils sociaux
- Authentification Firebase
- Cryptage des données sensibles
- Interface moderne et fluide pour mobile

## 🛠️ Stack technique

- Flutter / Dart
- Firebase Auth et Firestore
- Riverpod pour la gestion d’état
- Hive pour le stockage local
- mobile_scanner, qr_flutter, encrypt, permission_handler

## ✅ Prérequis

Avant de lancer l’application, assure-toi d’avoir :

- Flutter SDK installé
- Android Studio ou Xcode selon la plateforme cible
- Un projet Firebase configuré

## 🚀 Installation

1. Cloner le dépôt
   ```bash
   git clone <url-du-repo>
   cd ScanMe-main
   ```

2. Installer les dépendances
   ```bash
   flutter pub get
   ```

3. Configurer Firebase
   - Ajouter les fichiers Firebase nécessaires pour Android/iOS
   - Vérifier que le fichier lib/firebase_options.dart est présent

4. Lancer l’application
   ```bash
   flutter run -d chrome
   ```

   ou sur un émulateur Android :
   ```bash
   flutter run
   ```

## 📁 Structure du projet

```text
lib/
├── core/           # Thèmes, providers, utilitaires, widgets
├── features/       # Modules fonctionnels (auth, home, scanner, contacts, profile)
├── main.dart       # Point d’entrée de l’application
└── firebase_options.dart

test/
├── unit/
├── widget/
```

## 🧪 Tests

Exécuter la suite de tests :

```bash
flutter test
```

## 🔐 Sécurité

L’application utilise le package encrypt pour protéger les données sensibles et s’appuie sur Firebase pour l’authentification et la gestion des accès.

## 🤝 Contribution

Les contributions sont les bienvenues. Avant de proposer une modification :

```bash
flutter analyze
flutter test
```

## 📌 Notes

Ce projet est en développement actif et peut évoluer selon les besoins fonctionnels et les retours utilisateurs.

## 📄 License

This project is private and proprietary.

## 📞 Support

For issues or questions:
- Open an GitHub issue
- Contact: dhmchristelle@gmail.com

## 🎯 Roadmap

- [ ] Proximity-based contact sharing (Bluetooth/NFC)
- [ ] Offline-first architecture
- [ ] Web dashboard
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] API rate limiting
- [ ] User notifications

---

**Made with ❤️ for West Africa**
