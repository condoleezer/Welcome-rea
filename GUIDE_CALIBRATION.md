# 🎯 Guide pour une calibration précise

## Le problème principal
Le eye tracking n'est pas précis parce que **les iris ne bougent pas assez** pendant la calibration.

## ✅ Comment faire une BONNE calibration

### 1. Préparation
- Assieds-toi confortablement à **40-50cm** de l'écran
- Bon **éclairage** sur ton visage (pas de contre-jour)
- Pose la tablette sur un support stable

### 2. Pendant la calibration
**TRÈS IMPORTANT :**
- ✅ **Garde la TÊTE complètement immobile**
- ✅ **Bouge SEULEMENT TES YEUX** pour regarder les points
- ✅ **Force tes yeux à aller aux EXTRÊMES** (coins de l'écran)
- ✅ **Regarde VRAIMENT le centre du point rouge**, pas juste la zone
- ❌ **NE BOUGE PAS la tête** pour suivre les points

### 3. Vérifier la qualité
Après la calibration, regarde dans le terminal Python :

```
INFO:__main__:Variance iris : x=0.00XXXX, y=0.00YYYY
```

- **Mauvais** : x < 0.001 ou y < 0.001 → **REFAIRE la calibration**
- **Bon** : x > 0.001 ET y > 0.001 → Calibration OK

### 4. Si toujours pas précis
- Refais la calibration **2-3 fois**
- Essaie de **bouger encore plus les yeux** vers les coins
- Vérifie que l'**éclairage** est bon
- Assure-toi que la **caméra voit bien ton visage**

## 🔧 Améliorations apportées

1. **Points de calibration aux extrêmes** (0.05 et 0.95 au lieu de 0.1 et 0.9)
2. **Écran reste allumé** pendant la calibration (wakelock)
3. **Détection de variance faible** avec message d'erreur explicite
4. **Instructions claires** pendant la calibration

## 📊 Limitations du eye tracking

Le eye tracking basé sur la position de l'iris a des limites naturelles :
- Précision typique : **50-150 pixels**
- Dépend beaucoup de la **qualité de la calibration**
- Sensible aux **mouvements de tête**
- Nécessite un **bon éclairage**

Pour une précision parfaite, il faudrait du matériel spécialisé (eye tracker professionnel).
