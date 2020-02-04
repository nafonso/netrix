#import "Basic";
#import "String";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Process";

build :: () {
	
	// setup default workspace
	set_working_directory(#filepath);
	build_options := get_build_options();

	build_options.output_type = Build_Output_Type.NO_OUTPUT;

	set_build_options( build_options );

	/// setup build workspace
	w := compiler_create_workspace();

	build_directory := "bin/";
	executable_name := "netrix";
	executable_path := join(build_directory, executable_name, ".exe");

	build_options.output_type = Build_Output_Type.EXECUTABLE;
	build_options.output_executable_name = executable_name;
	build_options.output_path = build_directory;

	// handle arguments
	run_on_success := false;
	code_only := false;

	args := compiler_get_command_line_arguments();

	for args {
		if it == {
			case "run";
			run_on_success = true;
			case "codeonly";
			code_only = true;

			case; // default
			print("Ignoring unknown argument: %\n", it);
		}
	}

	// if it's only code, don't copy all dependencies
	if !code_only {
		// copy dependencies

		// copy libs
		lib_files := file_list( "libs/" );

		for lib_files {
			last_index := last_index_of_string(it, "/");
			if( last_index < 0 ){
				print("Error: Couldn't copy lib '%'", it);
				continue;
			}

			file_name := slice(it, last_index, it.count - last_index);
			new_file_path := join(build_directory, file_name);

			if( !file_exists(new_file_path) ) {
				copy_file(it, new_file_path);
			}
		}

		// handle data
		
		data_directory := "data";
		data_build_directory := join(build_directory, data_directory);

		make_directory_if_it_does_not_exist( data_build_directory );

		data_files := file_list(data_directory, true);

		for data_files {
			last_index := last_index_of_string(it, data_directory);
			if( last_index < 0 ){
				print("Error: Couldn't copy data '%'", it);
				continue;
			}

			file_path := slice(it, last_index, it.count-last_index);
			new_file_path := join( build_directory, file_path);

			directories := split(file_path, "/");

			aux_directory_path : string = data_build_directory;

			for i : 1..directories.count-2 { // ignore data and file name
				aux_directory_path = join( aux_directory_path, "/" , directories[i] );
				make_directory_if_it_does_not_exist( aux_directory_path );
			}

			// print("From: % ; To: %\n", it, new_file_path);

			// always override for latest
			copy_file(it, new_file_path);
		}
	}

	// start building

	success := false;

	set_build_options( build_options, w );
	compiler_begin_intercept(w);

	add_build_file("src/netrix.jai", w);

	while true {
        message := compiler_wait_for_message();

        if !message {
            continue;
        }

        if message.kind == Compiler_Message.Kind.COMPLETE {
			message_complete := cast(*Compiler_Message_Complete)message;
			success = message_complete.error_code == Completion_Error_Code.CM_COMPLETE_ERROR_NONE;

            break; // Done compiling.
        }
    }

	compiler_end_intercept(w);

	if( success && run_on_success ){
		os_run_command(executable_path);
	}
}

#run build();
