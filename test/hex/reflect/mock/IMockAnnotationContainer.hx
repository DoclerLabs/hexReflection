package hex.reflect.mock;

/**
 * @author Francis Bourre
 */
#if !macro
@:remove
@:autoBuild( hex.reflect.ReflectionBuilder.readMetadata( hex.reflect.mock.IMockAnnotationContainer, [ "Inject", "Language", "Test", "PostConstruct", "Optional", "ConstructID" ] ) )
#end
interface IMockAnnotationContainer
{
	
}