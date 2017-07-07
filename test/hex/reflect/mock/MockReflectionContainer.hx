package hex.reflect.mock;

import hex.reflect.mock.pack.MockModule.InternalTypedef;

/**
 * @author Francis Bourre
 */
class MockReflectionContainer implements IMockReflectionContainer
{
    public var genericProperty : Array<Array<Bool>>;
    public var typedefInsideAModule : InternalTypedef;
	
	public function new()
	{
		
	}
	
	public function doSomething( i : Int, collection : Array<Array<String>> ) : Void
	{
		
	}
}
