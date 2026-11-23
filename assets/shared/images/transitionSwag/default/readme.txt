Sticker transition art.

Picked in Options > Visuals > Transition > "Sticker". It only plays around songs
started from Freeplay; menus and Story Mode keep the normal fade.

Drop .png files in this folder (or in mods/<mod>/images/transitionSwag/default/) and
they become the stickers, used in file-name order. Up to 16 are shown per change.

Optional stickers.json, next to the images, to pick and order them:

{
	"name": "default",
	"artist": "",
	"stickers": ["one", "two", "three"]
}

Names are written without the .png extension. A mod's folder wins over this one.

Keep the PNGs small and cropped to the sticker itself: they are scaled to 0.35-0.75
of their own size and scattered randomly across the screen.

With no PNGs in the folder the transition does nothing and the state change happens
immediately, so an empty sticker set can never leave the game on a blank screen.
