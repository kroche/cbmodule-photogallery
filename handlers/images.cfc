/**
 * ContentBox - A Modular Content Platform
 * Copyright by Kevin Roche 2023, by Ortus Solutions Corp 2012.
 * ---
 * Manage images - used by administrators and managers
 */
component extends="baseContentHandler" {

	// Dependencies
	property name="ormService"   inject="imageService@contentbox";
	property name="imageService" inject="imageService@photoGallery";

	// Properties
	variables.handler         = "images";
	variables.defaultOrdering = "createdDate desc";
	variables.entity          = "Image";
	variables.entityPlural    = "images";
	variables.securityPrefix  = "IMAGES";

	/**
	 * Pre Handler interceptions
	 */
	function preHandler( event, action, eventArguments, rc, prc ){
writedump(var=arguments, label="arguments in photoGallery preHandler", abort="1");
		super.preHandler( argumentCollection = arguments );
		// exit Handlers
		prc.xehImages      = "#prc.cbAdminEntryPoint#.images.index";
		prc.xehImageEditor = "#prc.cbAdminEntryPoint#.images.editor";
		prc.xehImageRemove = "#prc.cbAdminEntryPoint#.images.remove";
	}

	/**
	 * Show Content
	 */
	function index( event, rc, prc ){
		// exit handlers
		prc.xehImageSearch     = "#prc.cbAdminEntryPoint#.images.index";
		prc.xehImageTable      = "#prc.cbAdminEntryPoint#.images.contentTable";
		prc.xehImageBulkStatus = "#prc.cbAdminEntryPoint#.images.bulkstatus";
		prc.xehImageExportAll  = "#prc.cbAdminEntryPoint#.images.exportAll";
		prc.xehImageImport     = "#prc.cbAdminEntryPoint#.images.importAll";
		prc.xehImageClone      = "#prc.cbAdminEntryPoint#.images.clone";

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
		prc.xehImageSearch    = "#prc.cbAdminEntryPoint#.images.index";
		prc.xehImageQuickLook = "#prc.cbAdminEntryPoint#.images.quickLook";
		prc.xehImageExport    = "#prc.cbAdminEntryPoint#.images.export";
		prc.xehImageClone     = "#prc.cbAdminEntryPoint#.images.clone";
		// Super size it
		super.contentTable( argumentCollection = arguments );
	}

	/**
	 * Change the status of many imahes
	 */
	function bulkStatus( event, rc, prc ){
		arguments.relocateTo = prc.xehImages;
		super.bulkStatus( argumentCollection = arguments );
	}

	/**
	 * Show the image editor
	 */
	function editor( event, rc, prc ){
		arguments.adminPermission = "IMAGES_ADMIN,IMAGES_EDITOR,NEW_REGISTRATION";
		// Super size it
		super.editor( argumentCollection = arguments );
	}

	/**
	* Display the page to upload an image
	*/
	function new( event, rc, prc ){
		arguments.adminPermission = "IMAGES_ADMIN,IMAGES_EDITOR";
		arguments.cancelTo = prc.xehImages;
		arguments.saveTo   = prc.xehImageEditor
		event.setView( "image/new" );
	}

	/**
	 * Save an image
	 */
	function save( event, rc, prc ){
		arguments.adminPermission = "IMAGES_ADMIN,IMAGES_EDITOR,NEW_REGISTRATION";
		arguments.relocateTo      = prc.xehImages;
		super.save( argumentCollection = arguments );
	}

	/**
	 * Upload an image
	 */
	function upload( event, rc, prc ){
		//arguments.adminPermission = "IMAGES_ADMIN,IMAGES_EDITOR,NEW_REGISTRATION";

		// Upload the image			// TODO: also allow zip files
		local.files = fileUploadAll( imageService.getTempImageDirectory(), "", "makeunique");

		// loop over the uploaded files
		for (local.i = 1; local.i <= arrayLen(local.files); local.i++) {
			local.image    = local.files[local.i];
			local.img      = imageRead(local.image.serverDirectory & "/" & local.image.serverFile);
			local.exifData = ImageGetEXIFMetadata(local.img);
//writedump(var=local.exifData, label="local.exifData line 115", abort="1");
			
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
	
	
*/
			
			imageData = {
				originalName   = local.image.clientFile,
				serverFileName = local.image.serverfile,
				height         = local.exifData.height ?: val(local.exifData[ "Image Height" ]),
				width          = local.exifData.width  ?: val(local.exifData[ "Image Width" ])
			};

			local.oImage = populateModel( model="Image@photoGallery", memento=imageData );
			local.result = ormService.save( local.oImage );
			
writedump(var=local.result, label="local.result line 174", abort="1");

			//imageService.saveUploadedImage(local.files[i], local.oImage);
			
writedump(var=local.oImage, label="local.oImage line 179", abort="1");

writedump(var=session, label="session", abort="1");		


			
    		//fileMove("#local.files[i].serverDirectory#/#local.files[i].serverFile#", imageService.makeImageFilePath(local.oPost.getId(), local.files[i].serverfileext));

		}
		
		// TODO: create resized versions of the uploaded image 

		//messagebox.info( "Image uploaded!" );
		relocate( URI="/posts" );
	}


	/**
	 * Clone an image
	 */
	function clone( event, rc, prc ){
		arguments.relocateTo = prc.xehImages;
		super.clone( argumentCollection = arguments );
	}

	/**
	 * Remove an image
	 */
	function remove( event, rc, prc ){
		arguments.relocateTo = prc.xehImages;
		super.remove( argumentCollection = arguments );
	}

	/**
	 * Editor selector for images UI
	 */
	function editorSelector( event, rc, prc ){
		// Sorting
		arguments.sortOrder = "publishedDate asc";
		// Supersize me
		super.editorSelector( argumentCollection = arguments );
	}

	/**
	 * Import images
	 */
	function importAll( event, rc, prc ){
		arguments.relocateTo = prc.xehImages;
		super.importAll( argumentCollection = arguments );
	}

}