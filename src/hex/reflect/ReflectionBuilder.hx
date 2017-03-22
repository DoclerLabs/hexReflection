package hex.reflect;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;

/**
 * ...
 * @author Francis Bourre
 */
class ReflectionBuilder 
{
	//static property name that will handle the data
	public static inline var REFLECTION : String = "__REFLECTION";
	
	public static var _static_classes : Array<ClassReflectionData> = [];

	/** @private */
    function new()
    {
        throw new hex.error.PrivateConstructorException();
    }
	macro public static function readMetadata( metadataExpr : Expr, allowedAnnotations : Array<String> = null ) : Array<Field>
	{
		var localClass = Context.getLocalClass().get();
		
		//parse annotations
		var fields : Array<Field> = ReflectionBuilder.parseMetadata( metadataExpr, Context.getBuildFields(), allowedAnnotations );
		
		//get data result
		var data = ReflectionBuilder._static_classes[ ReflectionBuilder._static_classes.length - 1 ];

		//append the expression as a field
		fields.push(
		{
			name:  ReflectionBuilder.REFLECTION,
			access:  [ Access.APublic, Access.AStatic ],
			kind: FieldType.FVar( macro: hex.reflect.ClassReflectionData, macro $v{ data } ), 
			pos: Context.currentPos(),
		});
		
		return fields;
	}
	
	#if macro
	public static function parseMetadata( metadataExpr : Expr, classFields : Array<Field>, annotationFilter : Array<String> = null, displayWarning : Bool = false ) : Array<Field>
	{
		//parse metadata name
		var metadataName = switch( metadataExpr.expr )
		{
			case EConst( c ):
				switch ( c )
				{
					case CIdent( v ):
						hex.util.MacroUtil.getClassNameFromExpr( metadataExpr );

					default: 
						null;
				}

			case EField( e, field ):
				haxe.macro.ExprTools.toString( e ) + "." + field;

			default: null;
		}
		
		return ReflectionBuilder._parseMetadata( metadataName, classFields, annotationFilter, displayWarning );
	}
	
	static function _getAnnotations( f : Field, annotationFilter : Array<String> = null, displayWarning : Bool = false ) : Array<AnnotationReflectionData>
	{
		var annotationDatas : Array<AnnotationReflectionData> = [];
		
		var metaID = f.meta.length -1;
		while ( metaID > -1 )
		{
			var m = f.meta[ metaID ];
			var annotationKeys : Array<Dynamic> = [];
			if ( annotationFilter == null || annotationFilter.indexOf( m.name )  != -1 )
			{
				if ( m.params != null )
				{
					for ( param in m.params )
					{
						switch( param.expr )
						{
							case EConst( c ):
								switch ( c )
								{
									case CInt( s ):
										var i = Std.parseInt( s );
										annotationKeys.push(  ( i != null ) ? i : Std.parseFloat( s ) ); // if the number exceeds standard int return as float

									case CFloat( s ):
										annotationKeys.push(  Std.parseFloat( s ) );

									case CString( s ):
										annotationKeys.push( s );

									case CIdent( "null" ):
										annotationKeys.push( null );

									case CIdent( "true" ):
										annotationKeys.push( true );

									case CIdent("false"):
										annotationKeys.push( false );

									case CRegexp( r, opt ):
										//do nothing

									case CIdent( v ):
										annotationKeys.push( hex.util.MacroUtil.getClassNameFromExpr( param ) );

									default: 
										null;
								}
								
							case EField( e, field ):
								annotationKeys.push( haxe.macro.ExprTools.toString( e ) + "." + field );

							default: null;
						}
					}
				}
				
				annotationDatas.unshift( { annotationName: m.name, annotationKeys: annotationKeys } );
				f.meta.remove( m );//remove metadata
			}
			else if ( displayWarning && m.name.charAt( 0 ) != ":" )
			{
				Context.warning( "Warning: Unregistered annotation '@" + m.name + "' found on field '" + Context.getLocalClass().get().module + "::" + f.name + "'", m.pos );
			}
			metaID--;
		}
		
		return annotationDatas;
	}
	
	static function _parseMetadata( metadataName : String, classFields : Array<Field>, annotationFilter : Array<String> = null, displayWarning : Bool = false ) : Array<Field>
	{
		var hasFilter = annotationFilter != null && annotationFilter.length > 0;
		var localClass = Context.getLocalClass().get();
		var superClassName : String;
		var superClassAnnotationData : ClassReflectionData = null;

		var superClass = Context.getLocalClass().get().superClass;
		if ( superClass != null )
		{
			superClassName = superClass.t.get().module;
			for ( classAnnotationData in ReflectionBuilder._static_classes )
			{
				if ( classAnnotationData.name == superClassName )
				{
					superClassAnnotationData = classAnnotationData;
					break;
				}
			}
		}
		
		var constructorAnnotationData : MethodReflectionData = null;

		var properties : Array<PropertyReflectionData>	= [];
		if ( superClassAnnotationData != null )
		{
			properties = properties.concat( superClassAnnotationData.properties );
		}

		var methods 	: Array<MethodReflectionData>	= [];
		if ( superClassAnnotationData != null )
		{
			methods = methods.concat( superClassAnnotationData.methods );
		}

		for ( f in classFields )
		{
			var annotationDatas = hasFilter ? ReflectionBuilder._getAnnotations( f, annotationFilter, displayWarning ) : [];

			if ( !hasFilter || annotationDatas.length > 0 )
			{
				switch ( f.kind )
				{
					case FVar( t, e ):
						properties.push( { annotations: annotationDatas, name: f.name, type: t.toType().toString().split(' ').join( '' ) } );

					case FFun( func ) :
						var argumentDatas : Array<ArgumentReflectionData> = [];
						for ( arg in func.args )
						{
							switch ( arg.type )
							{
								case TPath( p ):
									argumentDatas.push( { name: arg.name, type: arg.type.toType().toString().split(' ').join( '' ) } );

								default:
							}
						}

						if ( f.name == "new" )
						{
							constructorAnnotationData = { annotations: annotationDatas, arguments: argumentDatas, name: f.name };
						}
						else
						{
							if ( superClassAnnotationData != null )
							{
								var methodName = f.name;
								var superMethodAnnotationDatas : Array<MethodReflectionData> = superClassAnnotationData.methods;
								for ( superMethodAnnotationData in  superMethodAnnotationDatas )
								{
									if ( superMethodAnnotationData.name == methodName )
									{
										methods.splice( methods.indexOf( superMethodAnnotationData ), 1 );
										break;
									}
								}
							}

							methods.push( { annotations: annotationDatas, arguments: argumentDatas, name: f.name } );
						}

					default: null;
				}
			}
		}

		var data = { name:Context.getLocalClass().get().module, superClassName: superClassName, constructor: constructorAnnotationData, properties:properties, methods:methods };
		ReflectionBuilder._static_classes.push( data );
		return classFields;
	}
	#end
}

typedef MemberDescription =
{
	var name : String;
	var type : String;
}
