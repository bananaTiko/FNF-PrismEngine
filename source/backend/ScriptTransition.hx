package backend;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript;

/**
 * A state change transition driven by a script in `data/transitions/`, picked with
 * `ClientPrefs.data.transition` (Options > Visuals > "Transition:").
 *
 * The script gets the substate itself as `trans`, plus `isTransIn`, and adds its own
 * visuals to it. Optional hooks: `onCreate()`, `onUpdate(elapsed)` and `onFinish()`.
 *
 * The engine closes the transition after `duration` seconds. A script that wants to
 * time itself sets `trans.duration = -1` and calls `trans.finish()` when the switch
 * may happen, which is what lets it wait for tweens.
 */
class ScriptTransition extends MusicBeatSubstate
{
	public var finishCallback:Void->Void = null;
	public var isTransIn:Bool = false;
	public var duration:Float = 0.5;
	public var scriptName:String;
	public var scriptPath:String;

	public var script:HScript = null;

	var elapsedTotal:Float = 0;
	var finished:Bool = false;
	var dead:Bool = false;

	public function new(duration:Float, isTransIn:Bool, scriptPath:String, scriptName:String)
	{
		super();

		this.duration = duration;
		this.isTransIn = isTransIn;
		this.scriptPath = scriptPath;
		this.scriptName = scriptName;
	}

	override function create()
	{
		// Same camera the fade uses, so the transition covers the whole state
		if(FlxG.cameras.list != null && FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		try
		{
			script = new HScript(null, scriptPath, {trans: this, isTransIn: isTransIn});
		}
		catch(e:Dynamic)
		{
			Iris.error('Transition script "$scriptName" could not be loaded: $e');
			script = null;
			dead = true;
		}

		super.create();
		callScript('onCreate');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(finished) return;

		// A broken script must not leave the game stuck behind a transition
		if(dead)
		{
			close();
			return;
		}

		callScript('onUpdate', [elapsed]);

		if(duration >= 0)
		{
			elapsedTotal += elapsed;
			if(elapsedTotal >= duration) close();
		}
	}

	/** Ends the transition and lets the state change go through. Scripts call this. */
	public function finish():Void
		close();

	override function close():Void
	{
		if(finished) return;
		finished = true;

		callScript('onFinish');

		if(script != null)
		{
			script.destroy();
			script = null;
		}

		super.close();

		if(finishCallback != null)
		{
			final callback:Void->Void = finishCallback;
			finishCallback = null;
			callback();
		}
	}

	inline function callScript(func:String, ?args:Array<Dynamic>):Void
	{
		if(script == null || !script.exists(func)) return;
		script.call(func, args);
	}
}
#end
