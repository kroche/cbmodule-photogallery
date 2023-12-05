/**
 * I am the media image handler - available to all users to display media
 *
 * - show a thumbnail or full size image of a media object
 *		get: /index/:id
 */
component{
	
	property name="MediaService" inject="mediaService@photoGallery";

	/**
	* return a thumbnail or image of a media object
	*/
	function index( event, rc, prc ){
		if((rc.size ?: "") neq ""){
			mediaService.showMediaImage(rc.id, rc.size);
		}else{
			mediaService.showMediaImage(rc.id);
		}
		abort;
	}
	
	function temp( event, rc, prc ){
		mediaService.showTempMediaImage( rc.fileName, rc.fileType, rc.size);
		abort;
	}
}
