// Character script for characters/<name>.hx (data/characters/<name>.hx works too)
//
// `character` is the Character object that loaded this file, `characterName` is its
// name. Like any song script it also gets onUpdate/onStepHit/onEvent; only the three
// hooks below are sent to the one character that loaded the file.

function onCreate()
{
	// character.playAnim('idle', true);
}

function onDance()
{
	// The character is about to play its idle/dance animation
}

function onPlayAnim(anim:String, forced:Bool)
{
	// Called before an animation starts playing
	// anim: the animation name, forced: true when it was played with Force
}

function onGetCamPos()
{
	// Return the camera offset for this character, or null to keep the JSON one
	// return FlxPoint.get(100, -50);
	// return {x: 100, y: -50};
	return null;
}
