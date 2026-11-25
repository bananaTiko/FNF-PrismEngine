package backend;

// PsychCamera handles followLerp based on elapsed
// and stops camera from snapping at higher framerates

class PsychCamera extends FlxCamera
{
	var camName:String;

	public var X:Int;
	public var Y:Int;

	// When true the camera snaps straight to the reset point instead of lerping there
	public var ForcePos:Bool = false;

	var resetActive:Bool = false;
	var resetTarget:FlxPoint = FlxPoint.get();
	var resetEpsilon:Float = 0.5;

	public function new(name:String = 'camera', X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0)
	{
		camName = name;
		this.X = X;
		this.Y = Y;
		super(X, Y, Width, Height, Zoom);
	}

	override public function update(elapsed:Float):Void
	{
		if (ForcePos)
		{
			scroll.set(resetTarget.x, resetTarget.y);
			resetActive = false;
		}
		else
		{
			// follow the target, if there is one
			if (target != null && !resetActive)
			{
				updateFollowDelta(elapsed);
			}

			if (resetActive)
			{
				var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1 / 60));
				scroll.x += (resetTarget.x - scroll.x) * mult;
				scroll.y += (resetTarget.y - scroll.y) * mult;
				if (Math.abs(scroll.x - resetTarget.x) <= resetEpsilon && Math.abs(scroll.y - resetTarget.y) <= resetEpsilon)
				{
					scroll.set(resetTarget.x, resetTarget.y);
					resetActive = false;
				}
			}
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		updateCameraFilters();

		updateFlashSpritePosition();
		updateShake(elapsed);
	}

	// What the flash sprite's filter chain was last built from. OpenFL's `filters` setter has
	// no equality check: it clones every filter and marks the display object render-dirty, so
	// assigning it rebuilds the whole chain (and its render target) again. Doing that every
	// frame is both a per-frame allocation and a full-screen filter pass per camera, so only
	// touch the chain when what it should hold actually changes.
	var appliedFilters:Array<openfl.filters.BitmapFilter> = null;
	var appliedFiltersLength:Int = -1;
	var appliedFiltersEnabled:Bool = false;
	var appliedColorblind:String = null;
	var filtersApplied:Bool = false;

	/**
	 * Camera filters plus the colourblind filter, which is a display option rather than part of
	 * the stage, so it has to survive whatever a stage puts in `filters`.
	 */
	function updateCameraFilters():Void
	{
		var base:Array<openfl.filters.BitmapFilter> = (filtersEnabled ? filters : null);
		var baseLength:Int = (base == null) ? -1 : base.length;
		var colorblindMode:String = ClientPrefs.data.colorblind;

		if (filtersApplied && base == appliedFilters && baseLength == appliedFiltersLength
			&& filtersEnabled == appliedFiltersEnabled && colorblindMode == appliedColorblind)
			return;

		filtersApplied = true;
		appliedFilters = base;
		appliedFiltersLength = baseLength;
		appliedFiltersEnabled = filtersEnabled;
		appliedColorblind = colorblindMode;

		var colorblind:openfl.filters.BitmapFilter = shaders.ColorblindShader.filterFor(colorblindMode);

		if (colorblind != null)
		{
			var list:Array<openfl.filters.BitmapFilter> = base != null ? base.copy() : [];
			list.push(colorblind);
			flashSprite.filters = list;
			return;
		}

		flashSprite.filters = base;
	}

	public inline function resetToPoint(p:FlxPoint):Void
	{
		resetTo(p.x, p.y);
	}

	public inline function resetTo(x:Float, y:Float):Void
	{
		resetTarget.set(x, y);
		if (ForcePos)
		{
			scroll.set(resetTarget.x, resetTarget.y);
			resetActive = false;
		}
		else
		{
			resetActive = true;
		}
	}

	/**
	 * Sends the camera back to the position it was created with.
	 */
	public inline function GoZero():Void
	{
		resetTo(X, Y);
	}

	public function updateFollowDelta(?elapsed:Float = 0):Void
	{
		// Either follow the object closely,
		// or double check our deadzone and update accordingly.
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= viewRight)
				{
					_scrollTarget.x += viewWidth;
				}
				else if (targetX + target.width < viewLeft)
				{
					_scrollTarget.x -= viewWidth;
				}

				if (targetY >= viewBottom)
				{
					_scrollTarget.y += viewHeight;
				}
				else if (targetY + target.height < viewTop)
				{
					_scrollTarget.y -= viewHeight;
				}
				
				// without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
				bindScrollPos(_scrollTarget);
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				}
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
				{
					_scrollTarget.y = edge;
				}
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
				{
					_scrollTarget.y = edge;
				}
			}

			if ((target is FlxSprite))
			{
				if (_lastTargetPosition == null)
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
				}
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
		}

		var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1/60));
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
		//trace('lerp on this frame: $mult');
	}

	override function set_followLerp(value:Float)
	{
		return followLerp = value;
	}
}
