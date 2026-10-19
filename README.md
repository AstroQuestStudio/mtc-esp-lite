# MTC ESP Lite v2.1

## Correction v2.1 : visibilité des occupants de chars

Option activée par défaut : **Dans un char : visibilité du véhicule**. Pour un joueur assis, les raycasts visent le siège et la racine de son assemblage. Une première collision avec son siège, une pièce du même assemblage physique ou du petit modèle de véhicule déduit est considérée comme dégagée. La coque du char ne rend donc plus systématiquement son équipage sombre. Un mur, le terrain ou un autre véhicule qui intervient avant reste bloquant.

Le modèle est déduit du plus proche ancêtre Model commun au siège et à sa racine physique ; les personnages et modèles dont la diagonale dépasse 250 studs sont exclus. Si aucun modèle fiable n’est obtenu, seule l’identité de l’assemblage et du siège est utilisée. Cela reste une détection générique à vérifier dans MTC ; un véhicule dont toutes les pièces sont indépendantes peut être détecté seulement en partie. Deux points de test ne couvrent pas toute la silhouette d’un char partiellement visible.

Le repère indique **véhicule visible**, pas équipage exposé ou blindage pénétrable. Les boîtes restent celles des personnages. Désactiver cette option rétablit le test tête/torse de v2. Sortir du siège rétablit automatiquement le test du personnage. L’option d’ancrage du repère au siège est indépendante.

## Nouveautés v2 : boîtes, visibilité et performances

**Boîtes des personnages.** Volumes translucides calés sur les dimensions des parties du corps, accessoires et HumanoidRootPart exclus. Ce sont des repères visuels : les collisions ne changent pas, et les zones de dégâts propres au serveur ne sont pas connues.

**Visibilité.** La tête et le centre du personnage sont testés par raycast depuis la caméra. Couleur vive si au moins un point est dégagé ; couleur sombre si les deux sont bloqués, si le test est en attente ou si son résultat est périmé. Une option masque tous les personnages sans ligne de vue dégagée. La distance reste en studs, sans nom à l’écran.

Il s’agit de visibilité depuis **la caméra**, pas d’une promesse de tir possible : origine du canon, trajectoire d’obus, blindage, pénétration et dégâts ne sont pas calculés. Vitres, objets transparents, fumée, pièces non interrogeables et streaming peuvent produire une différence avec les tirs réels. Le char local n’est pas automatiquement exclu des raycasts.

**Charge de l’ESP bornée.** Repères uniquement à l’écran, parmi les joueurs les plus proches. Maximum réglable 12 / 24 / 48, initialement 24. Boîtes limitées à 12 personnages et 16 parties par personnage. Maximum de 24 raycasts par actualisation ; les vérifications tournent entre les joueurs, avec un résultat conservé au plus 0,9 seconde. Un mouvement rapide peut donc créer un court retard d’indication.

**Performances réversibles.** Le bouton fait défiler :

| Mode | Effets sur les graphismes | Charge ESP |
| --- | --- | --- |
| NORMAL | Graphismes d’origine | 10 actualisations/s, au plus 24 raycasts/actualisation |
| LÉGER | Ombres globales, Bloom, Blur, DepthOfField et SunRays désactivés | 5 actualisations/s, au plus 12 raycasts/actualisation, 12 repères et 6 personnages avec boîtes |
| FORT | Réductions précédentes ; ParticleEmitter, Trail, Beam, Fire, Smoke, Sparkles et ombres des lumières désactivés | Mêmes limites que LÉGER |

**FORT retire aussi les fumées, explosions et traînées produites par ces objets.** Cet effet est indiqué dans le menu. D’autres effets propres au jeu peuvent rester actifs. Le mode initial est NORMAL.

Le parcours de la scène et le traitement des nouveaux objets sont progressifs : au plus 80 objets et une fenêtre de travail de 1,5 ms par Heartbeat. Cette fenêtre limite le travail entre objets ; elle ne garantit pas la durée d’un appel moteur ni le temps total d’une image. Aucun balayage GetDescendants à chaque image, aucune destruction de carte, aucune modification des collisions, textures ou matériaux.

Retour à NORMAL, arrêt ou relance : les anciennes propriétés sont restaurées. Si le jeu les a modifiées entre-temps vers une autre valeur, sa nouvelle valeur est conservée. Les effets détruits sont retirés du suivi pour ne pas retenir les émetteurs des explosions. Le script ne force pas continuellement une propriété que le jeu réactive.

**Mesure locale.** Le panneau affiche sur environ deux secondes les FPS issus des images rendues, la durée de la pire image et le nombre d’images d’au moins 50 ms. Il ne mesure pas le ping. Comparer NORMAL / LÉGER / FORT dans une même scène permet d’observer l’effet sur votre machine.

Aucun gain de FPS n’est garanti : ces réglages visent le rendu client. Ils ne corrigent pas les scripts ou la physique du serveur, le réseau ou tous les pics de streaming.

**Recherche MTC.** La [page officielle](https://www.roblox.com/games/95721658376580/Multicrew-Tank-Combat), consultée le 19 octobre 2026, confirme le jeu Top Giun et les rôles commandant, tireur, conducteur et chargeur. Elle ne documente pas les structures des chars, factions, zones de dégâts ou règles balistiques. Aucun chemin d’objet ou RemoteEvent propre à MTC n’a été inventé. Les chars vides et les modules de blindage ne sont pas détectés.

**Validation v2.** Syntaxe vérifiée avec luaparse, logique exécutée sous Fengari avec API Roblox simulées. Tests : lignes de vue dégagées/bloquées/partielles, obstruction par un autre personnage, filtre de visibilité, retrait hors écran, tailles des boîtes, plafonds avec plus de 60 joueurs, modes graphiques, nouveaux objets, effets détruits, restauration, conservation des changements du jeu, collisions inchangées, traitement progressif, compteur d’images et nettoyage à la relance. Les tests de la v1 restent inclus. **Aucun test Roblox/Xeno/MTC ni gain réel de FPS mesuré depuis cet environnement.** Résultats : `VALIDATION.txt`.

Documentation supplémentaire vérifiée avec Context7 : [Raycasts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Raycast), [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams), [BoxHandleAdornment](https://create.roblox.com/docs/reference/engine/classes/BoxHandleAdornment), [optimisation Roblox](https://create.roblox.com/docs/performance-optimization/improve).

Les sections suivantes décrivent l’origine du projet et les contrôles conservés de la v1. En v2, l’actualisation passe à 5 Hz dans les modes performances et les repères hors écran sont exclus.

Version autonome centrée sur l’ESP, écrite après examen du dépôt [EdgeIY/infiniteyield](https://github.com/EdgeIY/infiniteyield), cloné dans `work/infiniteyield`.

Révision examinée : `4c1f7f349ea23191733ce91eec174d5302b2b2d8`.
Dans cette révision : `source:5726` définit ESP, `source:8098` enregistre `esp`, `source:8111` enregistre `espteam`.

## Fonctionnement de l’original

`esp` pose un BoxHandleAdornment sur chaque partie du personnage et un BillboardGui sur sa tête. Il actualise nom, santé et distance à chaque RenderStepped. `espteam` compare TeamColor : même couleur = vert, sinon rouge. Des événements recréent les repères après respawn et changement d’équipe.

## Cette version

- Repère : distance seule, en studs (`st`), sans nom ni santé.
- Alliés bleus, ennemis rouges, équipe inconnue grise.
- Détection automatique par Player.Team, uniquement si les deux joueurs ont une équipe et ne sont pas neutres.
- Choix par joueur : AUTO → ALLIÉ → ENNEMI → MASQUÉ. Le nom de compte apparaît uniquement dans la liste pour sélectionner la bonne personne.
- Filtres par catégorie, recherche dans la liste et portée 500 / 1500 / 3000 / illimitée.
- Distance calculée depuis le personnage local. Aucune conversion inventée en mètres.
- Repère sur le siège quand un joueur est assis ; option désactivable.
- Silhouette optionnelle du personnage, désactivée par défaut ; visibilité à travers les obstacles réglable.
- Actualisation à 10 Hz, suivi des respawns et changements d’équipe, suppression à la sortie des joueurs.
- Bouton d’arrêt complet et nettoyage de l’ancienne instance à la relance.
- Réglages conservés uniquement pendant la session du script.

## Utilisation

Le fichier à utiliser est **mtc-esp.client.lua**. Il remplace le chargement du script Infinite Yield complet. Il ne fournit pas sa console ni ses commandes `;esp`.

Chargement depuis le dépôt GitHub public :

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstroQuestStudio/mtc-esp-lite/main/mtc-esp.client.lua?v=2.1"))()
```

Dans votre propre expérience Studio, placez son contenu dans un **LocalScript** sous **StarterPlayer > StarterPlayerScripts**, puis lancez Play avec plusieurs clients pour vérifier les équipes.

Si votre environnement client dispose déjà de `loadstring` et de lecture de fichiers, chargez le fichier local avec :

```lua
loadstring(readfile("mtc-esp.client.lua"))()
```

`readfile` n’est pas une API standard Roblox. Votre ancienne URL EdgeIY charge toujours Infinite Yield d’origine.

- **Insert** ou bouton **ESP / MENU** : ouvrir / fermer le panneau.
- **F8** : activer / désactiver l’affichage.
- Mobile : bouton de menu et contrôles tactiles ; panneau défilant adapté à la taille d’écran.
- Pour retirer une instance Infinite Yield déjà chargée, utiliser ses commandes `;noesp` et `;nochams` avant d’utiliser cette version, afin d’éviter les repères superposés.

## Limites et vérification

La capture identifie le jeu **[MTC] Multicrew Tank Combat**. Son code et son modèle de véhicules n’ont pas été fournis : il ne s’agit pas d’une intégration MTC validée en jeu.

Le script utilise uniquement les personnages, équipes et sièges disponibles sur le client. Il ne détecte pas les chars vides, ne déduit pas l’équipe d’un véhicule et ne marque pas l’ensemble du char. Plusieurs occupants d’un même char peuvent produire des repères rapprochés. Si MTC utilise des factions personnalisées plutôt que Player.Team, employer les choix manuels.

Les personnages non répliqués par le streaming ne peuvent pas être affichés. Les silhouettes dépendent des limites de rendu de Roblox. Un personnage local absent suspend les distances ; les personnages morts ne reçoivent pas de repère.

Validation locale : voir VALIDATION.txt. Aucun essai dans Roblox/MTC n’a été réalisé depuis cet environnement.

Documentation API vérifiée avec Context7 : [BillboardGui](https://create.roblox.com/docs/reference/engine/classes/BillboardGui), [Highlight](https://create.roblox.com/docs/reference/engine/classes/Highlight), [Teams](https://create.roblox.com/docs/reference/engine/classes/Teams), [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid).

Licence et attribution Infinite Yield : **LICENSE-InfiniteYield.txt**.
