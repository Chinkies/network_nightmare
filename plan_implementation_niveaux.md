# Plan d'implémentation des niveaux

## Objectif

Mettre en place des niveaux configurés manuellement dans Godot, sans parseur
JSON, tout en conservant une seule scène de jeu générique et une séparation
claire entre :

- la définition statique d'un niveau ;
- son instanciation au lancement ;
- la simulation ;
- la validation des objectifs ;
- l'affichage du résultat au joueur.

Le sélecteur de niveaux choisira une ressource `LevelDefinition`, puis chargera
la scène de jeu commune. Les fichiers `.tres` seront créés et configurés
manuellement dans l'éditeur Godot.

---

## 1. Architecture générale

```text
Sélecteur de niveaux
        |
        v
LevelContext.current_level
        |
        v
LevelScene.tscn
        |
        v
LevelManager
   |         |          |
   v         v          v
Instanciateur  Simulation  Validateur
   |                         |
   v                         v
Devices, grille        Résultat de niveau
                                 |
                                 v
                         LevelEndUi
```

Le niveau est une donnée et non une scène dupliquée. Il ne faut pas créer une
copie de la scène principale pour chaque niveau.

---

## 2. Contrats communs à définir avant le développement

### 2.1 `LevelDefinition`

La ressource doit contenir au minimum :

- identifiant interne du niveau ;
- largeur et hauteur de la grille ;
- liste des devices imposés au chargement ;
- position et rotation de chaque device imposé ;
- état déplaçable et supprimable de chaque device ;
- stocks disponibles pour le joueur ;
- liste des objectifs ;
- identifiant du niveau suivant ;

Chaque device initial doit référencer une ressource `NetworkDeviceData`.

### 2.2 Description d'un device initial

Chaque entrée doit pouvoir définir :

- la ressource du device ;
- un identifiant unique ;
- une cellule de grille ;
- une rotation initiale ;
- `is_movable` ;
- `is_deletable`.

Les transmitters et receivers sont ainsi posés par la configuration du niveau,
et non par une méthode de debug.

### 2.3 Objectifs

Commencer avec un ensemble réduit et explicite :

- livrer un paquet à un receiver précis ;
- livrer un nombre minimal de paquets ;
- ne perdre aucun paquet ;
- ne faire expirer aucun paquet ;
- ne pas dépasser une quantité de devices ;
- terminer avant une durée maximale, si nécessaire.

Éviter au début un système d'objectifs entièrement scriptable ou trop générique.

### 2.4 Résultat de validation

Le validateur doit produire une structure indépendante de l'UI contenant :

- réussite ou échec global ;
- objectifs réussis ;
- objectifs échoués ;
- statistiques de simulation :
  - nombre de paquets émis, livrés, rejetés et expirés ;
  - nombre de devices placés ;
  - temps écoulé.

### 2.5 Signaux publics

Les événements utiles à l'intégration doivent être définis à l'avance :

- niveau chargé ;
- objectif mis à jour ;
- paquet livré ;
- paquet rejeté ;
- paquet expiré ;
- simulation terminée ;
- résultat de niveau disponible.

L'UI ne doit pas dépendre des structures internes des devices ou du validateur.

---

## 3. Répartition entre les deux développeurs

## Phase commune — Conception des interfaces

### Travail commun

1. Définir `LevelDefinition`.
2. Définir la description des devices initiaux.
3. Définir les types d'objectifs.
4. Définir la structure du résultat final.
5. Définir les signaux entre logique et interface.
6. Choisir le nom définitif de la scène commune.
7. Choisir l'emplacement des ressources de niveaux.

### Livrable

Un premier niveau minimal décrit par une ressource `.tres`, même si
l'instanciation et l'UI ne sont pas encore terminées.

Cette phase est obligatoire avant la séparation pour éviter que les deux
développeurs implémentent des interfaces incompatibles.

---

## Phase A — Données, chargement et validation

Responsable : développeur A.

### A1. Créer les ressources de définition

Créer :

- `LevelDefinition` ;
- les sous-ressources nécessaires pour les devices initiaux ;
- les descriptions d'objectifs ;
- les ressources `.tres` des premiers niveaux.

Les paquets doivent réutiliser les classes existantes :

- `NetworkPacketData` pour décrire un paquet ;
- `ScheduleEvent` pour décrire son délai ;
- `NetworkTransmitterData` pour le calendrier d'émission.

Chaque émission importante doit avoir un identifiant permettant une validation
fiable. La couleur et le numéro seuls ne doivent pas être considérés comme un
identifiant unique.

### A2. Créer le contexte de niveau

Créer un autoload `LevelContext` contenant le niveau actuellement sélectionné.

Responsabilités :

- recevoir une ressource depuis le sélecteur ;
- la conserver pendant le changement de scène ;
- permettre à la scène de jeu de la récupérer ;
- fournir un niveau par défaut lors d'un lancement direct depuis l'éditeur.

La ressource reste statique. Elle ne doit jamais contenir l'état courant d'une
partie.

### A3. Créer l'instanciation du niveau

Créer `LevelInstantiator`, ou intégrer cette responsabilité à
`LevelManager` si le nombre de fichiers doit rester réduit.

Responsabilités :

1. récupérer la définition active ;
2. configurer la taille de `GridBoard` ;
3. créer les devices imposés ;
4. appliquer leurs positions, rotations et états ;
5. créer et relier leurs vues ;
6. enregistrer les devices dans `GridBoard` et `SimulationRunner` ;
7. initialiser les stocks de l'inventaire ;
8. préparer le validateur.

La méthode `_debug_spawn_transmitter()` doit être supprimée ou remplacée par
ce mécanisme.

### A4. Faire évoluer `LevelManager`

`LevelManager` doit orchestrer :

- le chargement du niveau ;
- l'initialisation de la grille ;
- le lancement et l'arrêt de la simulation ;
- le reset ;
- le verrouillage des modes d'édition ;
- la notification de l'UI ;
- l'affichage du résultat final via le composant UI prévu.

Il reste l'orchestrateur, mais ne doit pas contenir les données particulières
d'un niveau.

### A5. Compléter la télémétrie de simulation

Faire remonter au validateur :

- l'émission d'un paquet ;
- la livraison correcte à un receiver ;
- le rejet d'un paquet ;
- l'expiration TTL ;
- la fin de chaque calendrier d'émission ;
- la fin complète de la simulation.

La simulation ne doit être considérée comme terminée que lorsque :

1. tous les calendriers sont terminés ;
2. les buffers des devices sont vides ;
3. les câbles ne transportent plus de paquets ;
4. aucun paquet éphémère ne reste actif.

### A6. Créer `LevelValidator`

Le validateur doit :

- écouter les événements de la simulation ;
- comptabiliser les résultats ;
- évaluer chaque objectif ;
- éviter de dépendre de l'UI ;
- produire un résultat final unique ;
- être réinitialisable sans recréer la scène.

Le reset doit remettre à zéro tous les compteurs et états de validation.

### Livrable de la phase A

Un niveau peut être sélectionné ou lancé par défaut, chargé dans la scène
commune, simulé, validé et réinitialisé sans intervention manuelle dans le
code pour ce niveau précis.

---

## Phase B — Sélection, affichage et navigation

Responsable : développeur B.

### B1. Adapter le sélecteur de niveaux

Le sélecteur ne doit plus charger une scène différente pour chaque bouton.

Chaque bouton doit référencer une `LevelDefinition`, puis :

1. assigner cette ressource à `LevelContext.current_level` ;
2. charger la scène commune ;
3. gérer explicitement les erreurs si la ressource est absente.

Le menu peut afficher à partir de la ressource :

- nom ;
- difficulté ;
- numéro ;
- état verrouillé ou débloqué ;
- meilleur score si cette fonctionnalité existe.

### B2. Créer l'interface des objectifs

Afficher les objectifs avant et pendant la simulation :

- texte de l'objectif ;
- état non commencé ;
- état en cours ;
- état réussi ;
- état échoué.

L'UI reçoit des mises à jour via les signaux publics, sans inspecter le
validateur directement.

### B3. Créer `LevelEndUi`

Créer une scène séparée pour le résultat final contenant :

- titre réussite ou échec ;
- liste des objectifs réussis ;
- liste des objectifs échoués ;
- statistiques utiles ;
- bouton recommencer ;
- bouton retour à la sélection ;
- bouton niveau suivant en cas de réussite.

Cette UI doit être masquée au chargement et affichée une seule fois après la
validation finale.

### B4. Gérer les états d'interface

Pendant la simulation :

- désactiver les outils d'édition ;
- conserver le contrôle pause/reset selon le comportement retenu ;
- empêcher une nouvelle pose ou suppression.

Après la fin :

- empêcher les modifications du réseau ;
- permettre le reset ou la navigation ;
- éviter le déclenchement multiple de la validation.

### B5. Intégrer le stock et les statistiques

Le menu d'appareils doit afficher les stocks définis par le niveau.

Les valeurs affichées doivent être mises à jour lors de :

- la pose d'un device ;
- sa suppression ;
- son reset ;
- un nouveau chargement de niveau.

### Livrable de la phase B

Un joueur peut sélectionner un niveau, voir ses objectifs et son inventaire,
lancer la simulation, consulter le résultat, recommencer ou naviguer vers un
autre niveau.

---

## Phase d'intégration commune

Les deux développeurs travaillent ensemble pour :

1. connecter `LevelContext` au sélecteur ;
2. connecter `LevelManager` au chargement ;
3. brancher le validateur sur les signaux de simulation ;
4. connecter le résultat à `LevelEndUi` ;
5. tester le reset complet ;
6. tester le passage au niveau suivant ;
7. vérifier le lancement direct de la scène commune ;
8. vérifier les erreurs de configuration.

### Scénarios minimum à tester

- niveau absent dans `LevelContext` ;
- ressource de device invalide ;
- position hors grille ;
- cellule déjà occupée ;
- stock à zéro ;
- paquet correctement livré ;
- paquet livré au mauvais receiver ;
- paquet perdu ;
- paquet expiré ;
- simulation sans câble ;
- reset pendant une simulation ;
- validation déclenchée une seule fois ;
- retour au sélecteur puis chargement d'un autre niveau.

---

## Phase de création des niveaux

Une fois le socle validé, les ressources de niveaux peuvent être créées sans
modifier la logique :

1. dupliquer une ressource `.tres` de niveau ;
2. configurer la grille ;
3. ajouter les transmitters et receivers ;
4. définir les positions et rotations ;
5. configurer les calendriers de paquets ;
6. renseigner les stocks ;
7. ajouter les objectifs ;
8. associer la ressource à un bouton du sélecteur ;
9. tester le parcours complet.

Progression recommandée :

1. routage simple entre un transmitter et un receiver ;
2. plusieurs paquets ou destinations ;
3. contrainte de stock, mauvais routage ou expiration TTL.

---

## 4. Structure finale optimale du projet

```text
network_nightmare/
├── autoload/
│   └── level_context.gd
├── core/
│   ├── level_manager.gd
│   ├── network_device.gd
│   ├── network_packet.gd
│   ├── network_wire.gd
│   ├── devices/
│   ├── grid/
│   ├── resource_definitions/
│   │   ├── level_definition.gd
│   │   ├── level_device_entry.gd
│   │   ├── level_objective.gd
│   │   ├── network_device_data.gd
│   │   ├── network_packet_data.gd
│   │   └── schedule_event.gd
│   └── simulation/
│       ├── simulation_runner.gd
│       └── level_validator.gd
├── levels/
│   ├── level_scene.tscn
│   └── definitions/
│       ├── level_01.tres
│       ├── level_02.tres
│       └── level_03.tres
├── resources/
│   ├── devices/
│   ├── packet/
│   └── ui/
└── ui/
    ├── levelSelectionMenu/
    ├── level_end_ui/
    ├── puzzle_ui/
    └── device_selection_menu/
```

Le nom exact des dossiers peut rester aligné sur les conventions actuelles,
mais les responsabilités doivent être séparées de cette manière.

---

## 5. Renommages recommandés

### `levels/Main.tscn` vers `levels/level_scene.tscn`

`Main.tscn` n'est plus un bon nom lorsque la scène représente tous les niveaux.
`level_scene.tscn` indique clairement qu'il s'agit de la scène de jeu générique.

### `levels/main.gd` vers `levels/level_scene.gd`

Le script associé doit porter le même rôle que la scène. Il reste responsable
de la scène Node2D, de la caméra et du cadrage initial, mais ne doit pas
contenir la définition d'un niveau particulier.

### `debug_transmitter_data` et `debug_transmitter_cell`

Ces exports de [LevelManager](/home/jerem/Documents/M2_IMAGINE_2026-2027/jeux_serieux/network_nightmare/core/level_manager.gd)
doivent disparaître. Ils sont remplacés par la liste des devices de
`LevelDefinition`.

### `level_device_limits`

Cette propriété ne doit plus être stockée directement dans `LevelManager`.
Elle doit provenir de la ressource de niveau, puis être transmise au système
d'inventaire.

### `first_level_scene`

Dans [levelSelectionMenu.gd](/home/jerem/Documents/M2_IMAGINE_2026-2027/jeux_serieux/network_nightmare/ui/levelSelectionMenu/levelSelectionMenu.gd),
remplacer les références à des scènes par des références à des ressources
`LevelDefinition`.

Le menu doit charger systématiquement `level_scene.tscn`.

### `_debug_spawn_transmitter()`

Remplacer cette méthode par une méthode d'instanciation générique capable de
poser tous les devices définis dans le niveau.

### `levelSelectionMenu.gd`

Renommage optionnel mais recommandé vers `level_selection_menu.gd` pour suivre
la convention snake_case utilisée ailleurs dans le projet.

### `Main` comme nom de classe ou de nœud

Renommer progressivement `Main` en `LevelScene` si aucune dépendance externe
ne l'impose. Ce renommage peut être réalisé après le fonctionnement du système
pour limiter les risques d'intégration.

---

## 6. Règles de responsabilité

### `LevelDefinition`

Décrit uniquement un niveau statique.

### `LevelContext`

Conserve le niveau sélectionné pendant le changement de scène.

### `LevelScene`

Contient la scène générique de jeu, la caméra, la grille et les composants
communs.

### `LevelManager`

Orchestre le chargement, la simulation, le reset et la fin de niveau.

### `LevelValidator`

Évalue les objectifs et produit un résultat.

### `LevelEndUi`

Affiche le résultat et déclenche les actions de navigation.

Cette séparation doit être respectée pour éviter de recréer une logique
spécifique dans chaque niveau.

