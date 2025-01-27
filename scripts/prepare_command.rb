require 'rubygems'
require 'cocoapods'
require 'find'

def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
end

BUILD_PHASE_NAME = "Label Optimizely Views"
SHELL_SCRIPT = "ruby \"$PODS_ROOT/Optimizely-iOS-SDK/scripts/OptimizelyPrepareNibs.rb\""

# These shell scripts were deprecated as of 7/15/14 and 5/28/14 respectively.
DEPRECATED_SHELL_SCRIPTS = ["python \"$PODS_ROOT/Optimizely-iOS-SDK/scripts/OptimizelyPrepareNibs.py\"", 
                            "python \"$SRCROOT/Pods/Optimizely-iOS-SDK/scripts/OptimizelyPrepareNibs.py\""]

# Find main project file by looking in the Podfile declaration
xcodeproj_path = nil
begin
  filename = File.exists?('../../podfile') ? '../../podfile' : '../../Podfile'
  suppress_warnings {
      xcodeproj_path = Pod::Command::IPC::Podfile::Pod::Podfile.from_file(filename).to_hash["target_definitions"].first["user_project_path"]
  }
rescue
  nil
end

if xcodeproj_path
  # If declared in Podfile, prepend two directories up so that project path is relative to this script
  xcodeproj_path = "../../" + xcodeproj_path

  # xcodeproj extension may or may not be specified
  if xcodeproj_path.split('.').last != 'xcodeproj'
    xcodeproj_path = xcodeproj_path + '.xcodeproj'
  end

  # Verify file is valid
  if(!File.exists?(xcodeproj_path))
    xcodeproj_path = nil
  end
end

if !xcodeproj_path
  # Otherwise, fallback on a simple directory listing
  xcodeproj_path = Dir['../../*'].detect do |fname|
      fname =~ /.*\.xcodeproj$/
  end
end

if xcodeproj_path
    # Open project
    project = Xcodeproj::Project.open(xcodeproj_path)
    main_target = project.targets.first

    # Check if build phase exists
    phases = main_target.shell_script_build_phases
    phase_to_remove = nil
    # Get our shell script build phase
    phases.each do |phase|
        if phase.shell_script == SHELL_SCRIPT
            phase_to_remove = phase
            break
        end
    end
    # delete it and save the project file
    # It wont stick unless we remove it from main_target.build_phases
    if phase_to_remove
        main_target.build_phases.delete(phase_to_remove)
        project.save()
    end
end
