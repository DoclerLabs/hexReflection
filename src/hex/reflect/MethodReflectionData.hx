package hex.reflect;

/**
 * @author Francis Bourre
 */
typedef MethodReflectionData =
{
	annotations		: Array<AnnotationReflectionData>,
	arguments		: Array<ArgumentReflectionData>,
	name 			: String
}