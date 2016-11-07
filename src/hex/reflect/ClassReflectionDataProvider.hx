package hex.reflect;

import hex.collection.HashMap;

/**
 * ...
 * @author Francis Bourre
 */
class ClassReflectionDataProvider implements IClassReflectionDataProvider
{
	var _metadataName       : String;
    var _annotatedClasses   : HashMap<Class<Dynamic>, ClassReflectionData>;
	
	public function new( type : Class<Dynamic> )
    {
        this._metadataName      = Type.getClassName( type );
        this._annotatedClasses  = new HashMap();
    }
	
	public function getClassReflectionData( type : Class<Dynamic> ) : ClassReflectionData
    {
        return this._annotatedClasses.containsKey( type ) ? this._annotatedClasses.get( type ) : this._getClassReflectionData( type );
    }
	
	function _getClassReflectionData( type : Class<Dynamic>)  : ClassReflectionData
    {
		var field : ClassReflectionData = Reflect.getProperty( type, "__INJECTION_DATA" );
		
		if ( field != null )
		{
			this._annotatedClasses.put( type, field );
			return field;
		}
		else
        {
            return null;
        }
    }
}