package hex.reflect.mock;

import hex.log.ILogger;

/**
 * @author Francis Bourre
 */
class MockContainerWithoutAnnotation
{
	@Inject( 42 )
	public function new( logger : ILogger )
	{
		//
	}

	@Test( "metadata" )
	@PostConstruct( 0 )
	public function testMethodInClassWithoutAnnotationImplementation( i : Int ) : Void
	{
		//
	}
}