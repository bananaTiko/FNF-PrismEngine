package;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import backend.Highscore;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		#if (cpp && windows)
		// Declare the process DPI-aware before the window is created. Windows decides
		// once, at creation, whether to bitmap-stretch us: a window made first stays
		// blurry at 125% / 150% display scaling however we resize it afterwards.
		backend.Native.registerDPIAware();
		#end

		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		// P-Slice style widescreen scaling, keeps the game filling wide displays instead of letterboxing it
		#if mobile
		FlxG.scaleMode = new backend.MobileScaleMode(true);
		#end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		// Global mods must load no matter which script backend is enabled, otherwise
		// Lua-less builds silently lose every "runsGlobally" mod's assets and scripts.
		Mods.pushGlobalMods();
		Mods.loadTopMod();

		FlxG.save.bind('prism', CoolUtil.getSavePath());
		Highscore.load();

		#if (cpp && windows)
		// The title bar is painted by Windows, not by us, so it has to be recoloured before the
		// game draws anything: doing it once FlxGame existed showed the default light bar for the
		// first frames and then Windows either animated or redrew its way to dark, which is the
		// fade on boot. ClientPrefs only loads on the title screen, so read the saved value here.
		if(FlxG.save.data.windowColorMode != null)
			ClientPrefs.data.windowColorMode = FlxG.save.data.windowColorMode;
		applyWindowColorMode();
		#end

		#if CHECK_FOR_UPDATES
		if(FlxG.save.data.checkForUpdates == null || FlxG.save.data.checkForUpdates)
			CoolUtil.checkForUpdates();
		#end

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		// Opt-in desktop widescreen scaling. FlxGame has to exist first, it measures the window.
		#if desktop
		backend.Widescreen.refresh();
		#end

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	// Colors the title bar and border from Options > Visuals. Windows only.
	public static function applyWindowColorMode():Void {
		#if (cpp && windows)
		// Windows 10 only redraws the title bar once the window is toggled,
		// Windows 11 applies the change immediately.
		hxwindowmode.WindowColorMode.setWindowColorMode(ClientPrefs.data.windowColorMode != 'Light');
		if(hxwindowmode.WindowColorMode.isWindows10)
			hxwindowmode.WindowColorMode.redrawWindowHeader();
		#end
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = ~/:/g.replace(dateNow, "'");

		var fileName:String = "PrismEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

			errMsg += "\nUncaught Error: " + e.error;
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/bananaTiko/FNF-PrismEngine/issues";
		#end
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";

		// The folder next to the executable can be read-only (Program Files, macOS app bundles),
		// so write to the app storage folder first and fall back to "./crash/" if that fails.
		var crashDir:String = lime.system.System.applicationStorageDirectory;
		if (!crashDir.endsWith("/") && !crashDir.endsWith("\\")) crashDir += "/";
		crashDir += "crash/";
		var crashPath:String = crashDir + fileName;

		try {
			if (!FileSystem.exists(crashDir))
				FileSystem.createDirectory(crashDir);
			File.saveContent(crashPath, errMsg + "\n");
		} catch (err:Dynamic) {
			crashDir = "./crash/";
			crashPath = crashDir + fileName;
			if (!FileSystem.exists(crashDir))
				FileSystem.createDirectory(crashDir);
			File.saveContent(crashPath, errMsg + "\n");
		}

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(crashPath));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
