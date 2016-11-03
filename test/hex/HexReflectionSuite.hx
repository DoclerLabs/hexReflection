package hex;

import hex.reflect.ReflectSuite;

/**
 * ...
 * @author Francis Bourre
 */
class HexReflectionSuite
{
	@Suite( "HexReflect suite" )
    public var list : Array<Class<Dynamic>> = [ ReflectSuite ];
}