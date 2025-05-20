# wrapper to start project build script in script directory
set proj_build_scr "project_mp2.tcl"

set old_path [ pwd ]
set script_path [ file dirname [ file normalize [ info script ] ] ]
cd $script_path


if { [ file exists ${proj_build_scr} ] } {
	source $proj_build_scr
	cd $old_path
} else {
	puts ""
	puts "ERROR:  ${proj_build_scr}   doesn't exist here."
	cd $old_path
	puts ""
}