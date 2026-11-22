package backend;

#if DISCORD_ALLOWED
import lime.app.Application;

import flixel.FlxG;

import hxdiscord_rpc.DiscordClient as RPC;
import hxdiscord_rpc.RichPresence;

/**
 * Discord Rich Presence, on top of Freak-Crew's hxdiscord_rpc fork
 * (haxelib `freak_discord_rpc`, package still `hxdiscord_rpc`).
 *
 * The library handles reconnecting, rate limiting and caching the presence, so
 * this class only keeps one RichPresence for the engine's many call sites and
 * forwards it. `update()` must run on the main thread every frame, hence the
 * postUpdate signal in `prepare()`.
 */
class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "1570632285886095480"; // Prism Engine Discord application
	public static var clientID(default, set):String = _defaultID;
	private static var presence:RichPresence = new RichPresence();
	private static var listeningForUpdates:Bool = false;

	public static function check()
	{
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare()
	{
		// Event handlers and pending sends only run inside update(), on this thread.
		if(!listeningForUpdates)
		{
			listeningForUpdates = true;
			FlxG.signals.postUpdate.add(RPC.update);
		}

		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown()
	{
		if(!isInitialized) return;

		isInitialized = false;
		RPC.shutdown();
	}

	public static function initialize()
	{
		if(isInitialized || !RPC.supported) return;

		RPC.onReady = function(user) {
			var message = '(Discord) Connected to User ';
			if (user.discriminator != 0) //Old discriminators
				message += '(${user.username}#${user.discriminator})';
			else //New Discord IDs/Discriminator system
				message += '(${user.username})';

			trace(message);
			updatePresence();
		};
		RPC.onError = function(errorCode:Int, message:String) trace('Discord: Error ($errorCode: $message)');
		RPC.onDisconnected = function(errorCode:Int, message:String) trace('Discord: Disconnected ($errorCode: $message)');

		RPC.initialize(clientID, {autoRegister: true});
		isInitialized = true;
		trace("Discord Client initialized");
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon')
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.smallImageKey = smallImageKey;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = "Engine Version: " + states.MainMenuState.prismEngineVersion;
		// Obtained times are in milliseconds so they are divided so Discord can use them
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp, $largeImageKey');
	}

	public static function updatePresence()
	{
		// Forced so a presence that only changed its timestamps still goes out.
		RPC.setPresence(presence, true);
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String):String
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			// initialize() closes the old connection and reconnects with the new ID;
			// the presence it kept is sent again once connected.
			RPC.initialize(newID, {autoRegister: true});
			updatePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
#end
