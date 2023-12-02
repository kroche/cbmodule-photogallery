/**
 * I am the media handler - available to all users to display media
 *
 * - show a page of media
 *		get: /index/[n]  n=number of media to display
 * - show the media upload page
 *      get: /new
 * - display an media
 *		get: /show/[id]  id=id of the media to be displayed
 * - upload an media or a zip of media
 * 		post: /create/
 
 */
component{
	
	property name="mediaService" 	inject="MediaService";
	property name="messagebox" 		inject="MessageBox@cbmessagebox";

	/**
	* index
	*/
	// TODO: Add criteria of media to show
	function index( event, rc, prc ){
		prc.aMedia = mediaService.getAll();
		event.setView( "media/index" );
	}

	/**
	* show media object
	*/
	function show( event, rc, prc ){
		if((rc.size ?: "") neq ""){
			mediaService.showMedia(rc.id, rc.size);
		}else{
			mediaService.showMedia(rc.id);
		}
		abort;
	}
}
