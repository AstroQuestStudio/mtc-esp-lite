# Infinite Yield — ESP compact v4.2

Le **rendu des boîtes original d’Infinite Yield** est conservé pour tous les occupants : taille et transparence d’origine, vraies couleurs d’équipe. Seuls quelques textes sont affichés, selon la distance et le centre de la caméra. Les grands déplacements d’étiquettes et tous les traits de liaison de v4.1 sont supprimés. Police SourceSansSemibold, contour noir, taille 20 pour les ennemis proches et 16 pour les alliés/ennemis lointains. Les cadres écran, onglets et effets de visibilité des anciennes versions ne sont pas chargés.

## Commande

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstroQuestStudio/mtc-esp-lite/v4.2.0/mtc-esp.client.lua"))()
```

L’ESP démarre automatiquement. Cette version contient le script Infinite Yield d’origine avec son interface et ses commandes, plus la modification ciblée de son ESP. Il ne s’agit plus de l’interface indépendante MTC Volumes.

## Texte affiché

**Allié :** `Ast`, uniquement, dans la couleur de son équipe. Pas de santé, de lettre A ou de distance.

**Ennemi proche :** `Ast | H85% | E | 240 st`.

**Ennemi lointain :** `Ast | H85% | E | 3.0k st`.

À pleine santé, le champ `H100%` disparaît : `Ast | E | 240 st`. Il réapparaît pour la cible retenue au centre de la caméra. Une santé inférieure à 100 % reste affichée pour tout ennemi dont l’étiquette est retenue.

- **Ast** : les trois premiers caractères du nom de compte Roblox ; un nom plus court est conservé tel quel.
- **H85%** : santé actuelle divisée par la santé maximale, arrondie et bornée entre 0 et 100 %. Une santé maximale nulle donne 0 %.
- **E** : ennemi. La lettre prend **la couleur réelle de l’équipe du joueur affiché**, identique à celle de ses boîtes : bleu, jaune, vert, rouge, etc. Elle n’est pas forcée au rouge ou au vert. La relation suit Player.Team lorsque les deux joueurs ont une équipe active, avec repli sur la comparaison TeamColor d’Infinite Yield si ces données manquent.
- **240 st** : distance en studs depuis le personnage local, arrondie vers le bas comme dans l’original en dessous de 1 000 studs. Au-delà, abréviation à une décimale en milliers : `3.0k st`, `3.1k st`, etc. La santé suit la règle ci-dessus, même à longue distance.

Pour les ennemis, nom, santé, séparateurs et distance restent blancs avec contour noir ; seule la lettre E est colorée. Les alliés n’affichent que leur nom abrégé coloré. La largeur des étiquettes s’adapte à leur contenu.

## Priorités : boîtes pour tous, peu de texte

La capture de v4.1 montrait que déplacer toutes les étiquettes vers des places libres remplissait le premier plan de textes concernant des joueurs très lointains. V4.2 limite l’information plutôt que de remplir l’écran.

- Au maximum **6 étiquettes ennemies**, triées par proximité après la cible retenue au centre de la caméra.
- Parmi elles, au maximum **2 ennemis au-delà de 1 500 studs**. S’il n’y a que des ennemis très lointains, seuls les deux plus proches peuvent donc avoir du texte.
- Au maximum **2 pseudos alliés**, uniquement à moins de 450 studs.
- Un ennemi proche du centre de la caméra peut prendre une des six places même s’il est très lointain. Il est retenu après environ 0,18 seconde de stabilité, avec une zone de relâchement plus large et un seuil de changement pour éviter les bascules permanentes. Le rayon dépend de la taille de l’écran, entre 36 et 90 pixels. C’est un choix d’affichage depuis la caméra, pas une vérification de ligne de vue ou un système d’assistance à la visée.
- Les boîtes des autres occupants restent affichées, à leur position réelle. Aucun regroupement d’équipage, aucune boîte déplacée.

Les étiquettes retenues sont essayées seulement au-dessus ou juste à côté de leur tête : au plus 12 pixels horizontalement et une ligne verticalement autour de la position initiale. Aucun déport de plusieurs centaines de pixels. Si deux textes se gênent encore, le texte de moindre priorité est masqué. Les nombres ci-dessus sont des plafonds, pas une promesse de toujours afficher huit textes.

Le tri est réévalué environ 12,5 fois par seconde ; les BillboardGui continuent leur suivi 3D natif entre les placements. Des chevauchements transitoires peuvent apparaître pendant un mouvement très rapide avant la mise à jour suivante. Les dimensions utilisent TextBounds quand disponibles, sinon une estimation prudente. Les têtes hors champ et l’absence du personnage local masquent les étiquettes.

Les seuils sont regroupés dans la table locale `labelPolicy` du script : ennemis 6, alliés 2, portée alliée 450, seuil lointain 1500, maximum lointain 2. Le menu d’Infinite Yield reste celui d’origine.

## Commandes Infinite Yield conservées

- `;esp` : activer les boîtes et les étiquettes.
- `;noesp` : retirer l’ESP.
- `;esptransparency 0.3` : régler la transparence des boîtes via le réglage original.
- `;espteam` : conserve également les vraies couleurs des équipes dans cette version, au lieu de forcer vert/rouge.

Le préfixe peut différer si vous avez personnalisé les réglages d’Infinite Yield. Les boîtes suivent le fonctionnement original : toutes les BasePart directement sous le personnage, y compris HumanoidRootPart, AlwaysOnTop, ZIndex 10, taille de la pièce et transparence chargée par Infinite Yield (0,3 par défaut). Les collisions du jeu ne sont pas modifiées.

## Remplacement d’une ancienne instance

Le chargeur arrête d’abord une ancienne instance MTC Volumes et restaure son éventuel mode graphique. Si Infinite Yield est déjà chargé et expose ses fonctions attendues, il remplace sa fonction ESP puis relance l’affichage. Il laisse une image aux anciennes connexions pour se déconnecter avant la relance.

Si l’environnement ne permet pas d’accéder aux fonctions de l’instance déjà chargée, un message demande de rejoindre une nouvelle partie puis de lancer cette commande avant l’autre Infinite Yield. Le script ne contourne pas silencieusement la protection contre les doublons.

## Validation et limites

- Script complet compilé avec le compilateur officiel Luau 0.743.
- Vérification que le corps d’Infinite Yield reste identique au dépôt cloné, hors fonction ESP modifiée, son formateur de texte et la description de espteam. Le préambule de remplacement et l’activation automatique sont ajoutés autour de ce corps.
- Tests Fengari avec API Roblox simulées : boîtes d’origine, texte attaché à la tête, police et contour, format à trois caractères, santé 0–100 % et MaxHealth nul, noms courts, relation allié/ennemi, dix couleurs d’équipe identiques entre lettre et boîtes, respawn, changements d’équipe, distance, espteam, nettoyage noesp, mise à jour d’une instance existante et repli si ses fonctions sont inaccessibles.
- Scénario de congestion : 46 occupants à plus de 3 000 studs au même endroit à l’écran, réduits aux deux textes ennemis les plus proches ; toutes les boîtes conservées, aucun trait et aucun texte déplacé dans le premier plan. Vérification des intersections, stabilité, mouvement de caméra et petit écran.
- Rencontre rapprochée : plafonds de six ennemis et deux alliés proches, insertion d’une cible lointaine au centre, remplacement par un ennemi plus proche, relâchement/reprise du focus avec délai et hystérésis, santé à 100 % masquée sauf sur le focus et santé endommagée conservée. Nettoyage du coordinateur après noesp.

**Pas de test dans Roblox, Xeno ou MTC depuis cet environnement.** La compilation et les tests simulés ne valident pas le rendu réel ni toutes les fonctions d’Infinite Yield. La détection des camps repose sur les équipes Roblox et le comportement de repli décrit ci-dessus, sans connaissance des factions propres à MTC. Aucun état de visibilité ou de pénétration n’est affiché. Les autres fonctions d’Infinite Yield restent celles du dépôt d’origine et n’ont pas été exécutées pour ces tests.

## Origine

Basé sur [EdgeIY/infiniteyield](https://github.com/EdgeIY/infiniteyield), révision `4c1f7f349ea23191733ce91eec174d5302b2b2d8`. Le bloc ESP original commence à `source:5726` dans cette révision. Attribution et licence MIT : `LICENSE` dans le dépôt et `LICENSE-InfiniteYield.txt` dans le pack.

Documentation RichText vérifiée avec Context7 : [TextLabel.RichText](https://create.roblox.com/docs/reference/engine/classes/TextLabel#RichText).
