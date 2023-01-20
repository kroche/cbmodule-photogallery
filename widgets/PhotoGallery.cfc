/**
* A widget that renders a gallery of the photos in a folder.
*/
component extends="contentbox.models.ui.BaseWidget" singleton{

	property name="settingService" 	inject="settingService@contentbox";

	PhotoGallery function init(controller){
		// super init
		super.init(controller);

		// Widget Properties
		setName("PhotoGallery");
		setVersion("2.0");
		setDescription("A widget that renders a gallery of the photos in a folder.");
		setForgeBoxSlug("cbwidget-photogallery");
		setAuthor("Computer Know How, LLC");
		setAuthorURL("http://www.compknowhow.com");
		setIcon( "image" );
		setCategory( "Utilities" );
		return this;
	}

	/**
	* Renders a photo gallery
	* @folder.hint The folder (relative to the ContentBox content root) from which to list the gallery of photos
	* @filter.hint A list of file extension filters to apply (*.jpg), use a | to separate multiple filters
	* @sort.hint The sort field (Name, Size, DateLastModified)
	* @order.hint The sort order of the photos (ASC/DESC)
	* @rowsPerPage.hint The number of rows of images to display
	* @rowsPerPage.type numeric
	* @imagesPerRow.hint The number of images to display per row
	* @imagesPerRow.type numeric
	* @navPosition.hint The position of the previous and next buttons on the gallery page
	* @navPosition.type string
	* @navPosition.options above,below,each side
	* @showOnPage.hint when a user clicks on an image should the link go to a page or the image itself?
	* @showOnPage.type boolean
	* @class.hint Class(es) to apply to the gallery
	
	*/
	
	// cbwire helper
	include "\modules\cbwire\helpers\helpers.cfm";

	any function renderIt(string folder, string filter="*", string sort="Name", string order="ASC", numeric rowsPerPage=0, numeric imagesPerRow=0, string navPosition="each side", boolean showOnPage=true, string class="" ){
		var event = getRequestContext();
		rc = event.getCollection();

		rc.startImage = rc.startImage ?: 1;
		var startImage = val(rc.startImage);
		if (startImage lt 1){ startImage = 1; };

		var oneImage = rc.oneImage ?: false;

		var relativePath = "";
		var cbSettings = event.getValue(name="cbSettings",private=true);
		var sortOrder = arguments.sort & " " & arguments.order;
		var mediaRoot = expandPath(cbSettings.cb_media_directoryRoot);
		var mediaPath = cbSettings.cb_media_directoryRoot & "/" & arguments.folder;
		var mediaPathExpanded = expandPath(mediaPath);
		var galleryPath = event.buildLink("__media/#arguments.folder#/_photogallery");

		if(!len(arguments.folder)){
			return "Please specify a folder";
		}

		if(!directoryExists(mediaPathExpanded)){
			return "The folder specified does not exist";
		}

		//security check - can't be higher than the media root
		if(!findNoCase(mediaRoot, mediaPathExpanded)){
			return "This widget is restricted to the ContentBox media root.  All photo galleries must be contained within that directory.";
		}

		var navPosition = listFindNoCase("above,below,each side", arguments.navPosition) ? arguments.navPosition : "each side";

		// get a query containing all the images
		var gallery = directoryList(mediaPathExpanded,false,"query",arguments.filter,sortOrder);
		var query = new Query();
		query.setAttributes(directoryListing = gallery);

		var qryGalleryFolders = query.execute(sql="select * from directoryListing where type = 'Dir' and name <> '_photogallery'", dbtype="query");
		var qryGalleryPhotos = query.execute(sql="select * from directoryListing where type = 'File'", dbtype="query");

		var galleryFolders = qryGalleryFolders.getResult();
		var galleryPhotos = qryGalleryPhotos.getResult();
		var maxPhotosPerPage = (rowsPerPage * imagesPerRow) GT 0 ? (rowsPerPage * imagesPerRow) : settings.maxPhotosPerPage;
		var maxPhotosPerRow = (imagesPerRow) GT 0 ? (imagesPerRow) : settings.maxPhotosPerRow;
		
		var settings = deserializeJSON(settingService.getSetting( "photo_gallery" ));
		
		// set sizes for layout and images on the current page
		var displaySize     = oneImage ? "normal" : "small";
		var maxImages       = oneImage ? 1 : maxPhotosPerPage;
		var maxImagesPerRow = oneImage ? 1 : maxPhotosPerRow;
		var marginLeft      = oneImage ? "200px" : "0";
		var marginTop       = "200px";
		var imageWidth      = settings.imageSize[#displaySize#].resizeWidth;
		var imageHeight     = settings.imageSize[#displaySize#].resizeHeight ;
		
		// calculate the number of pages and which page we are on
		var totalPages = ceiling(galleryPhotos.recordCount / maxImages);
		var thisPage = ceiling(startImage / maxImages);

		// generate photo gallery
		saveContent variable="rString"{
			writeOutput('
				<style>
					.cb-photogallery {
						margin: 0 auto 0 auto;
					}

					.cb-photogallery-tiles {
						overflow: hidden;
						float: left;
					}

					.cb-photogallery-tile {
						float: left;
						border-radius: 3px;
						-webkit-box-shadow: 0 0 7px rgba(0, 0, 0, 0.5);
						-moz-box-shadow: 0 0 7px rgba(0, 0, 0, 0.5);
						box-shadow: 0 0 7px rgba(0, 0, 0, 0.5);
						position: relative;
						width: #imageWidth#px;
						margin: 0 20px 20px 0;
						background-color: ##fff;
					}
					
					.cb-photogallery-newline {
						clear: both;
					}

					.cb-photogallery-tile img {
						display: block;
						overflow: hidden;
						position: relative;
						width: #imageWidth#px;
						border-radius: 3px;
					}

					.fa-2xl {
						font-size: 32px;
					}

					.cb-photogallery-previcon, .cb-photogallery-nexticon {
						float: left;
					}

					.cb-photogallery-previcon {
						margin-left: #marginLeft#;
						margin-right: 20px;
					}
					
					.cb-photogallery-previcon,
					.cb-photogallery-nexticon {
						margin-top: #marginTop#;
					}
					
					.cb-photogallery-previcon .cb-photogallery-prevlink, 
					.cb-photogallery-nexticon .cb-photogallery-nextlink{
						float: left;
					}
					
					.cb-photogallery-prevpage {
						float: left;
						width: 45%;
						margin-right: 20px;
					}
					.cb-photogallery-pageinfo {
						float: left;
						width: 50%;
					}
					
					.cb-photogallery-pageinfo-center {
						width: 100%;
						text-align: center;
						float: left;
					}
					
					.cb-photogallery-nextpage  {
						float: right;
					}
					
					.widget-preview-content .cb-photogallery-tile,
					.widget-preview-content a.cb-photogallery-nextlink,
					.widget-preview-content a.cb-photogallery-prevlink {
						pointer-events: none;
						cursor: not-allowed;
					}

					.cb-photogallery-pageinfo:before {
						content: "(";
					}

					.cb-photogallery-pageinfo:after {
						content: ")";
					}

					span.cb-photogallery-prevlink,
					span.cb-photogallery-nextlink {
						cursor: not-allowed;
					}
				</style>
			');

			wireArgs = {
				mediaPathExpanded = mediaPathExpanded,
				filter = arguments.filter,
				sortOrder = sortOrder,
				galleryPath = galleryPath,
				startImage = startImage,
				maxImages = maxImages,
				totalPages = totalPages,
				imageCount = galleryPhotos.recordCount,
				class = arguments.class,
				navPosition = navPosition,
				showOnPage = showOnPage,
				maxImgPerRow = imagesPerRow,
				displaySize = displaySize,
				oneImage = oneImage
			};

			// Generate the HTML for the gallery
			writeOutput('#wire( "gallery", wireArgs )#');
		}

		return rString;
	}

}