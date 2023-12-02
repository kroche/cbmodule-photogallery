component {
	// Include Utils
	include template="./util/MigrationUtils.cfm"; 
	
	function up( schema, qb ){
		// Content Templates
		if ( !schema.hasTable( "cb_media" ) ) {
			arguments.schema.create( "cb_media", ( table ) => {
				// Columns
				table.string( "contentID", 36 ).primaryKey();
				table.longText( "description" ).nullable();
				table.integer( "order" ).default( 0 );
				table.string( "fileType", 255 ).nullable();
				table.string( "mediaType", 255 ).nullable();
				table.integer( "width" ).default( 0 );
				table.integer( "height" ).default( 0 );
				table.integer( "cropXpos" ).default( 0 );
				table.integer( "cropYpos" ).default( 0 );
				table.integer( "cropWidth" ).default( 0 );
				table.integer( "cropHeight" ).default( 0 );
				table.string( "originalName" ).nullable();
				table.string( "serverFileName" ).nullable();
				table.longText( "metadata" ).nullable();
				table.longText( "excerpt" ).nullable();
				table.bit( "inTempStorage").default( false )
			} );
		} else {
			systemOutput( "- skipping 'cb_media' creation, table already there", true );
		}
	}
}
