# Infinite Yield — ESP compact v4

Retour au **rendu ESP original d’Infinite Yield** : BoxHandleAdornment sur les parties du personnage, texte au-dessus de la tête, police SourceSansSemibold taille 20 et contour noir. Les cadres écran, onglets et effets de visibilité des versions précédentes ne sont plus chargés.

## Commande

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstroQuestStudio/mtc-esp-lite/v4.0.0/mtc-esp.client.lua"))()
```

L’ESP démarre automatiquement. Cette version contient le script Infinite Yield d’origine avec son interface et ses commandes, plus la modification ciblée de son ESP. Il ne s’agit plus de l’interface indépendante MTC Volumes.

## Texte affiché

`Ast | H85% | E | 240 st`

- **Ast** : les trois premiers caractères du nom de compte Roblox ; un nom plus court est conservé tel quel.
- **H85%** : santé actuelle divisée par la santé maximale, arrondie et bornée entre 0 et 100 %. Une santé maximale nulle donne 0 %.
- **A / E** : allié / ennemi. La lettre prend **la couleur réelle de l’équipe du joueur affiché**, identique à celle de ses boîtes : bleu, jaune, vert, rouge, etc. Elle n’est pas forcée au rouge ou au vert. La relation suit Player.Team lorsque les deux joueurs ont une équipe active, avec repli sur la comparaison TeamColor d’Infinite Yield si ces données manquent.
- **240 st** : distance en studs depuis le personnage local, arrondie vers le bas comme dans l’original.

Nom, santé, séparateurs et distance restent blancs avec contour noir. Seule la lettre A/E est colorée dans le texte. La zone de texte est élargie à 250 pixels pour contenir le format compact.

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
- Tests Fengari avec API Roblox simulées : rendu d’origine (boîtes, tête, police, contour, transparence), format à trois caractères, santé 0–100 % et MaxHealth nul, noms courts, relation A/E, dix couleurs d’équipe identiques entre lettre et boîtes, respawn, changements d’équipe, distance, espteam, nettoyage noesp, mise à jour d’une instance existante et repli si ses fonctions sont inaccessibles.

**Pas de test dans Roblox, Xeno ou MTC depuis cet environnement.** La compilation et les tests simulés ne valident pas le rendu réel ni toutes les fonctions d’Infinite Yield. La détection des camps repose sur les équipes Roblox et le comportement de repli décrit ci-dessus, sans connaissance des factions propres à MTC. Aucun état de visibilité ou de pénétration n’est affiché. Les autres fonctions d’Infinite Yield restent celles du dépôt d’origine et n’ont pas été exécutées pour ces tests.

## Origine

Basé sur [EdgeIY/infiniteyield](https://github.com/EdgeIY/infiniteyield), révision `4c1f7f349ea23191733ce91eec174d5302b2b2d8`. Le bloc ESP original commence à `source:5726` dans cette révision. Attribution et licence MIT : `LICENSE` dans le dépôt et `LICENSE-InfiniteYield.txt` dans le pack.

Documentation RichText vérifiée avec Context7 : [TextLabel.RichText](https://create.roblox.com/docs/reference/engine/classes/TextLabel#RichText).
