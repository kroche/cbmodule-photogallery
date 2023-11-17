/**
 * ContentBox Image Object
 * Copyright: Kevin Roche
 * rochek@gmail.com
 * ---
 * I am an image entity designed for use with contentbox
 */
component
	persistent        ="true"
	entityname        ="cbImage"
	table             ="cb_image"
	batchsize         ="25"
	cachename         ="cbImage"
	cacheuse          ="read-write"
	extends           ="modules.contentbox.models.content.BaseContent"
	joinColumn        ="contentID"
	discriminatorValue="Image"
{

	/* *********************************************************************
	 **							PROPERTIES
	 ********************************************************************* */

	/**
	 * The description of the image
	 */
	property
		name   ="description"
		column ="description"
		notnull="false"
		length ="8000"
		default="";

	/**
	 * The ordering numeric sequence
	 */
	property
		name   ="order"
		column ="order"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The fileType of the image
	 */
	property
		name   ="fileType"
		column ="fileType"
		notnull="false"
		ormtype="varchar"
		default="";

	/**
	 * The width of the image
	 */
	property
		name   ="width"
		column ="width"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The height of the image
	 */
	property
		name   ="height"
		column ="height"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The crop X position of the image
	 */
	property
		name   ="cropXpos"
		column ="cropXpos"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The crop Y position of the image
	 */
	property
		name   ="cropYpos"
		column ="cropYpos"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The crop width of the image
	 */
	property
		name   ="cropWidth"
		column ="cropWidth"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The crop height of the image
	 */
	property
		name   ="cropHeight"
		column ="cropHeight"
		notnull="false"
		ormtype="integer"
		default="0";

	/**
	 * The original filename of the image
	 */
	property
		name   ="originalName"
		column ="originalName"
		notnull="false"
		length ="8000"
		default="";
		
	/**
	 * The server filename of the image
	 */
	property
		name   ="serverFileName"
		column ="serverFileName"
		notnull="false"
		length ="8000"
		default="";

	/**
	 * The metadata from the image
	 */
	property
		name   ="metadata"
		column ="metadata"
		notnull="false"
		length ="8000"
		default="";


	/* *********************************************************************
	 **							NON PERSISTED PROPERTIES
	 ********************************************************************* */


	/* *********************************************************************
	 **							CONSTRAINTS
	 ********************************************************************* */

	this.constraints[ "description" ]    = { required : false, size : "1..8000" };
	this.constraints[ "order" ]          = { required : true,  type : "numeric" };
	this.constraints[ "fileType" ]       = { required : false, size : "1..20"   };
	this.constraints[ "width" ]          = { required : true,  type : "numeric" };
	this.constraints[ "height" ]         = { required : true,  type : "numeric" };
	this.constraints[ "cropXpos" ]       = { required : false, type : "numeric" };
	this.constraints[ "cropYpos" ]       = { required : false, type : "numeric" };
	this.constraints[ "cropWidth" ]      = { required : false, type : "numeric" };
	this.constraints[ "cropHeight" ]     = { required : false, type : "numeric" };
	this.constraints[ "originalName" ]   = { required : false, size : "1..8000" };
	this.constraints[ "serverFileName" ] = { required : false, size : "1..8000" };
	this.constraints[ "metadata" ]       = { required : false, size : "1..8000" };

	/* *********************************************************************
	 **							CONSTRUCTOR
	 ********************************************************************* */

	function init(){
		appendToMemento( [ "description", "order", "fileType", "width", "height", "cropXpos", "cropYpos", "cropWidth", "cropHeight", "originalName", "serverFileName", "metadata" ], "defaultIncludes" );

		super.init();

		variables.categories      = [];
		variables.customFields    = [];
		variables.renderedContent = "";
		variables.renderedExcerpt = "";
		variables.allowComments   = true;
		variables.createdDate     = now();
		variables.layout          = "images";
		variables.contentType     = "Image";
		variables.order           = 0;
		variables.fileType        = "";
		variables.description     = "";
		variables.width           = 0;
		variables.height          = 0;
		variables.cropXpos        = 0;
		variables.cropYpos        = 0;
		variables.cropWidth       = 0;
		variables.cropHeight      = 0;
		variables.originalName    = "";
		variables.serverFileName  = "";
		variables.metadata        = "";
		return this;
	}

	/* *********************************************************************
	 **							PUBLIC FUNCTIONS
	 ********************************************************************* */

	boolean function isCropped(){
		if (    cropWidth  LT width
			or  cropHeight LT height
			){
			return true;
		}
		
		return false;
	}

	any function renderExcerpt(){
		// Check if we need to translate
		if ( NOT len( variables.renderedExcerpt ) ) {
			lock name="contentbox.excerptrendering.#getContentID()#" type="exclusive" throwontimeout="true" timeout="10" {
				if ( NOT len( variables.renderedExcerpt ) ) {
					// render excerpt out, prepare builder
					var builder = createObject( "java", "java.lang.StringBuilder" ).init( getExcerpt() );
					// announce renderings with data, so content renderers can process them
					variables.interceptorService.announce(
						"cb_onContentRendering",
						{ builder : builder, content : this }
					);
					// store processed content
					variables.renderedExcerpt = builder.toString();
				}
			}
		}

		return variables.renderedExcerpt;
	}

	// TODO: It may be best to provide a range of functions to output several different sized images.
	//       Each different template may require different sized images
	//       The images could be cached in the required sizes at upload time
	//       A process to create a new set may be needed when the template changes
	
	any function renderSmall(){
		return 1;
	}
	
	
	any function renderMedium(){
		return 1;
	}
	
	
	any function renderLarge(){
		return 1;
	}


	/**
	 * Wipe primary key, and descendant keys, and prepare for cloning of entire hierarchies
	 *
	 * @author           The author doing the cloning
	 * @original         The original content object that will be cloned into this content object
	 * @originalService  The ContentBox content service object
	 * @publish          Publish pages or leave as drafts
	 * @originalSlugRoot The original slug that will be replaced in all cloned content
	 * @newSlugRoot      The new slug root that will be replaced in all cloned content
	 */
	BaseContent function clone(
		required any author,
		required any original,
		required any originalService,
		required boolean publish,
		required any originalSlugRoot,
		required any newSlugRoot
	){
		// Do page property cloning
		setDescription( arguments.original.getDescription() );
		setOrder( arguments.original.getOrder() );
		setWidth( arguments.original.getWidth() );
		setHeight(arguments.original.getHeight() );
		setcropXpos( arguments.original.getcropXpos() );
		setcropYpos( arguments.original.getcropYpos() );
		setCropWidth( arguments.original.getCropWidth() );
		setCropHeight( arguments.original.getCropHeight() );

		// do core cloning
		return super.clone( argumentCollection = arguments );
	}


/* TODO: May need to provide alternatives for the following methods in BaseContent */
	/**
	 * Build content cache keys according to sent content object
	 */
	/*string function buildContentCacheKey(){
		var inputHash = hash( cgi.HTTP_HOST & cgi.query_string );
		return "cb-content-#getContentType()#-#getContentID()#-#i18n.getfwLocale()#-#inputHash#";
	}*/

	/**
	 * This builds a partial cache key so we can clean from the cache many permutations of the content object
	 */
	/*string function buildContentCacheCleanupKey(){
		return "cb-content-#getContentType()#-#getContentID()#";
	}*/

	/**
	 * Verify we can do content caching on this content object using global and local rules
	 */
	/*boolean function canCacheContent(){
		var settings = variables.settingService.getAllSettings();

		// check global caching first
		if (
			( getContentType() eq "page" AND settings.cb_content_caching ) OR
			( getContentType() eq "entry" AND settings.cb_entry_caching )
		) {
			// check override in local content bit
			return ( getCache() ? true : false );
		}
		return false;
	}*/


	/**
	 * Render content out using caching, etc.
	 */
	//any function renderContent(){}
	// TODO: will need to return an image

	/**
	 * Renders the content silently so no caching, or extra fluff is done, just content translation rendering.
	 *
	 * @content The content markup to translate, by default it uses the active content version's content
	 */
	/*
	any function renderContentSilent( any content = getContent() ) profile{
		// render content out, prepare builder
		var builder = createObject( "java", "java.lang.StringBuilder" ).init( arguments.content );
		// announce renderings with data, so content renderers can process them
		interceptorService.announce( "cb_onContentRendering", { builder : builder, content : this } );
		// return processed content
		return builder.toString();
	}*/
	
	

}