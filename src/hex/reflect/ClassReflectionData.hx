package hex.reflect;

/**
 * @author Francis Bourre
 */
typedef ClassReflectionData =
{
	name 							: String,
	superClassName 					: String,
	constructor						: MethodReflectionData,
	properties 						: Array<PropertyReflectionData>,
	methods							: Array<MethodReflectionData>
}