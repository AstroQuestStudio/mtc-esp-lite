# MTC Volumes v3

ESP client centré sur **chaque occupant** : cadres contrastés, volumes des membres à proximité et distance en studs. Aucun regroupement des équipages par char, aucune liste de joueurs, aucune affectation manuelle des camps.

## Chargement

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstroQuestStudio/mtc-esp-lite/v3.0.0/mtc-esp.client.lua"))()
```

Cette commande charge la version v3.0.0 pour éviter une copie périmée de la branche main dans les caches. Relancer le script supprime l’ancienne instance et restaure les réglages graphiques qu’elle avait modifiés. Le fichier `loader.lua` contient la commande.

Ce chargement dépend des fonctions fournies par l’environnement client. Pour votre propre expérience Studio, copier le contenu de `mtc-esp.client.lua` dans un LocalScript sous **StarterPlayer > StarterPlayerScripts** et tester avec plusieurs clients.

## Ce qui change en v3

- **Un cadre par personne**, à pied ou assise dans un véhicule. Deux occupants proches restent deux repères distincts.
- Cadre écran calculé à partir du volume des parties du corps, dans l’orientation du HumanoidRootPart. Accessoires, HumanoidRootPart et pièces du véhicule exclus de ces dimensions.
- Contour en pixels pour rester lisible à distance, doublé d’une bordure sombre ; remplissage léger coloré.
- Deux styles : **PLEIN** ou **ANGLES**. Trois contrastes : **FIN**, **NET**, **FORT**.
- Distance dans une pastille sombre indépendante. Les pastilles qui se chevauchent sont décalées dans la limite de six emplacements candidats ; les occupants ne sont jamais fusionnés. Les regroupements extrêmement denses peuvent encore produire des superpositions.
- **Détails à proximité** : volumes translucides des membres à moins de 180 studs, option désactivable. Jusqu’à 12 occupants détaillés en NORMAL, 6 en mode performances ; au plus 16 parties par occupant.
- Équipes automatiques : bleu allié, rouge ennemi, gris inconnu. Aucun nom, aucune santé et aucune liste de joueurs à l’écran ou dans le menu.
- Distance calculée depuis le personnage local vers le personnage concerné, y compris lorsqu’il est assis.

Les cadres représentent des volumes visuels, pas nécessairement les zones de dégâts du serveur. Le script ne redimensionne pas les collisions physiques.

## Menu refait

Panneau sombre avec état de l’ESP, compteur d’occupants et deux onglets :

**AFFICHAGE** : ESP actif, cadres, distance, style, contraste, détails proches, affichage à travers les obstacles, portée et maximum de repères.

**PERFORMANCES** : choix direct entre NORMAL, LÉGER et FORT, compteur FPS/pire image/pics d’images, état des réductions graphiques.

- **Insert** : ouvrir / réduire le menu.
- **F8** : activer / désactiver l’ESP ; le mode graphique choisi reste actif.
- **MTC / MENU** : bouton tactile pour ouvrir / réduire le panneau.
- **Arrêter** : supprimer l’ESP et le menu, déconnecter ses événements et restaurer ses réglages graphiques.
- Le panneau s’adapte à la largeur et la hauteur de l’écran ; chaque onglet défile indépendamment. Les réglages sont limités à la session du script.

Les anciens filtres par catégorie, choix manuels de camp, liste, recherche de joueurs et surbrillances Highlight ont été retirés. Aucun analyseur ni nouveau système de visibilité à trois états n’a été ajouté.

## Visibilité existante conservée

La logique de v2.1 reste utilisée : test de tête/centre pour un personnage à pied ; test du siège et de la racine d’assemblage pour un occupant assis. Pour ce dernier, une première collision avec son propre siège, son assemblage ou le petit modèle de véhicule déduit est considérée comme dégagée. Un mur, le terrain ou un autre véhicule devant reste bloquant.

Le modèle est déduit du plus proche ancêtre Model commun au siège et à sa racine physique ; les personnages et les modèles dont la diagonale dépasse 250 studs sont exclus. Sans modèle identifié, seul le siège ou l’assemblage physique est accepté. La structure réelle des chars MTC doit encore être vérifiée en jeu.

Le cadre conserve une couleur vive si le test est dégagé, plus sombre sinon ou si la mesure est en attente/périmée. **Voir à travers** permet de conserver les cadres masqués ; si désactivé, les cadres sans ligne de vue dégagée sont retirés. Cette indication concerne la caméra, pas le canon, la pénétration du blindage ou les dégâts. Transparences, fumée, pièces non interrogeables, trajectoires et streaming peuvent créer des différences avec les tirs réels.

Les vérifications tournent entre les occupants ; un résultat est conservé au maximum 0,9 seconde. Il peut donc y avoir un court retard après un mouvement de caméra ou d’obstacle. Aucun nouveau statut « partiellement visible » n’est introduit en v3.

## Performances et limites de charge

| Mode | Réductions graphiques | Charge ESP |
| --- | --- | --- |
| NORMAL | Graphismes du jeu | 10 actualisations logiques/s, au plus 24 raycasts/actualisation ; plafond de repères réglable 12/24/48 |
| LÉGER | Ombres globales, Bloom, Blur, DepthOfField, SunRays désactivés | 5 actualisations logiques/s, au plus 12 raycasts/actualisation, 12 repères et 6 occupants détaillés |
| FORT | Réductions précédentes, plus ParticleEmitter, Trail, Beam, Fire, Smoke, Sparkles et ombres des lumières désactivés | Mêmes limites que LÉGER |

**FORT retire aussi les fumées, explosions et traînées produites par ces objets.** C’est indiqué dans le menu. Le mode initial est NORMAL.

Le scan graphique est progressif : au plus 80 objets et une fenêtre de traitement de 1,5 ms par Heartbeat. Cette fenêtre borne le travail entre objets, sans garantir la durée d’un appel moteur individuel ni le temps total d’une image. Les propriétés sont mémorisées, puis restaurées au retour à NORMAL, à l’arrêt ou à la relance. Si le jeu a changé une propriété vers une autre valeur entre-temps, sa nouvelle valeur est conservée. Les effets détruits sont retirés du suivi. Le script ne force pas continuellement la désactivation d’un effet réactivé par le jeu.

Les cadres utilisent huit coins en cache par occupant et suivent la caméra à la cadence du rendu. Le calcul des dimensions du corps est rafraîchi séparément à fréquence limitée ; aucun parcours de scène n’est effectué à chaque image. Les formes posées peuvent donc avoir un léger retard lors d’un changement de pose, tandis que le déplacement global et la caméra restent suivis à chaque image. Les poses animées, accessoires et différences de structure peuvent limiter la précision visuelle.

Les repères sont sélectionnés parmi les occupants les plus proches dont le centre est à l’écran. Les cadres passant derrière le plan proche de la caméra sont masqués pour éviter les rectangles géants/inversés. Les personnages morts ou non répliqués par le streaming ne sont pas affichés ; sans personnage local, les distances sont suspendues. Les chars vides ne sont pas détectés.

La mesure du panneau porte sur environ deux secondes d’images rendues : FPS calculés, pire image et nombre d’images d’au moins 50 ms. Ce n’est pas une mesure du ping. Aucun gain chiffré n’est garanti ; les modes ne corrigent pas le réseau, les scripts/physique du serveur ou tous les pics de streaming. Le plafond de 48 cadres augmente le travail de projection ; réduire ce plafond ou couper les détails proches peut aider sur une machine limitée.

## Validation

Syntaxe vérifiée avec luaparse ; comportement exécuté sous Fengari avec API Roblox simulées. Les scénarios couvrent :

- Cadres distincts par occupant, distance, camps automatiques et changements d’équipe, absence de liste et de commandes par joueur.
- Onglets, ouverture/réduction, Insert/F8, styles plein/angles, trois contrastes et bascules indépendantes cadres/distance/détails.
- Suivi du déplacement à cadence de rendu, orientation des volumes, exclusion des accessoires, évolution des parties du corps, retrait hors écran et au plan proche.
- Portée, respawn, décès, absence du personnage local, visibilité existante à pied et assis, obstacles et rejet des modèles trop grands.
- Arrivée/départ des joueurs, pastilles de distance séparées sur des occupants superposés et taille constante du menu malgré le nombre de joueurs.
- Préréglages graphiques, nouveaux effets et effets détruits, restauration, changements du jeu conservés, collisions inchangées.
- Plus de 60 occupants simulés, plafonds de repères/raycasts, traitement progressif, compteur d’images et nettoyage à la relance.

**Aucun essai visuel dans Roblox, Xeno ou MTC, ni gain réel de FPS mesuré depuis cet environnement.** Les tests simulés ne valident pas le rendu réel ni la structure interne de MTC. Résultats détaillés : `VALIDATION.txt`.

## Origine et documentation

Version autonome écrite après examen de [EdgeIY/infiniteyield](https://github.com/EdgeIY/infiniteyield), révision `4c1f7f349ea23191733ce91eec174d5302b2b2d8`. `source:5726` définit ESP, `source:8098` enregistre esp, `source:8111` enregistre espteam. L’original pose des BoxHandleAdornment et un BillboardGui avec nom/santé/distance. Cette version conserve le principe des repères client et remplace la console complète par une interface spécialisée.

La [page officielle de MTC](https://www.roblox.com/games/95721658376580/Multicrew-Tank-Combat) identifie le jeu de Top Giun et ses rôles d’équipage, sans documenter sa hiérarchie interne ou ses zones de dégâts. Aucun chemin de modèle ou RemoteEvent spécifique au jeu n’a été inventé.

API vérifiées via Context7 : [UIStroke](https://create.roblox.com/docs/reference/engine/classes/UIStroke), [Camera](https://create.roblox.com/docs/reference/engine/classes/Camera), [CFrame](https://create.roblox.com/docs/reference/engine/datatypes/CFrame), [BoxHandleAdornment](https://create.roblox.com/docs/reference/engine/classes/BoxHandleAdornment), [Raycasts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Raycast), [Assemblages](https://create.roblox.com/docs/reference/engine/classes/BasePart#AssemblyRootPart).

Licence MIT et attribution Infinite Yield : `LICENSE` dans le dépôt ; `LICENSE-InfiniteYield.txt` dans le pack.
