package states.stages;

/**
 * The SSERAFIM diner from Spaghetti, ported from V-Slice's `sserafim` stage.
 *
 * The props keep V-Slice's stage coordinates (the song runs at zoom 0.5, the same
 * zoom the original stage uses) so the room lines up with the character positions
 * in `stages/sserafim.json`.
 */
class SSerafim extends BaseStage
{
	var bg:BGSprite;
	var floorSprite:BGSprite;
	var backTables:BGSprite;
	var backStools:BGSprite;
	var truck:BGSprite;
	var truckDoor:BGSprite;
	var frontStool:BGSprite;

	override function create()
	{
		bg = new BGSprite('sserafim/bg', -1853, -815, 0.75, 0.75);
		add(bg);

		floorSprite = new BGSprite('sserafim/floor', 790, 625, 0.85, 0.85);
		add(floorSprite);

		backTables = new BGSprite('sserafim/back-tables', -1857, 267, 0.93, 0.93);
		add(backTables);

		backStools = new BGSprite('sserafim/back-stools', -1357, 426, 0.94, 0.94);
		add(backStools);

		truck = new BGSprite('sserafim/truck-stuff', -983, -707, 0.95, 0.95);
		add(truck);

		truckDoor = new BGSprite('sserafim/truck-door', -980, -173, 0.95, 0.95);
		add(truckDoor);

		frontStool = new BGSprite('sserafim/front-stool', -280, 818, 1.0, 1.0);
		add(frontStool);
	}
}
