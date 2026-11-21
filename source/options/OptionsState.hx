package options;

import prismui.PrismButton;
import prismui.PrismList;
import prismui.PrismPanel;
import prismui.PrismUI;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		'Customize HUD'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var panel:PrismPanel;
	var list:PrismList;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Customize HUD':
				MusicBeatState.switchState(new options.HudCustomizeState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = PrismUI.theme.accentDark;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		var dim:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		dim.scale.set(FlxG.width, FlxG.height);
		dim.updateHitbox();
		dim.alpha = 0.45;
		add(dim);

		panel = new PrismPanel(0, 0, 760, 560, Language.getPhrase('options_title', 'Options'));
		panel.center();
		add(panel);

		list = new PrismList();
		list.visibleRows = 8;
		list.rowWidth = panel.wid - PrismUI.px(PrismUI.theme.panelPadding) * 2;
		list.rowHeight = 52;
		list.onChange = function(index:Int) curSelected = index;
		list.onActivate = function(index:Int) openSelectedSubstate(options[index]);
		panel.addContent(list);

		for (option in options)
			list.addItem(new PrismButton(0, 0, Language.getPhrase('options_$option', option)));

		list.select(curSelected, true);
		list.refreshSelection();

		ClientPrefs.saveSettings();
		FlxG.mouse.visible = true;

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
