/**
 * I am an MediaService Model Object
 */
component extends="contentbox.models.content.ContentService" singleton accessors="true"{

	// Properties
	property name="populator" inject="wirebox:populator";

	/**
	 * Constructor
	 */
	MediaService function init(){
		// TODO: Change these lines so that they use a config entry
		variables.mediaStore     = "D:/PhotoShare";
		variables.tempMediaStore = "D:/PhotoShare/temp"
		variables.mediaNotFound  = "D:/PhotoShare/mediaNotFound.jpg";

		super.init( entityName = "cbMedia", useQueryCaching = true );
		return this;
	}

	/**
	 * return the path to the root of the temporary media store
	 */
	// TODO: make this a private function again by moving code from the controller
	function getTempMediaDirectory(){
		return variables.tempMediaStore;
	}
	
	/**
	 * return the path to the root of the iamge store
	 */
	// TODO: make this a private function again by moving code from the controller
	function getMediaDirectory(){
		return variables.mediaStore;
	}

	/**
	 * get a path to the media using the ID (uuid) of the media
	 *
	 * @contentID    The contentID of the media (for temp images which don't yet have a contentID use the serverFileName)
	 * @fileType     The fileType (suffix) of the Image
	 * @size         The size of the image or "original"
	 * @temp         "True" If the image is or will be in the temporary storage
	 *
	 */
	private function getMediaFilePath( 
		required string contentId,
		required string fileType,
		string size = "",
		boolean temp = false
	){
		if ( temp ) {
			local.path = getTempMediaDirectory() & "/";
		}else{
			local.path = getMediaDirectory() & "/" & left(arguments.contentId, 3) & "/" & mid(arguments.contentId, 4, 3) & "/" & mid(arguments.contentId, 7, 3) & "/";
		}
		
		if( !directoryExists(local.path) ){
			directoryCreate(local.path);
		}
		
		if( (arguments.filetype ?: "") neq "" ){
			if ( temp AND ( arguments.size ?: "" ) eq "" ) {
				return local.path & arguments.contentId & "." & arguments.fileType;
			} elseif ( temp ){
				return local.path & arguments.contentId & "_" & arguments.size & "." & arguments.fileType;
			} elseif ( (arguments.size ?: "" ) eq "" ){
				return local.path & arguments.contentId & "_original." & arguments.fileType;
			}else{
				return local.path & arguments.contentId & "_" & arguments.size & "." & arguments.fileType;
			}
		}
		return local.path;
	}

	/**
	 * Save an image
	 *
	 * @image        The entry to save or update
	 *
	 * @return Saved entry
	 
	function saveImage( required any image ){
		oMedia = super.save( arguments.image );
//writedump(var=oMedia, label="oMedia after super.save() MediaService line 76", abort="1");
		return oMedia;
	}*/


	/**
	 * save an uploaded image using the ID (uuid) of the image
	 
	function saveUploadedMedia(
		required file,
		required oMedia
	){
		if ( arguments.Media.getId() neq "" ) {
			fileMove("#arguments.file.serverDirectory#/#arguments.file.serverFile#", getMediaFilePath(arguments.Media.getId(), arguments.file.serverfileext));
		}
   
		// TODO: Create smaller images
	}*/

	/**
	 * display a media image or thumbnail using the contentID of the image or video and the size
	 *
	 * @contentId   the Id of the image
	 * @size        the size we wish to show
	 */
	function showMediaImageByID( required string contentID, size ){
		local.media = queryExecute(
			// TODO: Check login or not will allow us to show this image
			// TODO: Check that the image is published and within the start and end dates (JOIN with cb_content)
			"SELECT fileType, serverFileName, inTempStorage, mediaType FROM `cb_media` WHERE ContentID = ?",
			[ arguments.contentID ],
			{ returntype = "array" });
		// since we are getting an image or thumbnail we don't use the real filetype to get the image we always use 'image/jpg'
		if ( arrayLen(local.media) ){
			if ( listFindNoCase( "jpg,jpeg,png,gif", local.media[1].fileType ) ){
				local.path = getMediaFilePath( arguments.contentID, local.media[1].fileType, arguments.size );
			} else {
				local.path = getMediaFilePath( arguments.contentID, "jpg", arguments.size );
			}

			try{
				cfcontent( type="image/jpg", file=local.path);
			}
			catch (any e){
				cfcontent( type="image/jpg", file=variables.mediaNotFound );
			}
		}else{
			cfcontent( type="image/jpg", file=variables.mediaNotFound );
		}
		abort;
	}

	/**
	 * display an image or video using the media entity and the size
	 *
	 * @mediaEntity  the Id of the image
	 * @size         the size we wish to show
	 */
	function showMediaImageByEntity( required Media oMedia, size ){
		// since we are getting an image or thumbnail we don't always use the real filetype to get the image for a video or document we use 'image/jpg'
		if ( oMedia.getInTempStorage() ){
			showTempMediaImage( oMedia.getServerFileName, oMedia.getServerFiletype, arguments.size );
		} 
		
		if ( listFindNoCase( "jpg,jpeg,png,gif", getFileType() ) ){
			local.path = getMediaFilePath( oMedia.getContentID(), oMedia.getFileType(), arguments.size );
		} else {
			local.path = getMediaFilePath( oMedia.getContentID(), "jpg",                arguments.size );
		}

		try{
			cfcontent( type="image/jpg", file=local.path);
		} catch (any e){
			cfcontent( type="image/jpg", file=variables.mediaNotFound );
		}
		abort;
	}
	
	/**
	 * show an image using the server file name of the image in temporary storage and the size
	 *
	 * @contentId   the Id of the image
	 * @size        the size we wish to show
	 */
	function showTempMediaImage( required string serverFileName, required string fileType, size ){
		local.path = getMediaFilePath( arguments.serverFileName, arguments.fileType, arguments.size, true );
		try{
			cfcontent( type="image/jpg", file=local.path);
		}
		catch (any e){
			cfcontent( type="image/jpg", file=variables.mediaNotFound );
		}
		abort;
	}

	/**
	 * Get all content with type media to make an array of media objects using the map() and populator
	 */
	/**
	array function getAll(){
		return queryExecute(
			"SELECT * FROM `cb_media`
			 WHERE `mediaType` = 'Media' ORDER BY `createdDate` DESC",
			[],
			{ returntype = "array" }
		).map( function ( post ) {
			return populator.populateFromStruct(
				new(),
				post
			);
		} );
	}
	*/

	/**
	 * Create a new media object 
	 
	Media function new() provider="Media"{}
	*/

	/**
	 * Get all posts with type media for a particiular site make an array of objects using the map() and populator
	
	function getForUserId( required userId ) {
		return queryExecute(
			"SELECT * FROM `posts` WHERE `userId` = ? AND `type` = 'Media' ORDER BY `createdDate` DESC",
			[ userId ],
			{ returntype = "array" }
		).map( function ( post ) {
			return populator.populateFromStruct(
				new(),
				post
			);
		} );
	} */

}
