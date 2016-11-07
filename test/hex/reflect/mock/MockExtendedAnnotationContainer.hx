package hex.reflect.mock;

import hex.domain.Domain;
import hex.log.ILogger;
import hex.log.Logger;

/**
 * @author Francis Bourre
 */
class MockExtendedAnnotationContainer extends MockAnnotationContainer
{
    @Inject( "anotherID", "anotherName", 3 )
    @Language( "it" )
    public var anotherProperty : Bool;

    @Inject( "d", 3, false )
    @ConstructID( 9 )
    public function new( a : Array<String>, extendedDomain : Domain, extendedLogger : ILogger )
    {
        super( extendedDomain, extendedLogger );
    }

    @Test( "methodToOverrideMetadata" )
    @PostConstruct( 3 )
    @Optional( false )
    override private function _methodToOverride( element : Logger ) : Void
    {
        //
    }

    @Test( "anotherTestMethodMetadata" )
    @PostConstruct( 2 )
    public function anotherTestMethod( f : Float ) : Void
    {
        //
    }

    @WontBeParsed
    public function methodWithNonParsableAnnotation() : Void
    {
        //
    }
}
