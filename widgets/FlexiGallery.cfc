/**
* A widget that renders a flexible gallery of the photos in a folder.
*/
component extends="contentbox.models.ui.BaseWidget" singleton{

	property name="settingService" 	inject="settingService@contentbox";

	FlexiGallery function init(controller){
		// super init
		super.init(controller);

		// Widget Properties
		setName("FlexiGallery");
		setVersion("0.1");
		setDescription("A widget that renders a gallery of photos with a choice of formats.");
		setForgeBoxSlug("cbwidget-flexigallery");
		setAuthor("Ziblix");
		setAuthorURL("http://www.ziblix.co.uk");
		setIcon( "images" );
		setCategory( "Content" );
		return this;
	}

	/**
	* Render a gallery
	* @folder.hint     The folder (relative to the ContentBox content root) from which to list the gallery of photos
	* @filter.hint     A list of file extension filters to apply (*.jpg), use a | to separate multiple filters
	* @sort.hint       The sort field (Name, Size, DateLastModified)
	* @order.hint      The sort order of the photos (ASC/DESC)
	* @format.hint     The format to display the gallery choose from justified, square, cascade or single 
	* @minHeight.hint  The Minimum Height of the gallery images in pixels (250) applies to justified format only
	* @maxHeight.hint  The Maximum Height of the gallery images in pixels (350) applies to justified format only
	* @minWidth.hint   The Minimum Width of the gallery images in pixels (300) applies to square, cascade or single formats only
	* @spacing.hint    The gap in pixels bewteen images (5) applies to all formats
	*/
	any function renderIt(
			string  folder,
			string  filter    = "*",
			string  sort      = "Name",
			string  order     = "ASC",
			string  format    = "justified",
			numeric minHeight = 250,
			numeric maxHeight = 350,
			numeric minWidth  = 300,
			numeric spacing   = 5
		){
		var event = getRequestContext();
		rc = event.getCollection();

		rc.startRow  = rc.startRow ?: 1;
		var startRow = val(rc.startRow);
		if (startRow lt 1){
			startRow = 1;
		};

		var relativePath = "";
		var cbSettings = event.getValue(name="cbSettings",private=true);
		var sortOrder = arguments.sort & " " & arguments.order;
		var mediaRoot = expandPath(cbSettings.cb_media_directoryRoot);
		var mediaPath = cbSettings.cb_media_directoryRoot & "/" & arguments.folder;
		var mediaPathExpanded = expandPath(mediaPath);
		var galleryPath = event.buildLink("__media/#arguments.folder#/");

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

		// get a query containing all the images
		var gallery = directoryList(mediaPathExpanded,false,"query",arguments.filter,sortOrder);
		var query = new Query();
		query.setAttributes(directoryListing = gallery);

		var qryGalleryFolders = query.execute(sql="select * from directoryListing where type = 'Dir' and name <> '_photogallery'", dbtype="query");
		var qryGalleryPhotos = query.execute(sql="select * from directoryListing where type = 'File'", dbtype="query");

		var galleryFolders = qryGalleryFolders.getResult();
		var galleryPhotos = qryGalleryPhotos.getResult();

		var settings = deserializeJSON(settingService.getSetting( "photo_gallery" ));
		//writedump(var=qryGalleryPhotos, label="qryGalleryPhotos", abort="1");

		// loop over the images
		var imageString = "images = [";
		for (var x=startRow; x lte galleryPhotos.recordcount; x++) {
			imageString &= "'#galleryPath#/#galleryPhotos.name[x]#'";
			if ( x lt galleryPhotos.recordcount ) {
				imageString &= ',';
			}
		}
		imageString &= ']';
		//<img src="#galleryPath#/#displaySize#/#galleryPhotos.name[x]#" title="#galleryPhotos.name[x]#" alt="#galleryPhotos.name[x]#" class="cb-photogallery-image" rel="group">

		// generate photo gallery
		var rString = "";
		saveContent variable="rString" {
			// HTML for the gallery
			writeOutput('<div id="gallery" style="flex"></div>');

			// Javascript for the gallery
			writeOutput("
				<script>
				function showGallery() {

					const minHeight = #arguments.minHeight#;
					const maxHeight = #arguments.maxHeight#;
					const minWidth  = #arguments.minWidth#;
					const spacing   = #arguments.spacing#;
					const format    = '#arguments.format#';

					// where will we display the images
					const gallery = document.querySelector('##gallery');

					// TODO: Change so this is done with an ajax call
					// Get an array of images from server
					#imageString#

					// call the chosen formatter
					switch(format) {
						case 'justified':
							justifyGallery( gallery, images, minHeight, maxHeight, minWidth, spacing );
							break;
						case 'cascade':
							cascadeGallery( gallery, images, format, minHeight, maxHeight, minWidth, spacing );
							break;
						case 'single':
							cascadeGallery( gallery, images, format, minHeight, maxHeight, minWidth, spacing );
							break;
						default:
							cascadeGallery( gallery, images, 'square', minHeight, maxHeight, minWidth, spacing );
					}
					// add mouse overs
					addMouseOver();
				}

				function justifyGallery( gallery, images, minHeight, maxHeight, minWidth, spacing ) {
					// Set variables to track current row width at max and min height
					let rowMaxWidth = spacing;
					let rowMinWidth = spacing;

					// Initialise current row to add images
					let currRow = [];
					// Gallery
					let galleryWidth = gallery.offsetWidth - spacing - 13; // 13 is the scroll bar allowance

					// Initialise variables
					let imgWidth = 0;
					let imgHeight = 0;
					let imgWidthResizeMax = 0;
					let imgWidthResizeMin = 0;

					// Loop over the array of image URLs and create the HTML
					images.forEach(imageURL => {
						createImage( imageURL, gallery, null, spacing );
					})

					// Greate an array of the div objects containg each img
					let imgDivs = gallery.childNodes;

					// Loop over the array of divs
					imgDivs.forEach(container => {
						// Get image width and height including margins
						img = container.firstChild;
						imgWidth  = img.naturalWidth;
						imgHeight = img.naturalHeight;

						// Calculate the min and max width based on min and max height
						imgWidthResizeMax = Math.round(imgWidth * maxHeight / imgHeight);
						imgWidthResizeMin = Math.round(imgWidth * minHeight / imgHeight);

						// Check if current row is empty
						if(currRow.length === 0) {
							// If empty start new row  
							currRow.push(container);
							rowMaxWidth += (imgWidthResizeMax + spacing);
							rowMinWidth += (imgWidthResizeMin + spacing);
						} else {
							// If image fits at maximum size add it to the row
							if((rowMaxWidth + imgWidthResizeMax) <= (galleryWidth - spacing)) {
								currRow.push(container);
								rowMaxWidth += (imgWidthResizeMax + spacing);
								rowMinWidth += (imgWidthResizeMin + spacing);

							// If image only fits at minimum size add it to the row and start a new row
							} else if((rowMinWidth + imgWidthResizeMin) <= (galleryWidth - spacing)) {
								currRow.push(container);
								(rowMaxWidth += imgWidthResizeMax + spacing);
								(rowMinWidth += imgWidthResizeMin + spacing);
								
								justifyRow(currRow, galleryWidth, rowMaxWidth, maxHeight, spacing);
								
								currRow = [];
								rowMaxWidth = spacing;
								rowMinWidth = spacing;
							
							} else {
								// If it does not fit either way start a new row
								justifyRow(currRow, galleryWidth, rowMaxWidth, maxHeight, spacing);
				
								// Start new row
								currRow = [];
								currRow.push(container);
								rowMaxWidth = imgWidthResizeMax + spacing;
								rowMinWidth = imgWidthResizeMin + spacing;
							}
						}
					});
					// Justify last row
					justifyRow(currRow, galleryWidth, rowMaxWidth, maxHeight, spacing);
				}

				function createImage( imageURL, container, width, spacing,  ) {
					if (width === null) {
						container.innerHTML += ('<div style=""margin-top: ' + spacing + 'px; margin-left: '+ spacing + 'px;""><img src=""' + imageURL + '""></div>');
					} else {
						container.innerHTML += ('<div style=""margin-top: ' + spacing + 'px; margin-left: '+ spacing + 'px;""><img src=""' + imageURL + '"" width=""' + width +'""></div>');
					}
				}

				function justifyRow(row, galleryWidth, rowMaxWidth, maxHeight, spacing) {
					let totalMargin      = (row.length + 1) * spacing;
					let totalImageWidths = galleryWidth - totalMargin;
					let resizeHeight     = Math.trunc(maxHeight * galleryWidth / rowMaxWidth);
					let img = '';
					let height = Math.min(maxHeight, resizeHeight);

					row.forEach((imgDiv) => {
						imgDiv.style.float = 'left';
						imgDiv.style.height = (height + spacing) + 'px';
						imgDiv.height = (height + spacing) + 'px';
						img = imgDiv.firstElementChild;
						img.style.height = height + 'px';
						img.height = height + 'px';
					});
				}

				function cascadeGallery( gallery, images, format, minHeight, maxHeight, minWidth, spacing ) {
					// Initialise variables
					let galleryHTML   = '';
					let columnElement = 0;
					let imageElement  = 0;
					let colCount = 1;
					let resizeWidth = minWidth;
					let galleryWidth = gallery.offsetWidth - spacing;
					let leftMargin = spacing;

					if ( format == 'single' ) {
						gallery.style.justifyContent = 'center';
						margin = ((galleryWidth - resizeWidth) / 2) - spacing;

					} else {
						// Gallery width
						galleryWidth = gallery.offsetWidth - spacing;

						// Calculate the number of columns and the column width
						colCount = Math.max(Math.trunc( galleryWidth / ( minWidth + spacing ) ), 1);
						resizeWidth = Math.trunc( ( galleryWidth - spacing ) / colCount ) - 2;
					}
					let colHeight = [];

					// Create HTML for the columns
					for ( let i = 0; i < colCount; i++ ){
						// create each column as a div
						if ( format === 'single' ) {
							galleryHTML += ('<div id=""col_' + i + '"" width=' + resizeWidth + 'px"" style=""margin-left: ' + margin + 'px; margin-right: ' + margin + 'px; ""></div>');
						} else {
							galleryHTML += ('<div id=""col_' + i + '"" width=' + resizeWidth + 'px"" style=""float: left;""></div>');
						}
						gallery.innerHTML = galleryHTML;
						// initialise the height of images in each column
						colHeight[i] = 0;
					}

					// make room for the margins around each image
					resizeWidth -= spacing;

					images.forEach(imageURL => {
						// find the shortest column
						columnElement = findShortestColumn( gallery );
						// add the image to the shortest column
						if ( format === 'square' ) {
							createSquareImage( imageURL, columnElement, resizeWidth, spacing );
						} else {
							createImage( imageURL, columnElement, resizeWidth, spacing );
						}
					});
				}

				function createSquareImage( img, column, width, spacing ) {
					column.innerHTML += '<div style=""width: ' + width + 'px; height: ' + width + 'px; margin-top: ' + spacing + 'px; margin-left:' + spacing + 'px; overflow: hidden;""><img src=""' + img + '""></div>';
					let imgHeight = column.lastChild.lastChild.naturalHeight;
					let imgWidth  = column.lastChild.lastChild.naturalWidth;
					let offset = 0;
					// TODO: handle position for manually or AI cropped images
					if ( imgHeight < imgWidth ){
						column.lastChild.lastChild.height = width;
						column.lastChild.lastChild.width  = imgWidth * width / imgHeight;
						column.lastChild.lastChild.style.position = 'relative';
						offset = (width - column.lastChild.lastChild.width) / 2;
						column.lastChild.lastChild.style.left = offset + 'px';
					} else if ( imgHeight > imgWidth ) {
						column.lastChild.lastChild.style.width = width + 'px';
						column.lastChild.lastChild.style.position = 'relative';
						offset = (width - column.lastChild.lastChild.height) / 2;
						column.lastChild.lastChild.style.top = offset + 'px';
					} else {
						column.lastChild.lastChild.style.width = width + 'px';
					}
				}

				function findShortestColumn(gallery) {
					let columns = gallery.childNodes;
				//alert('columns: ' + columns.length);
					let shortestColumn = columns[0];
					columns.forEach( col => {
						if( col.offsetHeight < shortestColumn.offsetHeight ) {
							shortestColumn = col;
						}
					})
					return shortestColumn;
				}

				function addMouseOver(){
					// Get all the image elements
					let images = document.querySelectorAll('##gallery img');

					// Loop through each image  
					images.forEach(function(image) {

						// Create a title variable 
						let title = image.src;

						// Set the title to show the file name on mouseover
						image.addEventListener('mouseover', function(){
// TODO: make this better!
							this.title = title;
						});

						// Create an overlay and large image to show on click 
						image.addEventListener('click', function(e) {
							// Create overlay div
							let overlay = document.createElement('div');
							overlay.id = 'overlay';

							// Set as fixed position 
							overlay.style.position = 'fixed';
							overlay.style.display = 'none';
							overlay.style.left   = 0;
							overlay.style.top    = 0;
							overlay.style.right  = 0;
							overlay.style.bottom = 0;
							overlay.style.background = 'rgba(0,0,0,0.5)';
							overlay.style.display = 'flex';
							overlay.style.alignItems = 'center';
							overlay.style.justifyContent = 'center';
							// ensure we are on top when on the editor preview page
							overlay.style.zIndex = 9998;

							document.body.appendChild(overlay);
							// Check the size of the image and window and chose a size that fits
							imgWidth  = Math.min( image.naturalWidth,  window.innerWidth  );
							imgHeight = Math.min( image.naturalHeight, window.innerHeight );

							// Create large image
							let largeImage = document.createElement('img');
							largeImage.src = this.src;
							largeImage.style.maxWidth = imgWidth + 'px';
							largeImage.style.maxHeight = imgHeight + 'px';
							largeImage.id = 'overlayImage';
							largeImage.style.zIndex = 9999;

							// Add large image to overlay
							overlay.appendChild(largeImage);

							// Close the image on click
							overlay.onclick = function() {
							  document.body.removeChild(overlay);
							}
						});
					});
				}

				function resizeOverlay(){
					// Check if the overlay is displayed
					let largeImage = document.getElementById('overlayImage');
					if ( largeImage !== null ){
						// Set the size
						imgWidth  = Math.min( largeImage.naturalWidth,  window.innerWidth  );
						imgHeight = Math.min( largeImage.naturalHeight, window.innerHeight );
						largeImage.style.maxWidth = imgWidth + 'px';
						largeImage.style.maxHeight = imgHeight + 'px';
					}
				}

				function resizeGallery(){
					showGallery();
					resizeOverlay();
				}

				// Render gallery
				showGallery();
				window.onresize = resizeGallery;
				</script>
			");
		}
		return rString;
	}
}