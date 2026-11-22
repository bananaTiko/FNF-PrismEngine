package backend;

import backend.Song.SwagSong;

/**
 * Song time signature, in the spirit of Psych Engine Extra's 1-100 / 1-64 support.
 *
 * Psych charts are section based and a section is one measure, so `sectionBeats`
 * on each section is what actually moves the chart. The signature's job is to say
 * how long a measure (and therefore a freshly made section) is: 4/4 keeps the old
 * four beats, 7/8 gives 3.5 beats, 6/8 gives 3, and so on.
 */
class TimeSignature
{
	public static inline var MAX_NUMERATOR:Int = 100;
	public static inline var MAX_DENOMINATOR:Int = 64;
	public static inline var DEFAULT_NUMERATOR:Int = 4;
	public static inline var DEFAULT_DENOMINATOR:Int = 4;

	public static function clampNumerator(value:Int):Int
		return MathUtils.clampInt(value, 1, MAX_NUMERATOR);

	public static function clampDenominator(value:Int):Int
		return MathUtils.clampInt(value, 1, MAX_DENOMINATOR);

	/** Beats in one measure, e.g. 7/8 -> 3.5. */
	public static function beatsPerMeasure(numerator:Int, denominator:Int):Float
	{
		numerator = clampNumerator(numerator);
		denominator = clampDenominator(denominator);
		return numerator * (4 / denominator);
	}

	/** Steps (sixteenths) in one measure, e.g. 7/8 -> 14. */
	public static function stepsPerMeasure(numerator:Int, denominator:Int):Int
		return Math.round(beatsPerMeasure(numerator, denominator) * 4);

	public static function numeratorOf(song:SwagSong):Int
		return (song != null && song.timeSignatureNum != null) ? clampNumerator(song.timeSignatureNum) : DEFAULT_NUMERATOR;

	public static function denominatorOf(song:SwagSong):Int
		return (song != null && song.timeSignatureDen != null) ? clampDenominator(song.timeSignatureDen) : DEFAULT_DENOMINATOR;

	/** Beats a measure holds for this chart, or 4 when it has no signature at all. */
	public static function songBeatsPerMeasure(song:SwagSong):Float
		return beatsPerMeasure(numeratorOf(song), denominatorOf(song));

	/** "4/4", "7/8"... for debug text and editors. */
	public static function toStringOf(song:SwagSong):String
		return numeratorOf(song) + '/' + denominatorOf(song);
}
