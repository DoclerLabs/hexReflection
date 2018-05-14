package hex.reflect.mock;

import hex.log.ILogger;
import hex.log.Logger;

/**
 * @author Francis Bourre
 */
class MockAnnotationContainer extends MockContainerWithoutAnnotation implements IMockAnnotationContainer
{
	@Inject( "ID", "name", 3 )
	@Language( "fr" )
	public var property : Logger;

	@Inject( "b", 3, false )
	@Language( "en" )
	private var _privateProperty : Int;

	public var propertyWithoutAnnotation : String;

	@Inject( "a", 2, true )
	public function new( domain : String, logger : ILogger )
	{
		super( logger );
	}
	
	//TODO add test for function parameters annotations
	@Test( "testMethodWithPrimMetadata" )
	@PostConstruct( 0 )
	public function testMethodWithPrim( i : Int, u : UInt, b : Bool, @RequestParam( { value: "name", required: false, defaultValue: "World" } ) s : String, f : Float ) : Void
	{
		//
	}

	@Test( "methodToOverrideMetadata" )
	@PostConstruct( 1 )
	@Optional( true )
	function _methodToOverride( element : Logger ) : Void
	{
		//
	}

	public function methodWithoutAnnotation() : Void
	{

	}
}