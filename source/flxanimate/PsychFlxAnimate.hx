package flxanimate;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.animate.FlxElement;
import flxanimate.animate.FlxKeyFrame;
import flxanimate.animate.FlxLayer;
import flxanimate.animate.FlxSymbol;
import flxanimate.data.AnimationData;
import flxanimate.data.AnimationData.SymbolT;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.FlxAnimate as OriginalFlxAnimate;
import objects.SpriteElement;

import openfl.geom.ColorTransform;

class PsychFlxAnimate extends OriginalFlxAnimate
{
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null)
	{
		var animJson:AnimAtlas = null;
		if(myJson is String)
		{
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if(trimmed == '.json') myJson = File.getContent(myJson); //is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		}
		else animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if(trimmed == '.json') //Path is json
		{
			myData = File.getContent(pathOrStr);
			isXml = false;
		}
		else if (trimmed.substr(1) == '.xml') //Path is xml
		{
			myData = File.getContent(pathOrStr);
			isXml = true;
		}
		myData = _removeBOM(myData);

		// Automatic if everything else fails
		switch(isXml)
		{
			case true:
				myData = Xml.parse(myData);
			case false:
				myData = haxe.Json.parse(myData);
			case null:
				try
				{
					myData = haxe.Json.parse(myData);
					isXml = false;
					//trace('JSON parsed successfully!');
				}
				catch(e)
				{
					myData = Xml.parse(myData);
					isXml = true;
					//trace('XML parsed successfully!');
				}
		}

		anim._loadAtlas(animJson);
		if(!isXml) frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		else frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy()
	{
		try
		{
			super.destroy();
		}
		catch(e:haxe.Exception)
		{
			anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			//anim.metadata = FlxDestroyUtil.destroy(anim.metadata);
			anim.metadata.destroy();
			anim.symbolDictionary = null;
		}
	}

	function _removeBOM(str:String) //Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1); //myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}
	public function resumeAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.play();
	}

	// ------------------------------------------------------------------------------------------
	// Sprites put inside of the atlas (V-Slice's `animate.internal.elements.FlxSpriteElement`)
	// ------------------------------------------------------------------------------------------

	/**
	 * Every keyframe of the symbols whose name has this in it, for things to be put on them: see `objects.SpriteElement`.
	 */
	public function getFramesWithKeyword(keyword:String):Array<FlxKeyFrame>
	{
		var found:Array<FlxKeyFrame> = [];
		if(anim == null || anim.symbolDictionary == null || keyword == null || keyword.length < 1) return found;

		for (name => symbol in anim.symbolDictionary)
		{
			if(symbol == null || symbol.timeline == null || name.indexOf(keyword) < 0) continue;

			for (layer in symbol.timeline.getList())
			{
				@:privateAccess
				for (keyFrame in layer._keyframes)
					found.push(keyFrame);
			}
		}
		return found;
	}

	/** Puts a sprite on those frames, to be drawn wherever they show up: V-Slice's `FlxSpriteElement`. */
	public function addPlacedSprite(frames:Array<FlxKeyFrame>, sprite:FlxSprite):Void
	{
		if(frames == null || frames.length < 1 || sprite == null) return;

		var element:SpriteElement = new SpriteElement(sprite);
		for (frame in frames)
		{
			if(frame == null) continue;
			@:privateAccess frame._elements.push(element);
		}
	}

	/**
	 * The area a timeline of the atlas takes, on its own coordinates. It's the box V-Slice gives to a sprite that's playing it:
	 * the sprite's position is the corner of that box, and when flipped the art is mirrored inside of it.
	 *
	 * @param matrix   Something the timeline is seen through, like the placement of the animation that plays it.
	 * @param frame    Only this frame of it.
	 */
	public function getTimelineBounds(symbolName:String, ?matrix:FlxMatrix, ?frame:Null<Int>):FlxRect
	{
		var result:FlxRect = FlxRect.get();
		var symbol:FlxSymbol = (anim != null && anim.symbolDictionary != null) ? anim.symbolDictionary.get(symbolName) : null;
		if(symbol == null) return result;

		var seenThrough:FlxMatrix = new FlxMatrix();
		if(matrix != null) seenThrough.copyFrom(matrix);

		var bounds:Array<Float> = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
		if(frame != null) addFrameBounds(symbolName, frame, seenThrough, bounds, 0);
		else
		{
			for (i in 0...symbol.length)
				addFrameBounds(symbolName, i, seenThrough, bounds, 0);
		}

		if(bounds[0] > bounds[2] || bounds[1] > bounds[3]) return result; //nothing on it
		return result.set(bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]);
	}

	var _wholeBox:FlxRect = null;

	/**
	 * The box of the atlas' main timeline, as it is on the file. Kept after the first time, not to be changed.
	 */
	public function getWholeBox():FlxRect
	{
		if(_wholeBox == null)
			_wholeBox = (anim != null && anim.stageInstance != null && anim.stageInstance.symbol != null) ? getTimelineBounds(anim.stageInstance.symbol.name) : FlxRect.get();
		return _wholeBox;
	}

	// Adds what a symbol shows on one of its frames to the bounds, seen through a matrix
	function addFrameBounds(symbolName:String, frame:Int, matrix:FlxMatrix, bounds:Array<Float>, depth:Int):Void
	{
		var symbol:FlxSymbol = anim.symbolDictionary.get(symbolName);
		if(symbol == null || depth > 30) return;

		for (layer in symbol.timeline.getList())
		{
			if(layer == null || (layer.type != null && layer.type.match(Clipper))) continue; //masks aren't drawn

			var layerBounds:Array<Float> = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
			addLayerBounds(layer, frame, matrix, layerBounds, depth);
			if(layerBounds[0] > layerBounds[2] || layerBounds[1] > layerBounds[3]) continue;

			if(layerBounds[0] < bounds[0]) bounds[0] = layerBounds[0];
			if(layerBounds[1] < bounds[1]) bounds[1] = layerBounds[1];
			if(layerBounds[2] > bounds[2]) bounds[2] = layerBounds[2];
			if(layerBounds[3] > bounds[3]) bounds[3] = layerBounds[3];
		}
	}

	// What one layer of a symbol shows on a frame
	function addLayerBounds(layer:FlxLayer, frame:Int, matrix:FlxMatrix, bounds:Array<Float>, depth:Int):Void
	{
		var keyFrame:FlxKeyFrame = null;
		@:privateAccess
		for (candidate in layer._keyframes)
		{
			if(candidate.index <= frame && frame < candidate.index + candidate.duration)
			{
				keyFrame = candidate;
				break;
			}
		}
		if(keyFrame == null) return;

		for (element in keyFrame.getList())
		{
			if(element == null || !element.visible) continue;

			var elementMatrix:FlxMatrix = new FlxMatrix();
			if(element.matrix != null) elementMatrix.copyFrom(element.matrix);
			elementMatrix.concat(matrix);

			if(element.bitmap != null)
			{
				var limb = (frames != null) ? frames.getByName(element.bitmap) : null;
				if(limb == null) continue;

				// The ones rotated on the image are drawn the right way up
				var rotated:Bool = (limb.angle != FlxFrameAngle.ANGLE_0);
				var limbWidth:Float = rotated ? limb.frame.height : limb.frame.width;
				var limbHeight:Float = rotated ? limb.frame.width : limb.frame.height;
				for (corner in [[0.0, 0.0], [limbWidth, 0.0], [0.0, limbHeight], [limbWidth, limbHeight]])
				{
					var pointX:Float = corner[0] * elementMatrix.a + corner[1] * elementMatrix.c + elementMatrix.tx;
					var pointY:Float = corner[0] * elementMatrix.b + corner[1] * elementMatrix.d + elementMatrix.ty;
					if(pointX < bounds[0]) bounds[0] = pointX;
					if(pointY < bounds[1]) bounds[1] = pointY;
					if(pointX > bounds[2]) bounds[2] = pointX;
					if(pointY > bounds[3]) bounds[3] = pointY;
				}
				continue;
			}

			if(element.symbol == null || element.symbol.name == null) continue;

			var child:FlxSymbol = anim.symbolDictionary.get(element.symbol.name);
			if(child == null) continue;

			var childFrame:Int = childFrameOf(element, child.length, frame - keyFrame.index);
			addFrameBounds(element.symbol.name, childFrame, elementMatrix, bounds, depth + 1);
		}
	}

	// The frame of a symbol that's shown on the given frame of its parent
	static function childFrameOf(element:FlxElement, length:Int, passed:Int):Int
	{
		if(element.symbol == null) return 0;
		if(element.symbol.type == SymbolT.MovieClip || element.symbol.type == SymbolT.Button) return 0;

		var first:Int = element.symbol.firstFrame;
		if(length < 1) return 0;
		return (first + passed) % length;
	}

	override function parseElement(instance:FlxElement, m:FlxMatrix, colorFilter:ColorTransform, ?filterInstance:{?instance:FlxElement} = null,
		?cameras:Array<FlxCamera> = null, ?scrollFactor:FlxPoint = null)
	{
		var placed:SpriteElement = Std.downcast(instance, SpriteElement);
		if(placed == null)
		{
			super.parseElement(instance, m, colorFilter, filterInstance, cameras, scrollFactor);
			return;
		}

		if(placed.visible && placed.sprite != null) drawPlacedSprite(placed, m, colorFilter, filterInstance != null, (cameras != null) ? cameras : this.cameras);
	}

	/**
	 * Draws a sprite that was put on one of the atlas' frames, as part of the atlas: on the coordinates of the symbol the frame
	 * is of (`parent` takes those to where the symbol is being drawn), and from there like any sprite is drawn on the screen.
	 * Its corner is at its position minus its offset, it's scaled and turned around its origin and mirrored inside of its own size.
	 *
	 * The details are V-Slice's (flixel-animate's `FlxSpriteElement`): the sprite isn't made part of the symbol, it draws itself as
	 * it would anywhere else, only somewhere else and turned.
	 * - Its position is taken through everything the symbol went through to where that ends up on the screen.
	 * - Its angle gets the angle the symbol ends up with added to it. It isn't scaled, skewed or mirrored by the symbol or by the
	 *   atlas: a mirrored symbol counts as one turned around, and the scripts of the characters whose mouth is on a mirrored face
	 *   turn it by about 180 degrees to have it upright again.
	 * - A texture atlas counts as a sprite the size of its whole timeline, with its corner where that area starts, and its origin is
	 *   the middle of the first image of its spritesheet (what the sprite had as a frame when it was loaded).
	 */
	function drawPlacedSprite(placed:SpriteElement, parent:FlxMatrix, color:ColorTransform, filterin:Bool, cameras:Array<FlxCamera>):Void
	{
		var sprite:FlxSprite = Std.downcast(placed.sprite, FlxSprite);
		if(sprite == null || !sprite.visible || sprite.alpha <= 0) return;

		// the atlas it shows, when it's one
		var inner:PsychFlxAnimate = Std.downcast(sprite, PsychFlxAnimate);
		if(inner == this) return;

		var boxX:Float = 0;
		var boxY:Float = 0;
		var boxWidth:Float = sprite.frameWidth;
		var boxHeight:Float = sprite.frameHeight;
		var pivotX:Float = sprite.origin.x;
		var pivotY:Float = sprite.origin.y;
		var innerSymbol:String = null;
		if(inner != null)
		{
			if(inner.anim == null || inner.anim.curInstance == null || inner.anim.curInstance.symbol == null || inner.anim.stageInstance == null) return;

			innerSymbol = inner.anim.curInstance.symbol.name;
			var box:FlxRect = inner.getWholeBox();
			boxX = box.x;
			boxY = box.y;
			boxWidth = box.width;
			boxHeight = box.height;

			pivotX = boxWidth * 0.5;
			pivotY = boxHeight * 0.5;
			var first = (inner.frames != null && inner.frames.frames != null) ? inner.frames.frames[0] : null;
			if(first != null && first.frame != null)
			{
				var turned:Bool = (first.angle != FlxFrameAngle.ANGLE_0);
				pivotX = (turned ? first.frame.height : first.frame.width) * 0.5;
				pivotY = (turned ? first.frame.width : first.frame.height) * 0.5;
			}
		}
		else if(sprite.frame == null) return;

		// What the atlas still does to everything it draws after `parent` (see `drawLimb()`): scaled and turned around its origin.
		// The sprite has to come out as if none of that was done to it, so it's undone here beforehand
		var own:FlxMatrix = new FlxMatrix();
		if(!filterin)
		{
			own.scale(scale.x, scale.y);
			if(bakedRotationAngle <= 0 && angle != 0) own.rotate(angle * Math.PI / 180);
		}

		var whole:FlxMatrix = new FlxMatrix();
		whole.copyFrom(parent);
		whole.tx = whole.ty = 0;
		whole.concat(own);
		var symbolAngle:Float = Math.atan2(whole.b, whole.a);

		var undone:FlxMatrix = new FlxMatrix();
		undone.copyFrom(own);
		if(undone.a * undone.d - undone.b * undone.c == 0) return;
		undone.invert();

		var local:FlxMatrix = new FlxMatrix();
		local.translate(-boxX, -boxY);
		if(sprite.flipX)
		{
			local.scale(-1, 1);
			local.translate(boxWidth, 0);
		}
		if(sprite.flipY)
		{
			local.scale(1, -1);
			local.translate(0, boxHeight);
		}
		local.translate(-pivotX, -pivotY);
		local.scale(sprite.scale.x, sprite.scale.y);
		local.rotate(sprite.angle * Math.PI / 180 + symbolAngle);
		local.translate(pivotX - sprite.offset.x, pivotY - sprite.offset.y);
		local.concat(undone);
		local.translate(parent.a * sprite.x + parent.c * sprite.y + parent.tx, parent.b * sprite.x + parent.d * sprite.y + parent.ty);

		var tinted:ColorTransform = color;
		if(sprite.alpha < 1)
		{
			tinted = new ColorTransform(color.redMultiplier, color.greenMultiplier, color.blueMultiplier, color.alphaMultiplier * sprite.alpha,
				color.redOffset, color.greenOffset, color.blueOffset, color.alphaOffset);
		}

		if(inner == null)
		{
			drawLimb(sprite.frame, local, tinted, filterin, null, null, cameras);
			return;
		}

		var instanceMatrix:FlxMatrix = inner.anim.curInstance.matrix;
		if(instanceMatrix != null)
		{
			var placedWhole:FlxMatrix = new FlxMatrix();
			placedWhole.copyFrom(instanceMatrix);
			placedWhole.concat(local);
			local = placedWhole;
		}
		drawOtherTimeline(inner, innerSymbol, inner.anim.curFrame, local, tinted, filterin, cameras, 0);
	}

	// What a symbol of another atlas shows on one of its frames, drawn by this one (where, how and with what this one is drawn).
	function drawOtherTimeline(other:PsychFlxAnimate, symbolName:String, frame:Int, matrix:FlxMatrix, color:ColorTransform, filterin:Bool,
		cameras:Array<FlxCamera>, depth:Int):Void
	{
		var symbol:FlxSymbol = other.anim.symbolDictionary.get(symbolName);
		if(symbol == null || depth > 30) return;

		// (the layers of a timeline are listed from the front one to the back one)
		var layers = symbol.timeline.getList();
		var index:Int = layers.length;
		while(--index >= 0)
		{
			var layer:FlxLayer = layers[index];
			if(layer == null || (layer.type != null && layer.type.match(Clipper))) continue;

			var keyFrame:FlxKeyFrame = null;
			@:privateAccess
			for (candidate in layer._keyframes)
			{
				if(candidate.index <= frame && frame < candidate.index + candidate.duration)
				{
					keyFrame = candidate;
					break;
				}
			}
			if(keyFrame == null) continue;

			for (element in keyFrame.getList())
			{
				if(element == null || !element.visible) continue;

				var elementMatrix:FlxMatrix = new FlxMatrix();
				if(element.matrix != null) elementMatrix.copyFrom(element.matrix);
				elementMatrix.concat(matrix);

				if(element.bitmap != null)
				{
					var limb = (other.frames != null) ? other.frames.getByName(element.bitmap) : null;
					if(limb != null) drawLimb(limb, elementMatrix, color, filterin, null, null, cameras);
					continue;
				}

				if(element.symbol == null || element.symbol.name == null) continue;

				var child:FlxSymbol = other.anim.symbolDictionary.get(element.symbol.name);
				if(child == null) continue;

				var childFrame:Int = childFrameOf(element, child.length, frame - keyFrame.index);
				drawOtherTimeline(other, element.symbol.name, childFrame, elementMatrix, color, filterin, cameras, depth + 1);
			}
		}
	}
}