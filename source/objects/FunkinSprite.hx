package objects;

/**
 * Small port of P-Slice's `mikolka.funkin.FunkinSprite`, keeping the helper the ported cutscenes use.
 */
class FunkinSprite extends FlxSprite
{
	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
	{
		makeGraphic(width, height, color);
		return this;
	}
}
