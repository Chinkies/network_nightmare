# Network Nightmare - Roadmap & Todo List

## 1. Fondations & Socle Technique Réalisés

* [x] **Modèle de données abstrait**
  * [x] Classe abstraite `NetworkDevice` (`network_device.gd`).
  * [x] Modélisation logique des câbles `NetworkWire` (`network_wire.gd`).
  * [x] Modélisation des unités de données `NetworkPacket` (`network_packet.gd`).

* [x] **Moteur d'horloge et de simulation**
  * [x] Moteur `NetworkSimulation` (`simulation.gd`) avec boucle `_physics_process`.
  * [x] Enregistrement et mise à jour cyclique des équipements et des câbles.
  * [x] Gestion du cycle de vie et expiration des paquets éphémères (`ephemeral_packets` / TTL).
  * [x] Méthodes d'exécution (`start`, `stop`, `step`).

* [x] **Navigation spatiale 2D**
  * [x] Scène principale `Main.tscn` configurée avec limites d'affichage.
  * [x] Caméra panoramique avec translations et zoom (`pan_zoom_camera.gd`).

* [x] **Contrôle utilisateur & Orchestration de base**
  * [x] Scène `UIPuzzle.tscn` intégrée dans un `CanvasLayer` dédié.
  * [x] Boutons exclusifs de contrôle d'exécution : **Start** et **Stop** (`radio_button.gd`).
  * [x] Bouton d'aide et indices (**Hint**).
  * [x] Contrôleur d'interface `ui_puzzle_controller.gd` avec signaux découplés.
  * [x] Orchestration racine dans `Main.gd` reliant les signaux UI aux méthodes de `NetworkSimulation`.

---

## 2. Système Spatial : Grille & Coordonnées (Étape Immédiate)

* [x] **Composant `GridManager`**
  * [x] Définir la structure du gestionnaire de grille (taille de cellule paramétrable, ex: 64x64 px).
  * [x] Fonctions de conversion bidirectionnelle : `world_to_grid(pos)` et `grid_to_world(coord)`.
  * [x] Registre d'occupation des cellules (savoir quelle machine ou quel câble occupe quelle case).
  * [x] Rendu visuel de la grille 2D (lignes ou points discrets configurables selon la taille du niveau).
  * [x] Gestion du confinement de la caméra aux limites de la grille du niveau courant.
  * [x] Gestion dynamique du niveau de zoom.
  * [ ] Gestion de la vitesse de déplacement en fonction du niveau de zoom.

---

## 3. Première Machine Concrète & Volet d'Inventaire

* [ ] **Socle 2D d'une machine concrète**
  * [ ] Créer une scène dérivée/concrète (ex: `HostNode` ou `Terminal` avec `Sprite2D` / `Area2D`).
  * [ ] Définition des connecteurs d'E/S (**Ports réseau**) avec ancrages locaux précis sur le sprite.
  * [ ] Distinction des états de persistance : `is_locked` (machine imposée par le puzzle) vs `is_editable` (placée par le joueur).

* [ ] **Volet latéral d'inventaire (UI rétractable)**
  * [ ] Panneau ancré à gauche de l'écran dans le `CanvasLayer`.
  * [ ] Bouton ou poignée permettant de replier/déplier le panneau avec animation/tween.
  * [ ] Liste des équipements disponibles pour le niveau avec icône, nom et compteur de stock restant.
  * [ ] Blocage des entrées de la caméra et du monde (`mouse_filter`) lorsque le curseur survole le volet.

* [ ] **Mécanique de placement sur la grille**
  * [ ] Détection du drag & drop (ou clic-sélection) depuis l'inventaire vers le monde 2D.
  * [ ] Prévisualisation "fantôme" (ghost preview) de la machine sous la souris, aimantée à la cellule ciblée.
  * [ ] Validation de placement : cellule libre, dans les limites de la grille, stock d'inventaire décrémenté.

---

## 4. Câblage Interactif & Raccordement

* [ ] **Rendu 2D des liaisons (`NetworkWire`)**
  * [ ] Représentation visuelle d'un câble via `Line2D`.
  * [ ] Définir la géométrie de tracé : connexion directe (port à port) ou routage orthogonal le long des axes de la grille.

* [ ] **Outil de tracé de câble**
  * [ ] Bouton d'activation du mode câblage (ou déclenchement intuitif par clic/tirer depuis un port réseau).
  * [ ] Ligne élastique temporaire suivant le curseur de la souris lors du tirage de câble.
  * [ ] Détection et aimantation sur le port cible d'une autre machine.
  * [ ] Validation de connexion : ports compatibles, non redondants, et instanciation du `NetworkWire` logique.

---

## 5. Visualisation des Flux Réseau en Simulation

* [ ] **Matérialisation des paquets en vol**
  * [ ] Composant visuel pour `NetworkPacket` (sprite compact, impulsion lumineuse ou forme vectorielle).
  * [ ] Interpolation de la position du paquet le long du chemin géométrique du câble en fonction du temps de transit.
  * [ ] Animation de consommation ou d'injection du paquet lors du passage dans les ports de machine.

* [ ] **Affichage des états d'erreur & Debug visuel**
  * [ ] Effet visuel lors de la destruction d'un paquet (expiration de TTL ou saturation de buffer).
  * [ ] Infobulle contextuelle au survol d'un paquet ou d'un câble pendant l'exécution (type, payload, destination).

---

## 6. Outils de Retrait & Gestion des États (Édition vs Simulation)

* [ ] **Machine à états du niveau (`LevelStateManager`)**
  * [ ] Définir les deux modes exclusifs : `EDIT_MODE` et `SIMULATION_MODE`.
  * [ ] Verrouillage strict des interactions de pose/déplacement/suppression lorsque la simulation tourne.
  * [ ] Contrôle de vitesse d'exécution (vitesse x1, avance rapide x2/x4, pause pas-à-pas).

* [ ] **Outil de suppression & Corbeille**
  * [ ] Action de suppression (clic droit contextuel ou outil dédié "Gomme / Ciseaux").
  * [ ] Suppression d'un câble : détachement des ports et nettoyage de l'instance.
  * [ ] Suppression d'une machine posée par le joueur : destruction automatique des câbles reliés et restitution au stock d'inventaire.
  * [ ] Interdiction formelle de suppression sur les machines marquées `is_locked`.

---

## 7. Interfaces de Configuration des Machines

* [ ] **Sélection et inspection contextuelle**
  * [ ] Clic de sélection sur une machine en mode édition pour ouvrir sa fiche de configuration.
  * [ ] Panneau UI dédié affichant les statistiques courantes (capacité du buffer, débit, règles).

* [ ] **Implémentation de nouveaux équipements spécialisés**
  * [ ] **Switch / Hub :** Acheminement vers tous les ports ou aiguillage selon table d'apprentissage MAC.
  * [ ] **Routeur :** Interface d'édition d'une table de routage simple (tables statiques).
  * [ ] **Firewall / Filtre :** Interface de définition de règles de filtrage (bloquer paquets d'un certain type ou origine).

---

## 8. Boucle Complète de Jeu, Validation & Reset

* [ ] **Gestionnaire de réinitialisation (Reset)**
  * [ ] Action Stop/Reset : arrêt de l'horloge, purge de tous les paquets en transit et vidage des buffers de machines.
  * [ ] Rétablissement instantané du niveau à son état statique d'édition, sans détruire les installations du joueur.

* [ ] **Évaluateur d'objectifs (`ObjectiveChecker`)**
  * [ ] Définition des conditions de victoire (ex: "X paquets délivrés au serveur cible sans perte").
  * [ ] Définition des conditions d'échec critique (ex: "Perte de paquet interdite", "Buffer overflow").
  * [ ] Affichage de l'écran de fin de niveau (succès avec métriques de performance ou échec explicatif).

---

## 9. Architecture de Données & Persistance (Format JSON)

* [ ] **Spécification du schéma JSON de définition de niveau**
  * [ ] Définition de la grille (colonnes, lignes, taille de cellule).
  * [ ] Liste des machines imposées (`is_locked == true`, position fixe, configuration d'usine).
  * [ ] Stock d'inventaire alloué au joueur pour ce niveau.
  * [ ] Conditions de validation et trafic source généré.

* [ ] **Chargeur de niveau (`LevelLoader`)**
  * [ ] Parser JSON qui instancie et positionne automatiquement la grille, les machines initiales et l'inventaire.

* [ ] **Système de sauvegarde de session joueur**
  * [ ] Sérialisation de l'état modifié par le joueur (machines ajoutées + câbles tracés).
  * [ ] Sauvegarde locale permettant de reprendre un puzzle entamé.
  * [ ] Option "Réinitialiser au départ du puzzle" pour recharger le JSON initial pur.

---

## 10. Contenu, Puzzles & Navigation Globale

* [ ] **Conception de la campagne de puzzles**
  * [ ] Niveaux tutoriels (familiarisation avec les câbles, latence, débits).
  * [ ] Niveaux intermédiaires (aiguillage, congestion, buffers limités).
  * [ ] Niveaux avancés (sécurité, routage multi-chemins, équilibrage de charge).

* [ ] **Système de menu et intégration finale**
  * [ ] Menu principal (Nouvelle partie, Continuer, Sélection de niveau).
  * [ ] Écran de sélection de puzzles avec indicateur de complétion/étoiles.
  * [ ] Menu pause en jeu et réglages audio/graphiques.