package require ::tclapp::xilinx::tk_tunnel
package require fileutil
namespace import ::tclapp::xilinx::tk_tunnel::*

# create process to close tk_tunnel instance 
proc close_tk_tunnel {} {
    puts "disconnected"
    set ::tclapp::xilinx::tk_tunnel::local_wait_on "done" 
    rexec {exit}
}

# clear prior version of variables if they exist
unset -nocomplain -- prior_ipxact chan proj_dir ip_repos_dir curr_ip_def from_core vendor library name version vendor_display_name url display_name_prev name_guess_on_client version_split major_version_guess_on_client minor_version_guess_on_client vivado_pid vivado_window_info vivado_window_id vivado_screenwidth vivado_xoffset vivado_screenheight new_version name_from_server major_version_from_server minor_version_from_server display_name new_ip_dir_name old_ip_dir_name old_ip_copy_dir new_ipxact

# save prior ipxact file in the case you decide not to save and want it back
set prior_ipxact [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == IP-XACT}]

launch_server "/home/charity/Local_Packages/tcl/tcl8.5.19-src/tcl8.5.19/bin/tclsh8.5"
start_client

# setting client local variable for ease of access
set chan $::tclapp::xilinx::tk_tunnel::sock

proc place_var_on_server {var_to_place chan} {
    set call_string [dict get [info frame -1] cmd]
    set var_ref_name [lindex $call_string 1]
    set str_command "::tclapp::xilinx::tk_tunnel::$var_ref_name"
    set str_command [join [split $str_command $] ""]
    # setting persistent server variable on server using client dynamic variable
    puts $chan "set $str_command \"$var_to_place\""
    # making the command sent in string form available on the server
    puts $chan "set ::tclapp::xilinx::tk_tunnel::str_command \"$str_command\""

    set verify_var [rexec_wait { \
        set test [subst $$::tclapp::xilinx::tk_tunnel::str_command]; \
        broadcast "puts stdout {$test}"; \
        return $test; \
    }]

    if {[string equal $var_to_place $verify_var]} {
        puts "Successfully passed variable $var_ref_name from Client to Server"
    } else {
        puts "Failed to pass variable $var_ref_name from Client to Server"
        error "couldn't pass variable $var_ref_name"
    }
} 

proc get_user_input {name_guess_from_client major_version_guess_from_client minor_version_guess_from_client chan} {
    # Placing variables on server
    place_var_on_server $name_guess_from_client $chan
    place_var_on_server $major_version_guess_from_client $chan
    place_var_on_server $minor_version_guess_from_client $chan

    # This is setting the key names so they are easily changeable in code
    set name_from_server_key name_from_server
    set major_version_from_server_key major_version_from_server
    set minor_version_from_server_key minor_version_from_server
    place_var_on_server $name_from_server_key $chan
    place_var_on_server $major_version_from_server_key $chan
    place_var_on_server $minor_version_from_server_key $chan

    # using persistent server variable in tk_tunnel process!
    set edited_user_input [rexec_wait { \
        \
        proc COMMENT {} { Setting local versions of variables that exist on the server }; \
        \
        variable name_key $::tclapp::xilinx::tk_tunnel::name_from_server_key; \
        variable minor_version_key $::tclapp::xilinx::tk_tunnel::minor_version_from_server_key; \
        variable major_version_key $::tclapp::xilinx::tk_tunnel::major_version_from_server_key; \
        \
        proc COMMENT {} { creating process to center the pop-up over the annoying vivado running process pop-up }; \
        \
        proc center_window {w width height} { \
            wm withdraw $w; \
            update idletasks; \
            set x [expr $::tclapp::xilinx::tk_tunnel::vivado_screenwidth/2 - $width/2 \
                - [winfo vrootx [winfo parent $w]]]; \
            set y [expr $::tclapp::xilinx::tk_tunnel::vivado_screenheight/2 - $height/2 \
                - [winfo vrooty [winfo parent $w]]]; \
            puts $x; \
            puts $y; \
            puts "screenwidth: [winfo screenwidth $w]"; \
            puts "reqwidth: [winfo reqwidth $w]"; \
            puts "vrootx of parent: [winfo vrootx [winfo parent $w]]"; \
            puts "screenheight: [winfo screenheight $w]"; \
            puts "reqheight: [winfo reqheight $w]"; \
            puts "vrooty of parent: [winfo vrooty [winfo parent $w]]"; \
            wm geom $w +$x+$y; \
            wm deiconify $w; \
        }; \
        \
        proc COMMENT {} { create the main pop-up window }; \
        \
        variable top [toplevel .top -takefocus 1]; \
        focus -force $top; \
        grab $top; \
        \
        proc COMMENT {} { creating process to create frames and labels dynamically }; \
        \
        proc create_frame_and_label {parent id text} { \
            variable frame [frame $parent.${id}_frame]; \
            pack $frame; \
            variable label [label $frame.${id}_label -text $text -wraplength 300];  \
            pack $label; \
            variable ret [list frame $frame label $label]; \
            return $ret; \
        }; \
        \
        proc COMMENT {} { create process to get a value from a dictionary }; \
        \
        proc get_value_from_key {in_dict key} { \
            return [dict get $in_dict $key]; \
        }; \
        proc create_error {parent id} { \
            set error_frame_label [create_frame_and_label $parent ${id}_error ""]; \
            set error_label [get_value_from_key $error_frame_label label]; \
            $error_label configure -foreground #ff0000 -font {TkDefaultFont 10 bold}; \
            return $error_label; \
        }; \
        \
        proc COMMENT {} { create the Main message, IP Name, IP version (major and minor) frames }; \
        \
        create_frame_and_label $top msg "Update the IP Version:\n"; \
        set name_frame_label [create_frame_and_label $top name "IP Name:"]; \
        set name_frame [get_value_from_key $name_frame_label frame]; \
        set version_frame_label [create_frame_and_label $top version "IP Version:"]; \
        set version_frame [get_value_from_key $version_frame_label frame]; \
        set version_label [get_value_from_key $version_frame_label label]; \
        variable version_error_label [create_error $version_frame version]; \
        set major_frame_label [create_frame_and_label $version_frame major "Major:"]; \
        set major_frame [get_value_from_key $major_frame_label frame]; \
        variable major_error_label [create_error $major_frame major]; \
        set minor_frame_label [create_frame_and_label $version_frame minor "Minor:"]; \
        set minor_frame [get_value_from_key $minor_frame_label frame]; \
        variable minor_error_label [create_error $minor_frame minor]; \
        \
        proc COMMENT {} { create the entry box for the name }; \
        \
        variable name $::tclapp::xilinx::tk_tunnel::name_guess_from_client; \
        variable name_entry_box [entry $name_frame.name -textvariable ::tclapp::xilinx::tk_tunnel::name -width 50]; \
        pack $name_entry_box; \
        \
        proc COMMENT {} { create the spinbox for the major version }; \
        \
        variable major_version $::tclapp::xilinx::tk_tunnel::major_version_guess_from_client; \
        variable major_version_spinbox [ttk::spinbox $major_frame.ver -textvariable ::tclapp::xilinx::tk_tunnel::major_version -from 1 \
            -increment 1 -to 100 -width 10 -state readonly -command { \
            set ::tclapp::xilinx::tk_tunnel::major_version [$::tclapp::xilinx::tk_tunnel::major_version_spinbox get]; \
            if {$::tclapp::xilinx::tk_tunnel::major_version > $::tclapp::xilinx::tk_tunnel::major_version_guess_from_client} { \
                set ::tclapp::xilinx::tk_tunnel::minor_version 0; \
            }; \
        }]; \
        pack $major_version_spinbox; \
        \
        proc COMMENT {} { create the entry box for the minor version }; \
        \
        variable minor_version $::tclapp::xilinx::tk_tunnel::minor_version_guess_from_client; \
        variable minor_version_entry_box [entry $minor_frame.ver -textvariable ::tclapp::xilinx::tk_tunnel::minor_version -width 25]; \
        pack $minor_version_entry_box; \
        \
        proc COMMENT {} { some visual settings for the spinbox }; \
        \
        ttk::style configure TSpinbox -arrowsize 15; \
        ttk::style map TSpinbox -fieldbackground {readonly #FFFFFF}; \
        \
        proc COMMENT {} { create the submit button }; \
        \
        variable btn [button $top.btn -text "submit" -command { \
            set ::tclapp::xilinx::tk_tunnel::name [$::tclapp::xilinx::tk_tunnel::name_entry_box get]; \
            set ::tclapp::xilinx::tk_tunnel::major_version [$::tclapp::xilinx::tk_tunnel::major_version_spinbox get]; \
            set ::tclapp::xilinx::tk_tunnel::minor_version [$::tclapp::xilinx::tk_tunnel::minor_version_entry_box get]; \
            if {$::tclapp::xilinx::tk_tunnel::major_version_guess_from_client == $::tclapp::xilinx::tk_tunnel::major_version && \
                $::tclapp::xilinx::tk_tunnel::minor_version_guess_from_client == $::tclapp::xilinx::tk_tunnel::minor_version} { \
                \
                $::tclapp::xilinx::tk_tunnel::version_error_label configure -text {You need to increase the version}; \
            } elseif {$::tclapp::xilinx::tk_tunnel::major_version_guess_from_client > $::tclapp::xilinx::tk_tunnel::major_version} { \
                \
                $::tclapp::xilinx::tk_tunnel::major_error_label configure -text "Major version cannot be less than previous version:\
                ($::tclapp::xilinx::tk_tunnel::major_version_guess_from_client)"; \
            } elseif {$::tclapp::xilinx::tk_tunnel::major_version_guess_from_client == $::tclapp::xilinx::tk_tunnel::major_version && \
                      $::tclapp::xilinx::tk_tunnel::minor_version_guess_from_client > $::tclapp::xilinx::tk_tunnel::minor_version} { \
                puts "You cannot create a version that is older than the current version (minor)"; \
                $::tclapp::xilinx::tk_tunnel::minor_error_label configure -text "Minor version cannot be less than previous version if major version has not increased:\
                ($tclapp::xilinx::tk_tunnel::minor_version_guess_from_client)"; \
            } else { \
                puts "You successfully updated the version"; \
                destroy $::tclapp::xilinx::tk_tunnel::top; \
            }; \
        }]; \
        pack $btn; \
        \
        proc COMMENT {} { center the pop-up and adjust the size and title }; \
        \
        wm attributes $top -topmost 1; \
        wm title $top "Set new version..."; \
        set width 600; \
        set height 300; \
        wm geom $top ${width}x${height}; \
        center_window $top $width $height; \
        \
        proc COMMENT {} { wait for user input and Submit button to be pressed }; \
        \
        tkwait window $top; \
        \
        proc COMMENT {} { after submission succeeds create the return list and return it to the client }; \
        \
        variable ret [list $name_key $name $major_version_key $major_version $minor_version_key $minor_version]; \
        broadcast "puts stdout {$ret}"; \
        return $ret; \
    }]

    puts $major_version_guess_from_client
    puts [get_value_from_key $edited_user_input $major_version_from_server_key]
    if {$major_version_guess_from_client == [get_value_from_key $edited_user_input $major_version_from_server_key] && \
        $minor_version_guess_from_client == [get_value_from_key $edited_user_input $minor_version_from_server_key]} {
        puts "You did not change the version"
    } elseif {$major_version_guess_from_client > [get_value_from_key $edited_user_input $major_version_from_server_key]} { 
        puts "You cannot create a version that is older than the current version (major)"
    } elseif {$major_version_guess_from_client == [get_value_from_key $edited_user_input $major_version_from_server_key] && \
              $minor_version_guess_from_client > [get_value_from_key $edited_user_input $minor_version_from_server_key]} {
        puts "You cannot create a version that is older than the current version (minor)"
    } else {
        puts "You successfully updated the version"
    }

    return $edited_user_input
}

proc get_value_from_key {in_dict key} {
    return [dict get $in_dict $key]
}

# some basics:
# get the directory of the current project
set proj_dir [get_property DIRECTORY [current_project]]
# get the current repo path:
set ip_repos_dir [get_property IP_REPO_PATHS [current_fileset]]
# get the current component.xml
set curr_ip_def [get_files -of_objects [get_filesets -filter FILESET_TYPE==DesignSrcs] -filter FILE_TYPE==IP-XACT]
# open the above core and set it as the "current_core"
ipx::open_core $curr_ip_def
set from_core [ipx::current_core]
# get the vendor for the "current_core"
set vendor [get_property vendor [ipx::current_core]]
# get the library for the current_core
set library [get_property library [ipx::current_core]]
# get the name for the current_core
set name [get_property name [ipx::current_core]]
# get the version for the current_core
set version [get_property version [ipx::current_core]]
# get the vendor_display_name for the current_core
set vendor_display_name [get_property vendor_display_name [ipx::current_core]]
# get the company_url for the current_core
set url [get_property company_url [ipx::current_core]]
# get display_name for the current_core
set display_name_prev [get_property display_name [ipx::current_core]]

# setting a dynamic string on client
set name_guess_on_client $name
set version_split [split $version .]
set major_version_guess_on_client [lindex $version_split 0]
set minor_version_guess_on_client [join [lrange $version_split 1 end] .]

# attempting to set up to place the pop-up from tk_tunnel over the background process popup from vivado
set vivado_pid [pid]
set vivado_window_info [exec {*}"wmctrl -lGp | awk {/Vivado/ { print \$0 }}"]
set vivado_window_id [exec {*}"echo $vivado_window_info | awk {/$vivado_pid/ {print \$1 }}"]
# puts "the window id: $vivado_window_id"

place_var_on_server $vivado_window_id $chan

set vivado_screenwidth [exec {*}"echo $vivado_window_info | awk {/$vivado_pid/ { print \$6 }}"]
set vivado_xoffset [exec {*}"echo $vivado_window_info | awk {/$vivado_pid/ {print \$4 }}"]
set vivado_screenwidth [expr $vivado_screenwidth + $vivado_xoffset*2]
set vivado_screenheight [exec {*}"echo $vivado_window_info | awk {/$vivado_pid/ { print \$7 }}"]
place_var_on_server $vivado_screenwidth $chan
place_var_on_server $vivado_screenheight $chan

set new_version [get_user_input $name_guess_on_client $major_version_guess_on_client $minor_version_guess_on_client $chan]

# close the tk_tunnel instance
close_tk_tunnel

# parsing server return values
set name_from_server [dict get $new_version name_from_server]
set major_version_from_server [dict get $new_version major_version_from_server]
set minor_version_from_server [dict get $new_version minor_version_from_server]

puts "name: $name_from_server"
puts "major version: $major_version_from_server"
puts "minor version: $minor_version_from_server"

set display_name ${name_from_server}_v${major_version_from_server}_$minor_version_from_server

# close the ip def
ipx::unload_core [ipx::current_core]
# We do what vivado documentation recommends:
# manually copy the packaged IP directory contents to a new location
set new_ip_dir_name $ip_repos_dir/$display_name
set old_ip_dir_name $ip_repos_dir/$display_name_prev
set old_ip_copy_dir $ip_repos_dir/${display_name_prev}_temp
file copy $old_ip_dir_name $old_ip_copy_dir

file rename $old_ip_dir_name $new_ip_dir_name

# rename $old_ip_new_loc directory to $old_ip_orig_loc directory
file rename $old_ip_copy_dir $old_ip_dir_name

# update the referenced IPXACT file
set new_ipxact $new_ip_dir_name/component.xml
update_files -from_files $new_ipxact -to_files $prior_ipxact

# reopen new IP def so user can continue process
ipx::open_ipxact_file $new_ipxact

# make the version changes 
set_property version $major_version_from_server.$minor_version_from_server [ipx::current_core]
set_property name $name_from_server [ipx::current_core]
set_property display_name $display_name [ipx::current_core]
set_property description [string tolower $display_name] [ipx::current_core]

# do this so that you can delete the old ones
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
update_ip_catalog -rebuild

# delete the old xgui files
set xgui_files [glob $new_ip_dir_name/xgui/*]
foreach file $xgui_files {
    if {![string equal $file $new_ip_dir_name/xgui/$display_name.tcl]} {
        file delete -- $file
    }
}

ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

return






########################################
# code to undo above if you hit cancel in the Vivado IP Packager after or just need to undo for some reason
set unsaved_ipxact [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == IP-XACT}]

update_files -from_files /$prior_ipxact -to_files $unsaved_ipxact -filesets [get_filesets sources_1]

file delete $unsaved_ipxact
file delete -force -- [file dirname $unsaved_ipxact]/xgui
file delete -force -- [file dirname $unsaved_ipxact]/src
file delete -force -- [file dirname $unsaved_ipxact]/gui
# relying on tcl to only delete if the directory is empty
file delete -- [file dirname $unsaved_ipxact]

update_ip_catalog -rebuild
