// State change transitions
//
// A .hx file in data/transitions/ shows up in Options > Visuals > "Transition:".
// The engine opens it as a substate on every state change: `trans` is that substate,
// so add your visuals to it. The same script runs twice per change, once with
// isTransIn == false while the old state is still up (the switch happens when the
// transition ends) and once with isTransIn == true after the new state exists.
//
// The engine ends the transition after `trans.duration` seconds. Set it to -1 to
// time it yourself and call trans.finish() when the switch may happen.

var bar:FlxSprite;

function onCreate()
{
	trans.duration = -1;

	bar = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
	bar.scale.set(FlxG.width, FlxG.height);
	bar.updateHitbox();
	bar.scrollFactor.set();
	bar.x = 0;

	// Sit off screen while leaving, cover the screen while entering
	bar.y = trans.isTransIn ? 0 : -FlxG.height;
	trans.add(bar);

	FlxTween.tween(bar, {y: trans.isTransIn ? FlxG.height : 0}, 0.35, {
		ease: FlxEase.quadInOut,
		onComplete: function(twn:FlxTween) {
			trans.finish();
		}
	});
}

function onUpdate(elapsed:Float)
{
	// Optional, called every frame while the transition runs
}

function onFinish()
{
	// Optional, called right before the transition closes
}
