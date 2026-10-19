# MTC ESP Lite

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
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstroQuestStudio/mtc-esp-lite/main/mtc-esp.client.lua"))()
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
