package hex.reflect;

/**
 * @author Francis Bourre
 */
interface IClassReflectionDataProvider 
{
	function getClassReflectionData( type : Class<Dynamic> ) : ClassReflectionData;
}