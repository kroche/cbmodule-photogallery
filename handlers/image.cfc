/**
 * I am the image handler - available to all users to display images
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

}

