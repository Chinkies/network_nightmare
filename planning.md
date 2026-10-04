# Feuille de route — Network Nightmare (Godot 4)

Cette feuille de route structure le développement du prototype en séparant le moteur logique de l'interface utilisateur et des interactions 2D[cite: 7, 8]. Les tâches sont réparties entre le **Développeur A** (logique, graphes, simulation) et le **Développeur B** (vue 2D, contrôles, UI/UX, retours visuels et sonores)[cite: 7, 8, 13, 15].

---

## Phase 1 : Socle technique et contrats d'interface

### Développeur A — Modèle logique du réseau
- Définir la structure de données des **Paquets** (ressource/classe : `id`, `type`/couleur, `forme`, `durée de vie / TTL`, `payload`)[cite: 7, 9, 13].
- Implémenter la structure de **Graphe abstrait** :
  - Classe de base `NetworkNode` (file d'attente FIFO interne, capacité maximale, ports d'entrée/sortie, temps de traitement par tick)[cite: 7, 8, 12].
  - Classe `NetworkEdge` / Câble (liaison orientée entre deux ports avec capacité/débit)[cite: 7, 13, 21].
- Créer le gestionnaire de simulation (`SimulationManager`) basé sur des pas de temps discrets (Start, Pause, Reset, Tick)[cite: 7, 8, 13].

### Développeur B — Plateau de jeu et contrôles
- Mettre en place la scène principale de jeu avec une `Camera2D` bornée (déplacement X/Y et zoom molette clampé)[cite: 15, 16].
- Implémenter la grille de placement 2D (`GridManager`) avec système d'aimantation (snap)[cite: 13].
- Créer la barre de commandes UI de la simulation : boutons *Play*, *Pause*, *Reset/Stop*[cite: 10, 13].

---

## Phase 2 : Interactions et composants élémentaires

### Développeur A — Logique des premiers composants
- Implémenter le nœud **Source / Émetteur** (génération d'une série prédéfinie de paquets selon un calendrier de ticks)[cite: 7, 12].
- Implémenter le nœud **Puits / Récepteur** (vérification de la conformité du paquet reçu et comptage des réussites)[cite: 7, 12].
- Implémenter les composants de base :
  - **Routeur basique / Nœud directionnel** (aiguillage simple)[cite: 12, 17].
  - **Séparateur (Splitter)** (tri par couleur/forme vers des sorties distinctes)[cite: 17].
- Gérer les conditions d'erreur logique : congestion (file saturée), boucle infinie, time-out d'un paquet[cite: 9, 12, 13, 21].

### Développeur B — Câblage et glisser-déposer (Drag & Drop)
- Implémenter le drag & drop des équipements depuis le panneau latéral vers la grille[cite: 8, 13].
- Développer l'outil de câblage interactif :
  - Clic sur un port de sortie, tracé visuel dynamique vers un port d'entrée[cite: 13].
  - Rendu vectoriel du câble via `Line2D`[cite: 15].
  - Interdiction de poser un équipement sur un câble existant ou sur une case occupée[cite: 13].
- Intégrer les sprites 2D des équipements et les ancres des ports de connexion[cite: 15].

---

## Phase 3 : Animation du flux et retours utilisateurs (Signes & Retours)

### Développeur A — Validation et états du puzzle
- Coder le système d'évaluation de fin de puzzle :
  - Détection de la condition de victoire (100 % des paquets requis validés)[cite: 12].
  - Détection de la condition d'échec (perte de paquet, surcharge matérielle, time-out)[cite: 12, 13, 17].
- Développer le chargeur de niveaux (`LevelLoader`) à partir de fichiers de données (JSON ou `Resource` Godot) définissant : grille initiale, items disponibles dans l'inventaire, séquence de paquets à injecter[cite: 12].

### Développeur B — Visualisation des paquets et feedback visuel/sonore
- Animer les paquets le long des câbles (`PathFollow2D` ou interpolation `Tween` le long des segments du `Line2D`)[cite: 9, 13, 15].
- Signes et alertes visuelles :
  - Shader ou effet de tremblement (shake) sur un composant proche de la saturation[cite: 9, 12].
  - Effet visuel lors de la destruction ou rejet d'un paquet (time-out, mauvaise route)[cite: 13, 15, 17].
- Intégration des retours sonores (SFX) : pose d'item, connexion de câble, passage de paquet, validation de niveau, son d'alerte/erreur[cite: 13, 16, 17].

---

## Phase 4 : Composants avancés et modes de jeu

### Développeur A — Mécaniques avancées et Pentesting
- Implémenter les composants spécialisés :
  - **Filtre / Pare-feu** (détruit les paquets malveillants, laisse passer les paquets légitimes)[cite: 18, 21].
  - **Répartiteur de charge (Load Balancer)** (distribution alternée ou équitable)[cite: 21].
  - **Priorisation QoS** (traitement prioritaire selon étiquette de paquet)[cite: 21].
- Implémenter le mode **Pentesting** :
  - Réseau figé non modifiable[cite: 8, 12, 21].
  - Interface d'injection : le joueur compose et injecte une séquence de paquets forgés pour provoquer une défaillance[cite: 8, 12, 21].

### Développeur B — UI de configuration et intégration des modes
- Implémenter le panneau contextuel de configuration des composants (clic droit pour définir les règles d'un filtre ou le routage)[cite: 13, 22].
- Développer les variantes d'interface selon le mode :
  - Mode Modification (certains composants ou câbles sont verrouillés/non déplaçables)[cite: 11, 22].
  - Mode Pentesting (panneau d'injection de paquets au lieu de l'inventaire de machines)[cite: 8, 12].
- Intégrer l'affichage des objectifs du niveau (pourcentage de paquets livrés, paquets rejetés)[cite: 10, 12].

---

## Phase 5 : Menus, progression et déploiement

### Développeur A — Système de sauvegarde et export multiplateforme
- Implémenter la sauvegarde locale (progression des niveaux débloqués et sauvegarde de l'état du circuit en cours)[cite: 12, 14].
- Configurer les profils d'export dans Godot :
  - **Export Web (HTML5/Wasm)** avec le renderer *Compatibility*[cite: 1].
  - **Export Linux (binaire x86_64 standard)**[cite: 1].
  - **Export Windows (.exe)**[cite: 1].
- Valider les builds en conditions réelles (exécution Web dans le navigateur sans blocage CORS / SharedArrayBuffer)[cite: 1].

### Développeur B — Parcours utilisateur et habillage global
- Créer l'écran titre et le menu principal (Campagne, Sélection de niveaux, Quitter)[cite: 13].
- Concevoir l'écran de sélection de niveaux sous forme de carte/arborescence linéaire (Actes I, II, III et embranchements)[cite: 10, 13, 14].
- Assembler 3 à 4 niveaux représentatifs et fonctionnels :
  1. *Niveau Didacticiel* : routage simple d'un point A à un point B[cite: 17].
  2. *Niveau Filtre/Sécurité* : tri de formes/couleurs avec pare-feu[cite: 17, 21].
  3. *Niveau Pentesting* : saturation ciblée d'un sous-système[cite: 21].
- Finaliser la page itch.io (description, lecteur Web plein écran, téléversement des archives Linux/Windows)[cite: 1].