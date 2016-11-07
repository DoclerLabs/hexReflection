package hex.reflect;

import haxe.macro.Context;
import haxe.macro.Expr;
import hex.error.PrivateConstructorException;

/**
 * ...
 * @author Francis Bourre
 */
class ReflectionBuilder 
{
	public static var _static_classes : Array<ClassReflectionData> = [];

	/** @private */
    function new()
    {
        throw new PrivateConstructorException( "This class can't be instantiated." );
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
			name:  "__INJECTION_DATA",
			access:  [ Access.APublic, Access.AStatic ],
			kind: FieldType.FVar( macro: hex.reflect.ClassReflectionData, macro $v{ data } ), 
			pos: Context.currentPos(),
		});
		
		return fields;
	}
	
	#if macro
	public static function parseMetadata( metadataExpr : Expr, classFields : Array<Field>, allowedAnnotations : Array<String> = null, displayWarning : Bool = false ) : Array<Field>
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
		
		return ReflectionBuilder._parseMetadata( metadataName, classFields, allowedAnnotations, displayWarning );
	}
	
	static function _getAnnotations( f : Field, allowedAnnotations : Array<String> = null, displayWarning : Bool = false ) : Array<AnnotationReflectionData>
	{
		var annotationDatas : Array<AnnotationReflectionData> = [];
		
		var metaID = f.meta.length -1;
		while ( metaID > -1 )
		{
			var m = f.meta[ metaID ];
			var annotationKeys : Array<Dynamic> = [];
			if ( allowedAnnotations == null || allowedAnnotations.indexOf( m.name )  != -1 )
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
	
	static function _parseMetadata( metadataName : String, classFields : Array<Field>, allowedAnnotations : Array<String> = null, displayWarning : Bool = false ) : Array<Field>
	{
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
			var annotationDatas = ReflectionBuilder._getAnnotations( f, allowedAnnotations, displayWarning );

			if ( annotationDatas.length > 0 )
			{
				switch ( f.kind )
				{
					case FVar( TPath( p ), e ):
						var t : haxe.macro.Type = null;
						try
						{
							t = Context.getType( p.pack.concat( [ p.name ] ).join( '.' ) );
						}
						catch ( e : Dynamic )
						{
							Context.error( e, f.pos );
						}
						
						var propertyType : String = "";
						switch ( t )
						{
							case TInst( t, p ):
								var ct = t.get();
								propertyType = ct.pack.concat( [ct.name] ).join( '.' );
								
							case TAbstract( t, params ):
								propertyType = t.toString();
								
							case TDynamic( t ):
								propertyType = "Dynamic";
								
							default:
						}

						properties.push( { annotations: annotationDatas, propertyName: f.name, propertyType: propertyType } );

					case FFun( func ) :
						var argumentDatas : Array<hex.annotation.ArgumentData> = [];
						for ( arg in func.args )
						{
							switch ( arg.type )
							{
								case TPath( p ):
									var t : haxe.macro.Type = null;
									try
									{
										t = Context.getType( p.pack.concat( [ p.name ] ).join( '.' ) );
									}
									catch ( e : Dynamic )
									{
										Context.error( e, f.pos );
									}

									var argumentType : String = "";
									switch ( t )
									{
										case TInst( t, p ):
											var ct = t.get();
											argumentType = ct.pack.concat( [ct.name] ).join( '.' );
											
										case TAbstract( t, params ):
											argumentType = t.toString();
											
										case TDynamic( t ):
											argumentType = "Dynamic";
											
										default:
									}

									argumentDatas.push( { argumentName: arg.name, argumentType: argumentType } );

								default:
							}
						}

						if ( f.name == "new" )
						{
							constructorAnnotationData = { annotations: annotationDatas, arguments: argumentDatas, methodName: f.name };
						}
						else
						{
							if ( superClassAnnotationData != null )
							{
								var methodName = f.name;
								var superMethodAnnotationDatas : Array<MethodReflectionData> = superClassAnnotationData.methods;
								for ( superMethodAnnotationData in  superMethodAnnotationDatas )
								{
									if ( superMethodAnnotationData.methodName == methodName )
									{
										methods.splice( methods.indexOf( superMethodAnnotationData ), 1 );
										break;
									}
								}
							}

							methods.push( { annotations: annotationDatas, arguments: argumentDatas, methodName: f.name } );
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