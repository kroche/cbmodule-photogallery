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
		return variables.tempMediaStore & "/";
	}
	
	/**
	 * return the path to the root of the iamge store
	 */
	// TODO: make this a private function again by moving code from the controller
	function getMediaDirectory(){
		return variables.mediaStore & "/";
	}

    /**
	 * get a path to the media using the ID (uuid) of the media
	 *
	 * @contentId    The contentId of the media
	 * @fileType     The fileType of contentIdmage
	 * @size         The size of the image or "original"
	 * @temp         "True" If the image is in the temporary storage
	 *
	 */
    private function getMediaFilePath( required contentId, fileType, size, boolean temp=false ){
    	if ( temp ) {
    		local.path = getTempMediaDirectory() & "/" & left(arguments.contentId, 3) & "/" & mid(arguments.contentId, 4, 3) & "/" & mid(arguments.contentId, 7, 3) & "/";
    	}else{
    		local.path = getMediaDirectory() & "/" & left(arguments.contentId, 3) & "/" & mid(arguments.contentId, 4, 3) & "/" & mid(arguments.contentId, 7, 3) & "/";
    	}
		
		if( !directoryExists(local.path) ){
			directoryCreate(local.path);
		}
		if( (arguments.filetype ?: "") neq "" ){
			if ( (arguments.size ?: "" ) eq "" ){
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
	 */
	function save( required any image ){
		oMedia = super.save( arguments.image );
writedump(var=oMedia, label="oMedia after super.save() MediaService line 76", abort="1");
		return oMedia;
	}


    /**
	 * save an uploaded image using the ID (uuid) of the image
	 */
    function saveUploadedMedia( required file, oMedia){
    	if ( arguments.Media.getId() neq "" ) {
    		fileMove("#arguments.file.serverDirectory#/#arguments.file.serverFile#", getMediaFilePath(arguments.Media.getId(), arguments.file.serverfileext));
    	}
        
        // TODO: Create smaller images
    }

	/**
	 * show an image or video using the contentID of the image or video and the size
	 */
    function showMedia( required contentID, size ){
        local.media = queryExecute(
            "SELECT fileType FROM `posts` WHERE `type` = 'Media' AND id = ?",
            [ contentID ],
            { returntype = "array" });
        if ( arrayLen(local.media) ){
            local.path = getMediaFilePath( arguments.mediaId, local.media[1].fileType, arguments.size );
            try{
                cfcontent( type="image/jpg", file=local.path);
            }
            catch (any e){
                cfcontent( type="image/jpg", file=variables.mediaNotFound );
            }
        }else{
            cfcontent( type="image/jpg", file=variables.mediaNotFound );
        }
	}

	/**
	 * Get all posts with type media to make an array of media objects using the map() and populator
	 */
    array function getAll(){
		return queryExecute(
            "SELECT * FROM `posts` WHERE `type` = 'media' ORDER BY `createdDate` DESC",
            [],
            { returntype = "array" }
        ).map( function ( post ) {
            return populator.populateFromStruct(
                new(),
                post
            );
        } );
	}

	/**
	 * Create a media object 
	 */
	Media function new() provider="Media"{}

    /**
	 * Get all posts with type media for a particiular user make an array of objects using the map() and populator
	 */
	function getForUserId( required userId ) {
		return queryExecute(
			"SELECT * FROM `posts` WHERE `userId` = ? AND `type` = 'media' ORDER BY `createdDate` DESC",
			[ userId ],
			{ returntype = "array" }
		).map( function ( post ) {
			return populator.populateFromStruct(
				new(),
				post
			);
		} );
    }

}
