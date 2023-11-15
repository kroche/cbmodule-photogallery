/**
 * I am an ImageService Model Object
 */
component singleton accessors="true"{
	
	// Properties
	property name="populator" inject="wirebox:populator";

	/**
	 * Constructor
	 */
	ImageService function init(){
		// TODO: Change these lines so that they use a config entry
        variables.imageStore = "D:/PhotoShare";
        variables.imageNotFound = "D:/PhotoShare/imageNotFound.jpg";
		return this;
	}

    /**
	 * return the path to the root of the iamge store
	 */
	// TODO: make this a private function again by moving code from the controller	
	function getTempImageDirectory(){
		return variables.imageStore & "/temp/";
	}

    /**
	 * get a path to the image using the ID (uuid) of the image
	 */
    private function getImageFilePath( required imageId, fileType, size ){
		local.path = getTempImageDirectory() & "/" & left(arguments.imageId, 3) & "/" & mid(arguments.imageId, 4, 3) & "/" & mid(arguments.imageId, 7, 3) & "/";
		if( !directoryExists(local.path) ){
			directoryCreate(local.path);
		}
		if( (arguments.filetype ?: "") neq "" ){
			if ( (arguments.size ?: "" ) eq "" ){
				return local.path & arguments.imageId & "_original." & arguments.fileType;
			}else{
				return local.path & arguments.imageId & "_" & arguments.size & "." & arguments.fileType;
			}
		}
		return local.path;
	}

    /**
	 * save an uploaded image using the ID (uuid) of the image
	 */
    function saveUploadedImage( required file, oImage){
    	if ( arguments.Image.getId() neq "" ) {
    		fileMove("#arguments.file.serverDirectory#/#arguments.file.serverFile#", getImageFilePath(arguments.Image.getId(), arguments.file.serverfileext));
    	}
        
        // TODO: Create smaller images
    }

	/**
	 * show an image using the ID (uuid) of the image and the size
	 */
    function showImage( required imageId, size ){
        local.image = queryExecute(
            "SELECT fileType FROM `posts` WHERE `type` = 'image' AND id = ?",
            [ imageId ],
            { returntype = "array" });
        if ( arrayLen(local.image) ){
            local.path = getImageFilePath( arguments.imageId, local.image[1].fileType, arguments.size );
            try{
                cfcontent( type="image/jpg", file=local.path);
            }
            catch (any e){
                cfcontent( type="image/jpg", file=variables.imageNotFound );
            }
        }else{
            cfcontent( type="image/jpg", file=variables.imageNotFound );
        }
	}

	/**
	 * Get all posts with type image to make an array of image objects using the map() and populator
	 */
    array function getAll(){
		return queryExecute(
            "SELECT * FROM `posts` WHERE `type` = 'image' ORDER BY `createdDate` DESC",
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
	 * Create an image 
	 */
	Image function new() provider="Image"{}

    /**
	 * Get all posts with type image for a particiular user make an array of objects using the map() and populator
	 */
	function getForUserId( required userId ) {
		return queryExecute(
			"SELECT * FROM `posts` WHERE `userId` = ? AND `type` = 'image' ORDER BY `createdDate` DESC",
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
