# Feuille de route — Network Nightmare (Godot 4)

Cette feuille de route structure le développement du prototype en séparant le moteur logique de l'interface utilisateur et des interactions 2D. Les tâches sont réparties entre le **Développeur A** (logique, graphes, simulation) et le **Développeur B** (vue 2D, contrôles, UI/UX, retours visuels et sonores).

---

## Phase 1 : Socle technique et contrats d'interface

### Développeur A — Modèle logique du réseau
- Définir la structure de données des **Paquets** (ressource/classe : `id`, `type`/couleur, `forme`, `durée de vie / TTL`, `payload`).
- Implémenter la structure de **Graphe abstrait** :
  - Classe de base `NetworkNode` (file d'attente FIFO interne, capacité maximale, ports d'entrée/sortie, temps de traitement par tick).
  - Classe `NetworkEdge` / Câble (liaison orientée entre deux ports avec capacité/débit).
- Créer le gestionnaire de simulation (`SimulationManager`) basé sur des pas de temps discrets (Start, Pause, Reset, Tick).

### Développeur B — Plateau de jeu et contrôles
- Mettre en place la scène principale de jeu avec une `Camera2D` bornée (déplacement X/Y et zoom molette clampé).
- Implémenter la grille de placement 2D (`GridManager`) avec système d'aimantation (snap).
- Créer la barre de commandes UI de la simulation : boutons *Play*, *Pause*, *Reset/Stop*.

---

## Phase 2 : Interactions et composants élémentaires

### Développeur A — Logique des premiers composants
- Implémenter le nœud **Source / Émetteur** (génération d'une série prédéfinie de paquets selon un calendrier de ticks).
- Implémenter le nœud **Puits / Récepteur** (vérification de la conformité du paquet reçu et comptage des réussites).
- Implémenter les composants de base :
  - **Routeur basique / Nœud directionnel** (aiguillage simple).
  - **Séparateur (Splitter)** (tri par couleur/forme vers des sorties distinctes).
- Gérer les conditions d'erreur logique : congestion (file saturée), boucle infinie, time-out d'un paquet.

### Développeur B — Câblage et glisser-déposer (Drag & Drop)
- Implémenter le drag & drop des équipements depuis le panneau latéral vers la grille.
- Développer l'outil de câblage interactif :
  - Clic sur un port de sortie, tracé visuel dynamique vers un port d'entrée.
  - Rendu vectoriel du câble via `Line2D`.
  - Interdiction de poser un équipement sur un câble existant ou sur une case occupée.
- Intégrer les sprites 2D des équipements et les ancres des ports de connexion.

---

## Phase 3 : Animation du flux et retours utilisateurs (Signes & Retours)

### Développeur A — Validation et états du puzzle
- Coder le système d'évaluation de fin de puzzle :
  - Détection de la condition de victoire (100 % des paquets requis validés).
  - Détection de la condition d'échec (perte de paquet, surcharge matérielle, time-out).
- Développer le chargeur de niveaux (`LevelLoader`) à partir de fichiers de données (JSON ou `Resource` Godot) définissant : grille initiale, items disponibles dans l'inventaire, séquence de paquets à injecter.

### Développeur B — Visualisation des paquets et feedback visuel/sonore
- Animer les paquets le long des câbles (`PathFollow2D` ou interpolation `Tween` le long des segments du `Line2D`).
- Signes et alertes visuelles :
  - Shader ou effet de tremblement (shake) sur un composant proche de la saturation.
  - Effet visuel lors de la destruction ou rejet d'un paquet (time-out, mauvaise route).
- Intégration des retours sonores (SFX) : pose d'item, connexion de câble, passage de paquet, validation de niveau, son d'alerte/erreur.

---

## Phase 4 : Composants avancés et modes de jeu

### Développeur A — Mécaniques avancées et Pentesting
- Implémenter les composants spécialisés :
  - **Filtre / Pare-feu** (détruit les paquets malveillants, laisse passer les paquets légitimes).
  - **Répartiteur de charge (Load Balancer)** (distribution alternée ou équitable).
  - **Priorisation QoS** (traitement prioritaire selon étiquette de paquet).
- Implémenter le mode **Pentesting** :
  - Réseau figé non modifiable.
  - Interface d'injection : le joueur compose et injecte une séquence de paquets forgés pour provoquer une défaillance.

### Développeur B — UI de configuration et intégration des modes
- Implémenter le panneau contextuel de configuration des composants (clic droit pour définir les règles d'un filtre ou le routage).
- Développer les variantes d'interface selon le mode :
  - Mode Modification (certains composants ou câbles sont verrouillés/non déplaçables).
  - Mode Pentesting (panneau d'injection de paquets au lieu de l'inventaire de machines).
- Intégrer l'affichage des objectifs du niveau (pourcentage de paquets livrés, paquets rejetés).

---

## Phase 5 : Menus, progression et déploiement

### Développeur A — Système de sauvegarde et export multiplateforme
- Implémenter la sauvegarde locale (progression des niveaux débloqués et sauvegarde de l'état du circuit en cours).
- Configurer les profils d'export dans Godot :
  - **Export Web (HTML5/Wasm)** avec le renderer *Compatibility*.
  - **Export Linux (binaire x86_64 standard)**.
  - **Export Windows (.exe)**.
- Valider les builds en conditions réelles (exécution Web dans le navigateur sans blocage CORS / SharedArrayBuffer).

### Développeur B — Parcours utilisateur et habillage global
- Créer l'écran titre et le menu principal (Campagne, Sélection de niveaux, Quitter).
- Concevoir l'écran de sélection de niveaux sous forme de carte/arborescence linéaire (Actes I, II, III et embranchements).
- Assembler 3 à 4 niveaux représentatifs et fonctionnels :
  1. *Niveau Didacticiel* : routage simple d'un point A à un point B.
  2. *Niveau Filtre/Sécurité* : tri de formes/couleurs avec pare-feu.
  3. *Niveau Pentesting* : saturation ciblée d'un sous-système.
- Finaliser la page itch.io (description, lecteur Web plein écran, téléversement des archives Linux/Windows).
