package hex.reflect;

/**
 * ...
 * @author Francis Bourre
 */
class ReflectSuite
{
	@Suite( "Reflect suite" )
    public var list : Array<Class<Dynamic>> = [ ReflectionBuilderTest, ReflectTest ];
}