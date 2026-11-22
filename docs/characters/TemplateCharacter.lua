-- Character script for characters/<name>.lua (data/characters/<name>.lua works too)
--
-- Loaded for every character with that name when the song starts (and for characters
-- added by a "Change Character" event). The script is also a normal song script, so
-- onUpdate/onStepHit/onEvent work here too; only these three hooks are sent to the
-- one character that loaded the file.

function onCreate()
	-- The character is already built at this point
end

function onDance()
	-- The character is about to play its idle/dance animation
end

function onPlayAnim(anim, forced)
	-- Called before an animation starts playing
	-- anim: the animation name, forced: true when it was played with Force
end

function onGetCamPos()
	-- Return the camera offset for this character, or nothing to keep the JSON one
	-- return {x = 100, y = -50}
end
