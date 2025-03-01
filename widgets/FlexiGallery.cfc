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

// TODO: create the folder list by querying a list for the chosen site
// TODO: support a selecton of images by date, tags, category

	/**
	* Render a gallery
	* @folder.hint         The folder (relative to the ContentBox content root) from which to list the gallery of photos.
	* @filter.hint         A list of file extension filters to apply (*.jpg), use a | to separate multiple filters.
	* @sort.hint           The sort field (Name, Size, DateLastModified).
	* @sort.options            Name,Size,DateLastModified
	* @order.hint          The sort order of the photos. (ASC/DESC).
	* @order.options           ASC,DESC
	* @format.hint         The format to display the gallery. Choose from justified, square, cascade, single or slider
	* @format.options          justified,square,cascade,single,slider
	* @showInfo.hint       Defines where to show the image title. Choose from mouseOver, below or none.
	* @showInfo.options        mouseOver,below,none
	* @minHeight.hint      The Minimum Height of the gallery images in pixels (250) applies to justified format only.
	* @minHeight.hideudf       test
	* @maxHeight.hint      The Maximum Height of the gallery images in pixels (350) applies to justified format only.
	* @minWidth.hint       The Minimum Width of the gallery images in pixels (300) applies to square, cascade or single column formats only.
	* @spacing.hint        The gap in pixels bewteen images (5) applies to all formats.
	* @showOnClick.hint    Show a large popup version or link to the image page when gallery image is clicked. Choose from popup,link or nothing.
	* @showOnClick.options     popup,link,nothing
	* @popupMaxHeight.hint The maximum height of the large popup in pixels (800).
	* @popupMaxWidth.hint  The maximum width of the large popup in pixels (800).
	* @showDescOnView.hint Show the text description on the large popup.
	* @showExifData        Show the EXIF data from the image on the large popup.
	*/
	any function renderIt(
			required string  folder,
					 string  filter         = "*",
			required string  sort           = "Name",
			required string  order          = "ASC",
			required string  format         = "justified",
			required string  showInfo       = "mouseOver",
			required numeric minHeight      = 250,
			required numeric maxHeight      = 350,
			required numeric minWidth       = 300,
			required numeric spacing        = 5,
					 string  showOnClick    = "popup",
					 numeric popupMaxHeight = 800,
					 numeric popupMaxWidth  = 800,
					 boolean showDescOnView = true,
					 boolean showExifData   = false
		){
		var event = getRequestContext();
		rc = event.getCollection();

		rc.startRow  = rc.startRow ?: 1;
		var startRow = val(rc.startRow);
		if (startRow lt 1){
			startRow = 1;
		};

// TODO: database query to get the folders and images 
		var relativePath = "";
		var cbSettings = event.getValue(name="cbSettings",private=true);
		var sortOrder = arguments.sort & " " & arguments.order;
		var mediaRoot = expandPath(cbSettings.cb_media_directoryRoot);
		var mediaPath = cbSettings.cb_media_directoryRoot & "/" & arguments.folder;
		var mediaPathExpanded = expandPath(mediaPath);
		var galleryPath = event.buildLink("__media/#arguments.folder#/");

		if( !len( arguments.folder ) ){
			return "Please specify a folder";
		}

		if(!directoryExists(mediaPathExpanded)){
			return "The folder specified does not exist";
		}

		if( !len( arguments.format ) ){
			return "Please specify a format";
		}

		if( !listFindNoCase( "justified,square,cascade,single,slider", arguments.format ) ){
			return "Please specify a valid format - justified, square, cascade, single or slider";
		}

		if( !len( arguments.format ) ){
			return "Please specify where to show the image info";
		}

		if( !listFindNoCase( "mouseOver,below,none", arguments.showInfo) ){
			return "Please specify a valid location for the image info in showInfo - mouseOver, below or none";
		}

		//security check - folder chosen must be below the media root
		if(!findNoCase(mediaRoot, mediaPathExpanded)){
			return "This widget is restricted to the ContentBox media root.  All photo galleries must be contained within that directory.";
		}

		// get a query containing all the images
		var gallery = directoryList(mediaPathExpanded,false,"query",arguments.filter,sortOrder);
		var query = new Query();
		query.setAttributes(directoryListing = gallery);

		var qryGalleryFolders  = query.execute(sql="select * from directoryListing where type = 'Dir' and name <> '_photogallery'", dbtype="query");
		var qryGalleryPhotos   = query.execute(sql="select * from directoryListing where type = 'File'", dbtype="query");
		var galleryFolders     = qryGalleryFolders.getResult();
		var galleryPhotos      = qryGalleryPhotos.getResult();
		var settings           = deserializeJSON(settingService.getSetting( "photo_gallery" ));
		var galleryRow         = {};
		var galleryPhotosArray = [];
		var galleryPhotosJSON  = "";

		// Temporary code to add extra columns
		for (var x=startRow; x lte galleryPhotos.recordcount; x++) {
			if ( x le galleryPhotos.recordcount ) {
				galleryRow["name"]        = galleryPhotos.name[x];
				galleryRow["url"]         = "#galleryPath#/#galleryPhotos.name[x]#";
				galleryRow["title"]       = galleryPhotos.name[x];
				galleryRow["description"] = "A sample description";
				galleryRow["tags"]        = "portrait,model,x-pro2";
				galleryRow["reactions"]   = {"like"=6,"love"=12,"star"=3,"award"=5};
				galleryRow["author"]      = "Anonymous";
				arrayAppend( galleryPhotosArray, galleryRow );
				galleryRow = {};
			}
		}

		//writeDump(var=galleryPhotosArray, label="galleryPhotosArray", abort="1");
		galleryPhotosJSON = serializeJSON( galleryPhotosArray );
		//writeDump(var=galleryPhotosJSON, label="galleryPhotosJSON", abort="1");
		
		//Fix for including the JSON in the writeOutput() below
		//galleryPhotosJSON = replace(galleryPhotosJSON, chr(34), chr(39) );

		// generate photo gallery
		var rString = "";
		saveContent variable="rString" {

			// Javascript Libraries
			writeOutput('<script src="/smartcrop/smartcrop.js"></script>');

			// CSS Libraries
			writeOutput('
				<style>
					.zx_slider{
						position: relative;
						width: 100%;
						margin: auto;
						overflow: hidden;
					}
					.zx_slider img{
						width: 100%;
						display: none;
					}
					img.zx_displaySlide{
						display: block;
						animation-name: fade;
						animation-duration: 1.5s;
					}
					.zx_slider button{
						position: absolute;
						top: 50%;
						transform: translateY(-50%);
						font-size: 2rem;
						padding: 10px 15px;
						background-color: hsla(0, 0%, 0%, 0.5);
						color white;
						border: none;
						cursor: pointer;
					}
					.zx_prev{
						left: 0;
					}
					.zx_next{
						right: 0;
					}
					@keyframes fade {
						from {opacity: .5 }
						to (opacity: 1)
					}
				</style>	
			');

			// HTML for the gallery
			writeOutput('<div id="gallery" style="flex"></div>');

			// Javascript for the gallery
			writeOutput("
			<script>
				var slides = null;
				var slideIndex = 0;
				var intervalId = null;

				async function showGallery() {
					const minHeight      =  #arguments.minHeight#;
					const maxHeight      =  #arguments.maxHeight#;
					const minWidth       =  #arguments.minWidth#;
					const spacing        =  #arguments.spacing#;
					const format         = '#arguments.format#';
					const showInfo       = '#arguments.showInfo#';
					const showOnClick    = '#arguments.showOnClick#';
					const showDescOnView =  #arguments.showDescOnView#;
					const showExifData   =  #arguments.showExifData#;
					const popupMaxHeight =  #arguments.popupMaxHeight#;
					const popupMaxWidth  =  #arguments.popupMaxWidth#;
					// Set the crop size on square images to minWidth 
					const squareCrop     =  {
						width:  minWidth,
						height: minWidth
					};

					// where will we display the images
					const gallery = document.querySelector('##gallery');

// TODO: get the list of images, titles and descriptions with an ajax call
					// Get an array of images from server
					const images = JSON.parse('#galleryPhotosJSON#');
					for ( var image of images ) {
						// Preload images so that the size information is available
						image.photo = await loadImage( image.url );
						// If we are using square images crop any that need to be cropped
						if ( format == 'square' ) {
							if ( image.photo.naturalHeight != image.photo.naturalWidth ) {
								image.crops = await smartcrop.crop(image.photo, squareCrop);
								console.log( 'image.crops', image.crops );
							}
						}
					}

					// call the chosen formatter
					switch(format) {
						case 'justified':
							await justifyGallery( gallery, images, minHeight, maxHeight, minWidth, spacing, showInfo, showOnClick );
							break;
						case 'slider':
							await sliderGallery( gallery, images, minHeight, maxHeight, showInfo, showOnClick );
							break;
						default:
							await cascadeGallery( gallery, images, format, minHeight, maxHeight, minWidth, spacing, showInfo, showOnClick );
					}
					// add mouseover and click events
					addMouseEvents( showInfo, showOnClick, popupMaxHeight, popupMaxWidth, showDescOnView, showExifData );
				}

				async function justifyGallery( gallery, images, minHeight, maxHeight, minWidth, spacing, showInfo, showOnClick ) {
					// Set variables to track current row width at max and min height
					let rowMaxWidth = spacing;
					let rowMinWidth = spacing;

					// Initialise current row to add images
					let currRow = [];
					// Gallery
					let galleryWidth = gallery.offsetWidth - spacing - 13; // 13 is the scroll bar allowance

					// Initialise variables
					let img = '';
					let imgWidth = 0;
					let imgHeight = 0;
					let imgWidthResizeMax = 0;
					let imgWidthResizeMin = 0;

					// Loop over the array of image URLs and create the HTML
//TODO: Handle image title and description
					images.forEach(image => {
						createImage( image.url, gallery, null, spacing, showInfo, image.title, image.description, showOnClick );
					})

					// Greate an array of the div objects containg each img
					let imgDivs = gallery.childNodes;

					// Loop over the array of divs
					imgDivs.forEach(container => {
						// Get image width and height including margins
						img = container.querySelector('img');
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

								justifyRow(currRow, galleryWidth, rowMaxWidth, maxHeight, spacing, showInfo);

								currRow = [];
								rowMaxWidth = spacing;
								rowMinWidth = spacing;
							
							} else {
								// If it does not fit either way start a new row
								justifyRow(currRow, galleryWidth, rowMaxWidth, maxHeight, spacing, showInfo);

								// Start new row
								currRow = [];
								currRow.push(container);
								rowMaxWidth = imgWidthResizeMax + spacing;
								rowMinWidth = imgWidthResizeMin + spacing;
							}
						}
					});
					// Justify last row
					justifyRow( currRow, galleryWidth, rowMaxWidth, maxHeight, spacing, showInfo );
				}

				function justifyRow( row, galleryWidth, rowMaxWidth, maxHeight, spacing, showInfo ) {
					let totalMargin	     = (row.length + 1) * spacing;
					let totalImageWidths = galleryWidth - totalMargin;
					let resizeHeight     = Math.trunc(maxHeight * galleryWidth / rowMaxWidth);
					let img              = '';
					let height           = Math.min(maxHeight, resizeHeight);
					let divHeight        = height;
					if ( showInfo == 'below' ){
						divHeight = height + 40;
					}
					// set the height of the divs and images in the row
					row.forEach((imgDiv) => {
						imgDiv.style.float = 'left';
						imgDiv.style.height = divHeight + 'px';
						imgDiv.height = divHeight + 'px';
						img = imgDiv.querySelector('img');
						img.style.height = height + 'px';
						img.height = height + 'px';
					});
				}

				async function cascadeGallery( gallery, images, format, minHeight, maxHeight, minWidth, spacing, showInfo, showOnClick ) {
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
						galleryHTML += ('<div width=' + resizeWidth + 'px"" ');
						if ( format === 'single' ) {
							galleryHTML += ('style=""margin-left: ' + margin + 'px; margin-right: ' + margin + 'px; ""></div>');
						} else {
							galleryHTML += ('style=""float: left;""></div>');
						}
						gallery.innerHTML = galleryHTML;
						// initialise the height of images in each column
						colHeight[i] = 0;
					}

					// make room for the margins around each image
					resizeWidth -= spacing;

					let i = 0;
					images.forEach(image => {
// TODO: choose the best size image based on maxHeight and minWidth
						// find the shortest column
						columnElement = findShortestColumn( gallery );
						// add the image to the shortest column
// TODO: Handle image title and description
						if ( format === 'square' ) {
							createSquareImage( image, columnElement, resizeWidth, spacing, showInfo, image.title, image.description, showOnClick );
						} else {
							createImage( image.url, columnElement, resizeWidth, spacing, showInfo, image.title, image.description, showOnClick );
						}
						// Make sure the title box does not push the element below down the column
						if ( showInfo != 'below' ){
							columnElement.lastChild.style.maxHeight = columnElement.lastChild.querySelector('img').offsetHeight + 'px';
						}
					});
				}

				async function sliderGallery( gallery, images, minHeight, maxHeight, showInfo, showOnClick ){
					let galleryHTML   = '';
					galleryHTML += ('<div class=""zx_slider""><div class=""zx_slides"" >');
					images.forEach(image => {
						galleryHTML += ('<img class=""zx_slide"" src=""' + image.url + '"" title=""' + image.title + '"" alt=""' + image.description + '""/> ');
					});
					galleryHTML += ('</div>');
					galleryHTML += ('<button class=""zx_prev"" onclick=""prevSlide()"">&##10094</button>');
					galleryHTML += ('<button class=""zx_next"" onclick=""nextSlide()"">&##10095</button>');
					galleryHTML += ('</div>');
					gallery.innerHTML = galleryHTML;
					slides = gallery.querySelectorAll("".zx_slides img"");
					console.log(slides.length + ' slides found');
					if ( slides.length > 0 ){
						slides[ slideIndex ].classList.add(""zx_displaySlide"");
						intervalId = setInterval( nextSlide, 5000);
						console.log('intervalId:' + intervalId);
					}
					slideIndex = 0;
					showSlide(slideIndex);
				}

				function showSlide( index ){
					if( index >= slides.length ){
						slideIndex = 0;
					} else if( index < 0 ){
						slideIndex = slides.length - 1;
					}
					slides.forEach( slide => {
						slide.classList.remove(""zx_displaySlide"");
					});
					slides[ slideIndex ].classList.add(""zx_displaySlide"");
				}

				function prevSlide(){
					clearInterval( intervalId )
					slideIndex --;
					showSlide( slideIndex );
				}

				function nextSlide(){
					slideIndex ++;
					showSlide( slideIndex );
				}

				function createImage( imageURL, container, width, spacing, showInfo, title, alt, showOnClick ) {
					let titleBox = createTitleBox( showInfo, title );
					let linkTag  = showOnClick == 'link' ? createLinkTag( imageURL, showOnClick ) : { open:'', close:'' };
// TODO: choose the best size image
// TODO: cut the length of the title to suit the width of the image
					if ( width === null ) {
						// used for justified images
						container.innerHTML += ('<div style=""margin-top: ' + spacing + 'px; margin-left: '+ spacing + 'px;"">' + linkTag.open + '<img src=""' + imageURL + '"" title=""' + title + '"" alt=""' + alt + '""/>' + linkTag.close + titleBox + '</div>');
					} else {
						// used for cascading or single column images 
						container.innerHTML += ('<div style=""margin-top: ' + spacing + 'px; margin-left: '+ spacing + 'px;""><div width=""' + width + 'px"">' + linkTag.open + '<img src=""' + imageURL + '"" title=""' + title + '"" alt=""' + alt + '"" width=""' + width + 'px""/>' + linkTag.close + titleBox + '</div></div>');
					}
				}

				function loadImage( src ) {
					// this function uses a promise to preload images
					return new Promise((resolve, reject) => {
						const image = new Image();
						image.onload = () => resolve(image);
						image.onerror = e => reject(new Error(e));
						image.src = src;
					});
				}

				function createSquareImage( image, column, width, spacing, showInfo, title, alt, showOnClick ) {
					let titleBox      = createTitleBox( showInfo, title );
					let linkTag       = showOnClick == 'link' ? createLinkTag( image.url, showOnClick ) : { open:'', close:'' };
					let divHeight     = ( showInfo == 'below' ) ? width + 40 : width;
					
					column.innerHTML += '<div style=""width: ' + width + 'px; height: ' + divHeight + 'px; margin-top: ' + spacing + 'px; margin-left:' + spacing + 'px; overflow: hidden;"">' + linkTag.open + '<img src=""' + image.url + '"" title=""' + title + '"" alt=""' + alt + '""/>' + linkTag.close + titleBox + '</div>';
					let img           = column.lastChild.querySelector('img');
					let imgHeight     = img.naturalHeight;
					let imgWidth      = img.naturalWidth;
					let imageStyle    = img.style;
					let imageOffset   = 0;

// TODO: choose the best size image
// TODO: cut the length of the title to suit the width of the image
					if ( imgHeight < imgWidth ){
						// Landscape
						let displayWidth    = imgWidth * width / imgHeight;
						imageStyle.height   = width + 'px';
						imageStyle.maxWidth = displayWidth + 'px';
						imageStyle.width    = displayWidth + 'px';
						imageStyle.position = 'relative';
						if ( image.crops != undefined ){
							const scale     = width / image.crops.topCrop.width;
							imageStyle.left = -image.crops.topCrop.x * scale + 'px';
						} else {
							imageOffset     = ( width - displayWidth ) / 2;
							imageStyle.left = imageOffset + 'px';
						}
					} else if ( imgHeight > imgWidth ) {
						// Portrait
						let displayHeight    = imgHeight * width / imgWidth;
						imageStyle.maxHeight = displayHeight + 'px';
						imageStyle.height    = displayHeight + 'px';
						imageStyle.width     = width + 'px';
						imageStyle.position  = 'relative';
						if ( image.crops != undefined ){
							const scale      = width / image.crops.topCrop.width;
							imageOffset      = -image.crops.topCrop.y * scale;
						} else {
							imageOffset      = ( width - displayHeight ) / 2;
						}
						imageStyle.top   = imageOffset + 'px';
						column.lastChild.lastChild.style.top = ( showInfo == 'below' ) ? -displayHeight + width + 'px' : -displayHeight + width - 40 + 'px';
					} else {
						// Square
						imageStyle.width  = width + 'px';
						imageStyle.height = width + 'px';
					}
				}

				function createTitleBox ( showInfo, title ) {
					if ( showInfo == 'none' ){
						return '';
					}
					let titleBox   = '<div style=""min-height:40px; padding:1px 5px; position:relative; background-color:white; z-index:9990; text-align:center;';
					if ( showInfo == 'mouseOver' ) {
						titleBox += ' display:none; top:-40px;"">';
					}else if ( showInfo == 'below' ) {
						titleBox += ' display:block;"">';
					}
					titleBox += '<p>' + title + '</p></div>';
					return titleBox;
				}

				function createLinkTag( url, showOnClick ){
					let linkTag = {};
					linkTag.open  = '<a href=""' + url + '"">';
					linkTag.close = '</a>';
					return linkTag;
				}

				function findShortestColumn(gallery) {
					let columns = gallery.childNodes;
					let shortestColumn = columns[0];
					columns.forEach( col => {
						if( col.offsetHeight < shortestColumn.offsetHeight ) {
							shortestColumn = col;
						}
					})
					return shortestColumn;
				}

				function addMouseEvents( showInfo, showOnClick, popupMaxHeight, popupMaxWidth, showDescOnView, showExifData ){
					// Get all the image elements
					let images = document.querySelectorAll('##gallery img');

					// Loop through each image  
					images.forEach(function(image) {

						if ( showInfo == 'mouseOver' && this.title != ''){
						// Set the mouseover on each image to show the title
							image.addEventListener('mouseover', function(e){
								let titleBox = '';
								if (this.parentElement.tagName == 'A'){
									titleBox = this.parentElement.nextSibling;
								} else {
									titleBox = this.nextSibling;
								};
								titleBox.style.display = 'block';
							});
							image.addEventListener('mouseout', function(e){
								let titleBox = '';
								if (this.parentElement.tagName == 'A'){
									titleBox = this.parentElement.nextSibling;
								} else {
									titleBox = this.nextSibling;
								};
								titleBox.style.display = 'none';
							});
						}

						if ( showOnClick == 'popup' ){
							// Create an overlay and large image with title and description to show on click
							image.addEventListener('click', function(e) {
								// Create overlay div
								let overlay = document.createElement('div');
								let nextPosition = 40;
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
								overlay.style.justifyContent = 'center';
								
								// ensure we are on top when on the editor preview page
								overlay.style.zIndex = 9997;

								document.body.appendChild(overlay);
								// Check the size of the image and window and chose a size that fits
								imgHeight = Math.min( image.naturalHeight, window.innerHeight, popupMaxHeight );
								imgWidth  = Math.min( image.naturalWidth,  window.innerWidth,  popupMaxWidth  );

// TODO: choose the best size image to show in larger image (won't be able to use image.naturalHeight to do that!)
								// Create large image
								let largeImage = document.createElement('img');
								largeImage.src = this.src;
								
								largeImage.style.maxHeight = imgHeight + 'px';
								largeImage.style.maxWidth  = imgWidth + 'px';
								largeImage.style.position  = 'absolute';
								largeImage.style.top       = (nextPosition) + 'px';
								largeImage.id = 'overlayImage';
								largeImage.style.zIndex    = 9998;
								// Add large image to overlay
								overlay.appendChild(largeImage);

								// Show the title and description below the image
								let titleBox   = document.createElement('div');
								titleBox.style.width           = imgWidth + 'px';
								titleBox.style.minHeight       = '40px';
								titleBox.style.paddingLeft     = '10px';
								titleBox.style.position        = 'absolute';
								nextPosition                   = overlay.lastChild.getBoundingClientRect().bottom;
								titleBox.style.top             = (nextPosition) + 'px';
								titleBox.style.backgroundColor = 'white';
								titleBox.style.zIndex          = 9999;
								titleBox.style.display         = 'block';
								titleBox.style.textAlign       = 'center';
// TODO: don't show the title or alt text if it is blank
								if ( this.title != '' ){
									titleBox.innerHTML  = '<p>' + this.title + '</p>';
								}
								if ( showDescOnView && this.alt != ''){
									titleBox.innerHTML += '<p>' + this.alt + '</p>';
								}
								//if ( showExifData && this.dataExif != ''){
								//	titleBox.innerHTML += '<p>' + this.dataExif + '</p>';
								//}
// TODO: Option to link to a shop to purchase the picture
// TODO: Option to play a video if this is a video
// TODO: Option to show likes and awards
// TODO: Option to allow comments

								// Add title to overlay
								overlay.appendChild(titleBox);

								// Close the image on click
								overlay.onclick = function() {
									document.body.removeChild(overlay);
								}
							});
						}
					});
				}

				function resizeOverlay(){
					// Check if the overlay is displayed
					let overlayImage = document.getElementById('overlayImage');
					if ( overlayImage !== null ){
						// Set the size
						imgWidth  = Math.min( overlayImage.naturalWidth,  window.innerWidth  );
						imgHeight = Math.min( overlayImage.naturalHeight, window.innerHeight );
						overlayImage.style.maxWidth  = imgWidth + 'px';
						overlayImage.style.maxHeight = imgHeight + 'px';
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
