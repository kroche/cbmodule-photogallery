/**
 * ContentBox - A Modular Content Platform
 * Copyright by Kevin Roche 2023, by Ortus Solutions Corp 2012.
 * ---
 * Manage media - used by administrators and managers
 */
component extends="modules.contentbox.modules.contentbox-admin.handlers.baseContentHandler" {

	// Dependencies
	property name="MediaService" inject="mediaService@photoGallery";
	property name="messagebox"   inject="MessageBox@cbmessagebox";

	// Properties
	variables.handler         = "media";
	variables.defaultOrdering = "createdDate desc";
	variables.entity          = "Media";
	variables.entityPlural    = "media";
	variables.securityPrefix  = "MEDIA";

	// Configuration
	variables.homeSiteList    = "e4f604a68ac19104018ac19319b600af,e4f604a68ac19104018ac1931b030109";
	variables.thumbnailSize   = 150;

//writedump(var=variables, label="variables line 19 in media handler", top=2);
	/**
	 * Pre Handler interceptions
	 */
	function preHandler( event, action, eventArguments, rc, prc ){
//writedump(var=arguments, label="arguments in photoGallery preHandler", top=2, abort="1");
		super.preHandler( argumentCollection = arguments );
		// Prepare UI Request
		variables.CBHelper.prepareUIRequest();
		// exit Handlers
		//prc.xehMedias      = "#prc.cbAdminEntryPoint#.media.index";
		//prc.xehMediaEditor = "#prc.cbAdminEntryPoint#.media.editor";
		//prc.xehMediaRemove = "#prc.cbAdminEntryPoint#.media.remove";
	}

	/**
	 * Show Content
	 */
	function index( event, rc, prc ){
		// exit handlers
		prc.xehMediaSearch     = "#prc.cbAdminEntryPoint#.media.index";
		prc.xehMediaTable      = "#prc.cbAdminEntryPoint#.media.contentTable";
		prc.xehMediaBulkStatus = "#prc.cbAdminEntryPoint#.media.bulkstatus";
		prc.xehMediaExportAll  = "#prc.cbAdminEntryPoint#.media.exportAll";
		prc.xehMediaImport     = "#prc.cbAdminEntryPoint#.media.importAll";
		prc.xehMediaClone      = "#prc.cbAdminEntryPoint#.media.clone";

		// Light up
		prc.tabContent_blog = true;

		// Super size it
		super.index( argumentCollection = arguments );
	}

	/**
	 * Content table brought via ajax
	 */
	function contentTable( event, rc, prc ){
		// exit handlers
		prc.xehMediaSearch    = "#prc.cbAdminEntryPoint#.media.index";
		prc.xehMediaQuickLook = "#prc.cbAdminEntryPoint#.media.quickLook";
		prc.xehMediaExport    = "#prc.cbAdminEntryPoint#.media.export";
		prc.xehMediaClone     = "#prc.cbAdminEntryPoint#.media.clone";
		// Super size it
		super.contentTable( argumentCollection = arguments );
	}

	/**
	 * Change the status of many imahes
	 */
	function bulkStatus( event, rc, prc ){
		arguments.relocateTo = prc.xehMedias;
		super.bulkStatus( argumentCollection = arguments );
	}

	/**
	 * Show the media editor
	 */
	function editor( event, rc, prc ){
		arguments.adminPermission = "MEDIA_ADMIN,MEDIA_EDITOR,NEW_REGISTRATION";
		// Super size it
		super.editor( argumentCollection = arguments );
	}

	/**
	* Display the page to upload media
	*/
	function new( event, rc, prc ){
		arguments.adminPermission = "MEDIA_ADMIN,MEDIA_EDITOR";
		arguments.cancelTo = prc.xehMedia;
		arguments.saveTo   = prc.xehMediaEditor;
		event.setView( "media/new" );
	}

	/**
	 * Save media object
	 */
	function save( event, rc, prc ){
		arguments.adminPermission = "MEDIA_ADMIN,MEDIA_EDITOR,NEW_REGISTRATION";
		arguments.relocateTo      = prc.xehMedia;
		super.save( argumentCollection = arguments );
	}

	/**
	 * Upload media
	 */
	function upload( event, rc, prc ){
		//arguments.adminPermission = "MEDIA_ADMIN,MEDIA_EDITOR,NEW_REGISTRATION";

		// Upload the media			// TODO: also allow zip files
		local.files = fileUploadAll( mediaService.getTempMediaDirectory(), "", "makeunique");
		// TODO: local.files will be an empty array if nothing was uploaded
		// loop over the uploaded files
		for (local.i = 1; local.i <= arrayLen(local.files); local.i++) {
			local.media    = local.files[local.i];
			local.img      = imageRead(local.media.serverDirectory & "/" & local.media.serverFile);
			local.exifData = local.img.getEXIFMetadata();
			local.iptcData = local.img.getIptcMetadata();

//writedump(var=local.exifData, label="local.exifData line 122");
//writedump(var=local.iptcData, label="local.iptcData", top=2, abort=1);
			
/**  Interesting EXIF values by manufacturer
  exif.Make = SONY
  Make = SONY
	Aperture Value			"f/6.7"
	Color Space				"RGB"
	Color Transform			"YCbCr"
	Date/Time Original		"2023:02:26 13:45:58"
	DateTimeOriginal		"2023:02:26 13:45:58"
	exif.DateTimeOriginal	"2023:02:26 13:45:58"
	exif.ExposureTime  		"1/200 (0.005)"
	exif.FNumber  			"67/10 (6.7)"
	exif.FocalLength   		"52"
	exif.LensModel    		"E 35-150mm F2.0-F2.8 A058"
	exif.Model    			"ILCE-7RM5"
	Exif Version			"2.32"
	Exposure Time  			"1/200 sec"
	ExposureTime  			"1/200 (0.005)"
	F-Number   				"f/6.7"
	Focal Length  			"52 mm"
	height					"1080"
	Image Height			"1080 pixels"
	Image Width				"864 pixels""
	metadata.Dimension.ImageOrientation 	"normal"
	ISO Speed Ratings		"100"
	Model					"ILCE-7RM5"
	Resolution Info			"240x240 DPI"
	Resolution Unit			"Inch"
	Shutter Speed Value		"1/199 sec"
	White Balance			"Unknown"
	White Balance Mode      "Auto white balance"
	width					"864"
	X Resolution 			"240 dots per inch"
	XResolution				"72"
	Y Resolution 			"240 dots per inch"
	YResolution				"72"
	
Lightroom ?..
	Copyright
	Copyright Notice
	exif.Copyright
	exif.Software
	exif.XResolution		"72"
	exif.YResolution 		"72"
	
	
IPTC Data

	Date Created	 	        string	20230226
	Digital Creation Date		string	20230226
	Digital Creation Time		string	134528+0000
	Keywords					string	Scandi Chic;_Model_
	Time Created				string	134528+0000

*/

			local.exifList = "Color Space,F-Number,Exposure Time,Focal Length,Make,Model,White Balance,White Balance Mode";
			local.iptcList = "Date Created,Time Created,Keywords";
			local.metaData = {};

			for( local.metaItem in local.exifList) {
				local.metaData[metaItem] = local.exifData[metaItem] ?: "";
			}
			for( local.metaItem in local.iptcList) {
				local.metaData[metaItem] = local.iptcData[metaItem] ?: "";
			}
//writedump(var=local.metaData, label="local.metaData", top=2, abort="1");

//  getEXIFMetadata,getEXIFTag,getIptcMetadata,getIPTCTag

			// Does prc contain oCurrentAuthor and oCurrentSite? In which case we can save the media object straight away.
			local.saveMedia = prc.keyExists( "oCurrentAuthor" ) and prc.keyExists( "oCurrentSite" )
// TODO: Remove temporary test code
			local.saveMedia = false;

			// Does prc only contain oCurrentSite? Then we check if the site is the home site, in which case the media object is cached in the session scope.
			local.cacheMedia = !local.saveMedia and prc.keyExists( "oCurrentSite" ) and variables.homeSiteList.listFindNoCase( prc.oCurrentSite.getSiteID() );
// TODO: Remove temporary test code
			//local.cacheMedia = true;
//writedump(var=local.media, label="local.media", top=2);
			local.mediaData = {
				originalName   = local.media.clientFileName,
				serverFileName = local.media.serverFileName,
				fileType       = local.media.serverFileExt,
				inTempStorage  = true,
				metadata       = "",
				mediaType      = local.media.contentType & "/" & local.media.contentSubType,
				height         = local.exifData.height ?: val(local.exifData[ "Image Height" ]),
				width          = local.exifData.width  ?: val(local.exifData[ "Image Width" ]),
				metadata       = serializeJSON(local.metaData)
			};

			local.oMedia = populateModel( model="Media@photoGallery", memento=local.mediaData );
//writedump(var=local.mediaData, label="local.mediaData", top=3, abort="1");

			// Save or cache the media object
			if ( local.saveMedia ) {
				local.oMedia.setSite( prc.oCurrentSite );
				local.oMedia.setCreator( prc.oCurrentAuthor );
				local.result = MediaService.save( local.oMedia );
			}
			if ( local.cacheMedia ) {
				if ( !structKeyExists( session, "registrationData" ) ){
					session.registrationData = { media = [] };
				}
				arrayAppend( session.registrationData.media, local.oMedia );
			}
			// create resized versions of the uploaded media 
			
			local.oMedia.createThumbnail( variables.thumbnailSize, local.img );

			//local.thumbnailFileName  = local.media.serverDirectory & "/";
			//local.thumbnailFileName &= local.media.serverFileName & "_#variables.thumbnailSize#.";
			//local.thumbnailFileName &= local.media.serverFileExt;

			//local.img.resize( variables.thumbnailSize,"");
			//local.img.write( destination=local.thumbnailFileName, quality=0.9, overwrite=true);


//fileMove("#local.files[i].serverDirectory#/#local.files[i].serverFile#", mediaService.makeMediaFilePath(local.oPost.getId(), local.files[i].serverfileext));

		}

	//messagebox.info( "Media uploaded!" );
	}


	/**
	 * Clone media
	 */
	function clone( event, rc, prc ){
		arguments.relocateTo = prc.xehMedia;
		super.clone( argumentCollection = arguments );
	}

	/**
	 * Remove media
	 */
	function remove( event, rc, prc ){
		arguments.relocateTo = prc.xehMedia;
		super.remove( argumentCollection = arguments );
	}

	/**
	 * Editor selector for media UI
	 */
	function editorSelector( event, rc, prc ){
		// Sorting
		arguments.sortOrder = "publishedDate asc";
		// Supersize me
		super.editorSelector( argumentCollection = arguments );
	}

	/**
	 * Import media
	 */
	function importAll( event, rc, prc ){
		arguments.relocateTo = prc.xehMedia;
		super.importAll( argumentCollection = arguments );
	}
}

