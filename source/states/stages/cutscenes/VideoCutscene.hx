package states.stages.cutscenes;


class VideoCutscene
{
	public static function playVideo(videoName:String, onEnd:() -> Void)
	{
		var game = PlayState.instance;
		if (videoName != null)
		{
			#if VIDEOS_ALLOWED
			//startVideo returns null when the file isn't in the build, so there is nothing to
			//attach callbacks to; just carry on with whatever came after the cutscene.
			if (game.startVideo(videoName) == null)
			{
				new FlxTimer().start(0.0, function(tmr:FlxTimer)
				{
					onEnd();
				});
				return;
			}
			game.videoCutscene.finishCallback = game.videoCutscene.onSkip = function()
			{
				game.videoCutscene = null;
				onEnd();
			};
			#else // Make a timer to prevent it from crashing due to sprites not being ready yet.
			new FlxTimer().start(0.0, function(tmr:FlxTimer)
			{
				onEnd();
			});
			#end
			return;
		}
	}
}
