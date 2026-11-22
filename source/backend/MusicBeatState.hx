package backend;

import flixel.FlxState;
import flixel.FlxSubState;
import backend.PsychCamera;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curMeasure:Int = 0;

	private var lastWidth:Int = 0;
	private var lastHeight:Int = 0;
	private var gameResizedCallback:Int->Int->Void;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables()
		return getState().variables;

	/**
	 * Makes sure the menu track is loaded, without restarting one that is already playing.
	 * Returns whether `FlxG.sound.music` is available: a missing or unreadable
	 * `freakyMenu` leaves it null, and the menus used to dereference that and crash.
	 */
	public static function ensureMenuMusic(volume:Float = 0):Bool
	{
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), volume);

		return FlxG.sound.music != null;
	}

	override function create() {
		// a state change is also the moment to look the audio device up again:
		// unplugging headphones kills OpenAL's device without telling anyone. Only a
		// changed device is rebuilt, so the menu track normally keeps playing. A rebuild
		// tears it down, so it is started again at a level the state's own fade expects.
		var rebuilt:Bool = AudioRecovery.checkDevice();
		ensureMenuMusic(rebuilt ? 0.7 : 0);

		// idempotent, and the first state after the save is loaded is where the
		// widescreen option actually takes effect
		#if desktop
		Widescreen.refresh();
		#end

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		lastWidth = FlxG.width;
		lastHeight = FlxG.height;
		gameResizedCallback = onGameResized; // keep the closure so destroy() can remove it
		FlxG.signals.gameResized.add(gameResizedCallback);

		if(!skip) Transitions.playIn();
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		updateMeasure();

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	// Measures follow the song's time signature, unlike sections: a section can be 8 or 12
	// beats long, while a 4/4 measure is always 4. Can be overridden to run state logic.
	public function measureHit():Void {}

	private function updateMeasure():Void
	{
		if(curStep < 0) return;

		var perMeasure:Int = TimeSignature.stepsPerMeasure(TimeSignature.numeratorOf(PlayState.SONG), TimeSignature.denominatorOf(PlayState.SONG));
		if(perMeasure < 1) perMeasure = 16;

		var newMeasure:Int = Std.int(curStep / perMeasure);
		if(newMeasure == curMeasure) return;

		curMeasure = newMeasure;
		measureHit();
	}

	// Lua and HScript only exist while a PlayState is loaded, so every other state asks
	// it to dispatch for them instead of keeping its own list of scripts.
	public function dispatchScripts(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if(PlayState.instance == null) return null;
		return PlayState.instance.callOnScripts(func, args);
	}

	override public function onFocus():Void
	{
		super.onFocus();
		dispatchScripts('onFocus');
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		dispatchScripts('onFocusLost');
	}

	private function onGameResized(width:Int, height:Int):Void
	{
		var oldWidth:Int = lastWidth;
		var oldHeight:Int = lastHeight;
		lastWidth = width;
		lastHeight = height;

		dispatchScripts('onResize', [width, height, oldWidth, oldHeight]);
	}

	// Both the fade and scripted transitions are engine plumbing, not a menu a script opened
	static function isTransitionSubstate(SubState:FlxSubState):Bool
	{
		if(Std.isOfType(SubState, CustomFadeTransition)) return true;

		#if HSCRIPT_ALLOWED
		return Std.isOfType(SubState, backend.ScriptTransition);
		#else
		return false;
		#end
	}

	override public function openSubState(SubState:FlxSubState)
	{
		if(SubState != null && !isTransitionSubstate(SubState))
			dispatchScripts('onOpenSubState', [Type.getClassName(Type.getClass(SubState))]);

		super.openSubState(SubState);
	}

	override function destroy():Void
	{
		FlxG.signals.gameResized.remove(gameResizedCallback);
		gameResizedCallback = null;
		super.destroy();
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		notifyStateSwitch(nextState);
		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		notifyStateSwitch(FlxG.state);
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	static function notifyStateSwitch(nextState:FlxState):Void
	{
		var state:MusicBeatState = getState();
		if(state == null || nextState == null) return;

		state.dispatchScripts('onStateSwitch', [Type.getClassName(Type.getClass(nextState))]);
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		// The transition decides when it is over; then the switch goes through
		final target:FlxState = nextState;
		Transitions.playOut(function() {
			if(target == FlxG.state)
				FlxG.resetState();
			else
				FlxG.switchState(target);
		});
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = null;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		if(val == null && PlayState.SONG != null) val = TimeSignature.songBeatsPerMeasure(PlayState.SONG);
		return val == null ? 4 : val;
	}
}
