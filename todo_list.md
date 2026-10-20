# Network Nightmare - Roadmap & Todo List

> État vérifié le 20/10/2026 sur la branche `connectionMode`, à partir du code présent
> et de l'historique Git jusqu'au commit `1a1995f`.

### Réalisations confirmées par l'historique

- `ea3b3ba` à `9f47bd6` : modèle réseau, câbles, devices, TTL et boucle de simulation.
- `0acffdc` à `730effb` : scène principale, caméra et contrôles UI reliés à la simulation.
- `775a5b8` : grille 2D, occupation des cellules et cadrage dynamique de la caméra.
- `4003c29` à `d2efbc8` : switch, receiver et logique d'apprentissage/routage.
- `7ccfdf9` à `b866036`, puis `d1ba169` et `a7aac3d` : inventaire, ressources de
  devices, textures, drag-and-drop et refactorisation.
- `e740a4c` et `1a1995f` : validation des ports et géométrie logique des câbles.
  Leur rendu et leur création interactive restent à faire.

## 1. Fondations & Socle Technique Réalisés

* [x] **Modèle de données abstrait**
  * [x] Classe de base `NetworkDevice` (`scripts/model/network_device.gd`).
  * [x] Modélisation logique des câbles `NetworkWire` (`network_wire.gd`).
  * [x] Modélisation des unités de données `NetworkPacket` (`network_packet.gd`).

* [x] **Moteur d'horloge et de simulation**
  * [x] Moteur `NetworkSimulation` (`scripts/simulation/network_simulation.gd`) avec boucle `_physics_process`.
  * [x] Enregistrement et mise à jour cyclique des équipements et des câbles.
  * [x] Gestion du cycle de vie et expiration des paquets éphémères (`ephemeral_packets` / TTL).
  * [x] Méthodes d'exécution (`start`, `stop`, `step`).

* [x] **Navigation spatiale 2D**
  * [x] Scène principale `Main.tscn` configurée avec limites d'affichage.
  * [x] Caméra panoramique avec translations et zoom (`pan_zoom_camera.gd`).

* [x] **Contrôle utilisateur & Orchestration de base**
  * [x] Scène `PuzzleUi.tscn` intégrée dans un `CanvasLayer` dédié.
  * [x] Boutons exclusifs de contrôle d'exécution : **Start** et **Stop** (`radio_button.gd`).
  * [x] Bouton d'aide et indices (**Hint**).
  * [x] Contrôleur d'interface `ui_puzzle_controller.gd` avec signaux découplés.
  * [x] Orchestration racine dans `Main.gd` reliant les signaux UI aux méthodes de `NetworkSimulation`.

---

## 2. Système Spatial : Grille & Coordonnées (Étape Immédiate)

* [x] **Composant `GridManager`**
  * [x] Définir la structure du gestionnaire de grille (taille de cellule paramétrable, ex: 64x64 px).
  * [x] Fonctions de conversion : `world_to_cell(pos)` et `cell_to_world_center(coord)`.
  * [x] Registre d'occupation des cellules (savoir quelle machine ou quel câble occupe quelle case).
  * [x] Rendu visuel de la grille 2D (lignes ou points discrets configurables selon la taille du niveau).
  * [x] Gestion du confinement de la caméra aux limites de la grille du niveau courant.
  * [x] Gestion dynamique du niveau de zoom.
  * [x] Gestion de la vitesse de déplacement en fonction du niveau de zoom.

---

## 3. Première Machine Concrète & Volet d'Inventaire

* [ ] **Socle 2D d'une machine concrète** *(partiellement réalisé)*
  * [x] Scène générique `NetworkDeviceView` avec `Sprite2D`, texture et liaison à la logique.
  * [x] Définition logique des ports réseau et de leurs contraintes par type de device.
  * [ ] Définition des connecteurs visuels avec ancrages locaux précis sur le sprite.
  * [ ] Distinction des états de persistance : `is_locked` (machine imposée par le puzzle) vs `is_editable` (placée par le joueur).

* [ ] **Volet latéral d'inventaire (UI rétractable)** *(partiellement réalisé)*
  * [x] Panneau latéral présent dans le `CanvasLayer` avec `ScrollContainer`.
  * [x] Structure de panneau repliable (`FoldableContainer`).
  * [x] Liste des équipements disponibles avec leurs icônes.
  * [ ] Afficher le nom et le compteur de stock restant par équipement.
  * [ ] Blocage des entrées de la caméra et du monde (`mouse_filter`) lorsque le curseur survole le volet.

* [ ] **Mécanique de placement sur la grille** *(partiellement réalisé)*
  * [x] Drag & drop depuis l'inventaire vers la grille.
  * [ ] Prévisualisation fantôme aimantée à la cellule ciblée (le drag preview actuel n'est pas une prévisualisation dans le monde).
  * [x] Validation de la cellule libre et des limites de la grille.
  * [ ] Décrémenter et restaurer le stock d'inventaire.

---

## 4. Câblage Interactif & Raccordement

* [ ] **Rendu 2D des liaisons (`NetworkWire`)** *(partiellement réalisé)*
  * [ ] Représentation visuelle d'un câble via `Line2D`.
  * [x] Modèle logique du câble avec points clés, longueur et cases occupées.
  * [ ] Définir et afficher le tracé direct ou orthogonal dans la scène.

* [ ] **Outil de tracé de câble** *(partiellement réalisé côté données)*
  * [ ] Bouton d'activation du mode câblage (ou déclenchement intuitif par clic/tirer depuis un port réseau).
  * [ ] Ligne élastique temporaire suivant le curseur de la souris lors du tirage de câble.
  * [ ] Détection et aimantation sur le port cible d'une autre machine.
  * [x] Validation logique des ports compatibles, des collisions et des limites d'E/S.
  * [x] Construction logique d'un `NetworkWire` avec occupation des cases.
  * [ ] Brancher cette logique à une interaction utilisateur et l'enregistrer dans la simulation.

---

## 5. Visualisation des Flux Réseau en Simulation

* [ ] **Matérialisation des paquets en vol**
  * [ ] Composant visuel pour `NetworkPacket` (sprite compact, impulsion lumineuse ou forme vectorielle).
  * [x] Simulation logique du transit, de la vitesse, de l'espacement et de la livraison au device cible.
  * [ ] Interpolation visuelle de la position le long du chemin géométrique.
  * [ ] Animation de consommation ou d'injection du paquet lors du passage dans les ports de machine.

* [ ] **Affichage des états d'erreur & Debug visuel** *(partiellement réalisé)*
  * [x] Signal logique de paquet rejeté et feedback rouge temporaire sur la vue du device.
  * [ ] Effet visuel dédié lors de l'expiration TTL ou d'une saturation de buffer.
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
  * [x] **Switch / Hub :** Aiguillage MAC, broadcast et apprentissage implémentés dans `NetworkSwitch`.
  * [ ] Ajouter l'interface de configuration et l'affichage de la table MAC.
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