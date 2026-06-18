# Guide : Tracking Figé avec Sélection Automatique

## 📋 Résumé des Fonctionnalités

Ce guide explique les nouvelles fonctionnalités ajoutées au système d'eye tracking pour améliorer l'interaction utilisateur.

## ✨ Nouvelles Fonctionnalités

### 1. **Sélection Automatique quand le Curseur devient Vert**

Quand le regard de l'utilisateur reste stable sur une zone pendant quelques frames (curseur devient vert), le système :
- ✅ Encadre automatiquement la zone ciblée
- ✅ Fige le tracking à cette position
- ✅ Le curseur reste vert et affiche une icône de cadenas 🔒

### 2. **Sélection Manuelle avec Gel du Tracking**

Quand l'utilisateur touche/clique sur une zone :
- ✅ La zone est encadrée (bordure rouge)
- ✅ Le curseur devient vert et se positionne au centre de la zone
- ✅ Le tracking est figé - le curseur ne bouge plus
- ✅ L'icône du curseur change en cadenas 🔒

### 3. **Réactivation du Tracking**

L'utilisateur peut réactiver le tracking de plusieurs façons :
- 🔄 Cliquer à nouveau sur la zone encadrée (désélection)
- 🔄 Cliquer sur l'icône d'eye tracking dans l'AppBar
- 🔄 Via le dialogue qui s'affiche avec le bouton "Réactiver"

## 🎨 Indicateurs Visuels

### Curseur d'Eye Tracking

| État | Couleur | Bordure | Icône | Description |
|------|---------|---------|-------|-------------|
| **Actif (mobile)** | 🔴 Rouge | Blanche | 👁️ Œil | Le tracking suit le regard |
| **Stable** | 🟢 Vert | Blanche | 👁️ Œil | Le regard est stable |
| **Figé** | 🟢 Vert | 🟡 Ambre | 🔒 Cadenas | Le tracking est figé |

### Encadrement des Zones

| État | Bordure | Description |
|------|---------|-------------|
| **Hover (regard)** | 🟠 Orange | Le regard survole la zone |
| **Sélectionné** | 🔴 Rouge | La zone est sélectionnée |

### Indicateur de Statut (bas gauche)

| État | Couleur Fond | Icône | Texte |
|------|--------------|-------|-------|
| **Tracking actif** | 🟢 Vert | 👁️ | "Tracking (x, y)" |
| **Tracking figé** | 🟡 Ambre | 🔒 | "Tracking figé (x, y)" |
| **Tracking inactif** | ⚫ Gris | 🚫 | "Tracking inactif" |

## 🔧 Modifications Techniques

### Fichiers Modifiés

1. **`welcomrea/lib/Views/PainView.dart`**
   - Ajout de variables d'état pour le gel du tracking
   - Nouvelle méthode `_autoSelectWidgetUnderGaze()` pour la sélection automatique
   - Nouvelle méthode `_selectWidgetAndFreezeTracking()` pour figer le tracking
   - Nouvelle méthode `_unfreezeTracking()` pour réactiver le tracking
   - Modification de `_handleGazeData()` pour gérer l'état figé
   - Mise à jour du curseur avec indicateur de cadenas
   - Mise à jour de l'indicateur de statut

2. **`welcomrea/lib/components/empty_widget.dart`**
   - Ajout de méthodes pour notifier le parent lors de la sélection/désélection
   - Communication avec `_PainViewState` pour figer/dégeler le tracking

### Nouvelles Variables d'État

```dart
bool   _trackingFrozen = false;              // Indique si le tracking est figé
double _frozenX        = 0.0;                // Position X figée
double _frozenY        = 0.0;                // Position Y figée
GlobalKey<State<StatefulWidget>>? _selectedWidgetKey;  // Widget sélectionné
```

## 🎯 Flux d'Utilisation

### Scénario 1 : Sélection par le Regard

```
1. L'utilisateur regarde une zone
   └─> Curseur rouge suit le regard
   
2. Le regard reste stable 4 frames
   └─> Curseur devient vert
   └─> Zone est automatiquement encadrée (orange)
   └─> Tracking se fige
   └─> Curseur affiche un cadenas 🔒
   
3. Pour continuer :
   └─> Cliquer sur l'icône 👁️ dans l'AppBar
   └─> Choisir "Réactiver"
   └─> Le tracking reprend
```

### Scénario 2 : Sélection par le Toucher

```
1. L'utilisateur touche une zone
   └─> Zone encadrée en rouge
   └─> Curseur devient vert et se positionne au centre
   └─> Tracking se fige avec icône cadenas 🔒
   
2. Pour désélectionner :
   └─> Toucher à nouveau la zone
   └─> OU cliquer sur l'icône 👁️ > "Réactiver"
   └─> Le tracking reprend
```

## 🚀 Avantages

1. **Meilleure Précision** : L'utilisateur peut confirmer visuellement sa sélection
2. **Moins de Fatigue** : Pas besoin de maintenir le regard fixe pendant longtemps
3. **Feedback Visuel Clair** : Indicateurs multiples (couleur, icône, encadrement)
4. **Contrôle Total** : L'utilisateur peut réactiver quand il le souhaite

## 🐛 Dépannage

### Le tracking ne se fige pas automatiquement
- Vérifier que `_stableThreshold` est à 4 frames
- Vérifier que `_stableRadius` est à 60 pixels
- S'assurer que la calibration est correcte

### Le curseur ne devient pas vert
- Vérifier la stabilité du regard
- Augmenter `_stableRadius` si nécessaire
- Réduire `_stableThreshold` pour une réponse plus rapide

### Le tracking ne se réactive pas
- Vérifier que `_unfreezeTracking()` est bien appelée
- S'assurer que les états sont correctement réinitialisés

## 📝 Notes de Développement

- Le système utilise une distance Manhattan pour calculer la proximité du regard
- Le seuil de stabilité est de 60 pixels de rayon
- 4 frames consécutives sont nécessaires pour considérer le regard comme stable
- Le gel du tracking préserve la dernière position connue
