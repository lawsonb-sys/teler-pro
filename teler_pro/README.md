# 🧵 Teler Pro — Application de Gestion d'Atelier de Couture

**Teler Pro** est une application mobile d'administration et de suivi d'ateliers de couture/taille sur-mesure. Conçue avec une architecture **Offline-First**, elle garantit aux artisans un accès instantané à leurs clients, commandes, mesures et paiements, même sans connexion Internet, avec une synchronisation automatique dès le retour du réseau.

---

## 🌟 Fonctionnalités Principales

- **📊 Tableau de bord interactif** : Vue d'ensemble en temps réel des commandes en cours, prêt-à-livrer et statistiques clés de l'atelier.
- **👥 Gestion de la clientèle** : Fichier client complet avec historique des commandes et gestion des coordonnées.
- **✂️ Suivi des commandes** : Prise de commande intuitive (type de vêtement, type de tissu, dates de livraison prévues, statuts).
- **💳 Gestion des paiements** : Suivi des avances, soldes et états d'encaissement par commande.
- **⚡ Fonctionnement Offline-First** :
  - Consultation et création immédiates sans latence réseau.
  - Stockage local sécurisé avec cache réactif.
  - Synchronisation transparente en arrière-plan.

---

## 🏗️ Architecture & Choix Techniques

### Stack Technologique

- **Framework** : Flutter (Dart 3+)
- **State Management** : `ValueNotifier` / `ChangeNotifier` avec typage fort (`Records` Dart 3 & `sealed classes` pour les états UI).
- **Base de données distante** : PocketBase
- **Stockage Local & Cache** : Hive (Repository Offline avec architecture événementielle par `Stream`).

### Structure du Projet

```text
lib/
├── controllers/      # Contrôleurs d'état (AccueilController, ClientsController, etc.)
├── models/           # Modèles de données (CommandeModel, ClientModel, etc.)
├── repo/             # Repositories d'accès aux données (OfflineRepository, etc.)
├── outils/           # Services, thèmes (KColors), utilitaires
└── pages/            # Écrans de l'application (AccueilPage, ClientsPage, Commandes, etc.)