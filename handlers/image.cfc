/**
 * I am the image handler
 *
 * - show a page of images
 *		get: /index/[n]  n=number of images to display
 * - show the image upload page
 *      get: /new
 * - display an image
 *		get: /show/[id]  id=id of the image to be displayed
 * - upload an image or a zip of images
 * 		post: /create/
 
 */
component{
	
	property name="imageService" 	inject="ImageService";
	property name="messagebox" 		inject="MessageBox@cbmessagebox";

	/**
	* index
	*/
	// TODO: Add criteria of images to show
	function index( event, rc, prc ){
		prc.aImages = imageService.getAll();
		event.setView( "image/index" );
	}

	/**
	* new image
	*/
	function new( event, rc, prc ){
		event.setView( "image/new" );
	}

	/**
	* show an image
	*/
	function show( event, rc, prc ){
		if((rc.size ?: "") neq ""){
			imageService.showImage(rc.id, rc.size);
		}else{
			imageService.showImage(rc.id);
		}
		abort;
	}

	/**
	* create
	*/
	function create( event, rc, prc ){
		// TODO: Check who is logged on and reject if not a Site Author, Manager or Administrator

		// Upload the images here
		local.files = fileUploadAll(getTempDirectory(), "", "makeunique");
		//writeDump(local.files); abort;

		// TODO: if it is a zip unzip it

		// loop over the files
		for (i = 1; i <= arrayLen(local.files); i++) {
			local.oPost = populateModel( "Post" );
			local.oPost.setUserId( auth().getUserId() );
			local.oPost.setType( "image" );
			local.oPost.setFileType( local.files[i].serverfileext );
			local.oPost.setClassification( "unknown" );

			imageService.saveUploadedImage(local.files[i], local.oPost);
    		//fileMove("#local.files[i].serverDirectory#/#local.files[i].serverFile#", imageService.makeImageFilePath(local.oPost.getId(), local.files[i].serverfileext));
			postService.create( local.oPost );
		}
		
		// TODO: create resized versions of the uplaoded image 

		messagebox.info( "Image uploaded!" );
		relocate( URI="/posts" );
	}
}

