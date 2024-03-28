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
        # TODO make this error more specific.
        error "couldn't pass variable $var_ref_name"
    }
} 

proc get_user_input {name_guess_from_client major_version_guess_from_client minor_version_guess_from_client chan} {
    # Placing variables on server
    place_var_on_server $name_guess_from_client $chan
    place_var_on_server $major_version_guess_from_client $chan
    place_var_on_server $minor_version_guess_from_client $chan

    # This is setting the key names so they are easily changable in code
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


# set ::tclapp::xilinx::tk_tunnel::name_from_client [.top.ent get]; \
        # variable version_from_client "placeholder"; \
        # set version_entry [entry $top.ver -textvariable ::tclapp::xilinx::tk_tunnel::version_from_client -width 50]; \
        # pack $version_entry; \

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

# need to have pop-up that asks for new version here
# should use old version as guess...make it clear in popup that this should be changed
# then set a variable for new version
set vivado_pid [pid]
set vivado_window_info [exec {*}"wmctrl -lGp | awk {/Vivado/ { print \$0 }}"]
set vivado_window_id [exec {*}"echo $vivado_window_info | awk {/$vivado_pid/ {print \$1 }}"]
puts "the window id: $vivado_window_id"

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

set name_from_server [dict get $new_version name_from_server]
set major_version_from_server [dict get $new_version major_version_from_server]
set minor_version_from_server [dict get $new_version minor_version_from_server]

puts "name: $name_from_server"
puts "major version: $major_version_from_server"
puts "minor version: $minor_version_from_server"

set display_name ${name_from_server}_v${major_version_from_server}_$minor_version_from_server



# OK so what if:
# 0.
# close the ip def (could be moved much earlier)
ipx::unload_core [ipx::current_core]
# then
# We do what vivado recommends:
# 1.
# manually copy the packaged IP directory contents to a new location
set new_ip_dir_name $ip_repos_dir/$display_name
set old_ip_dir_name $ip_repos_dir/$display_name_prev
set old_ip_copy_dir $ip_repos_dir/${display_name_prev}_temp
file copy $old_ip_dir_name $old_ip_copy_dir



# try instead:
file rename $old_ip_dir_name $new_ip_dir_name

# 6.
# rename $old_ip_new_loc direcetory to $old_ip_orig_loc directory
file rename $old_ip_copy_dir $old_ip_dir_name


#try one at a time

# delete old xgui and gui files (they will be regnerated) NOPE
# file delete -force -- $new_ip_dir_name/xgui
# file delete -force -- $new_ip_dir_name/gui

set new_ipxact $new_ip_dir_name/component.xml
update_files -from_files $new_ipxact -to_files $prior_ipxact

# 8.
# reopen new IP def so user can continue process
# won't need to
ipx::open_ipxact_file $new_ipxact
# return
# maybe can do it here? NOPE
# delete old xgui and gui files (they will be regnerated) NOPE
# file delete -force -- $new_ip_dir_name/xgui
# file delete -force -- $new_ip_dir_name/gui

# 3. 
# make the version changes 
set_property version $major_version_from_server.$minor_version_from_server [ipx::current_core]
set_property name $name_from_server [ipx::current_core]
# set_property vendor_display_name $vendor_display_name [ipx::current_core]
# set_property company_url $url [ipx::current_core]
set_property display_name $display_name [ipx::current_core]
set_property description [string tolower $display_name] [ipx::current_core]

# do this so that you can delete the old ones...?
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
update_ip_catalog -rebuild




# TODO delete the old xgui files
set xgui_files [glob $new_ip_dir_name/xgui/*]
foreach file $xgui_files {
    if {![string equal $file $new_ip_dir_name/xgui/$display_name.tcl]} {
        file delete -- $file
    }
}

# do i need to do this, if nothing more than to make the person feel better
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

return



# DONT
# 2.
# open the $old_ip_orig_loc 
# ipx::open_ipxact_file $prior_ipxact

# # 3. 
# # make the version changes 
# set_property version $major_version_from_server.$minor_version_from_server [ipx::current_core]
# set_property name $name_from_server [ipx::current_core]
# # set_property vendor_display_name $vendor_display_name [ipx::current_core]
# # set_property company_url $url [ipx::current_core]
# set_property display_name $display_name [ipx::current_core]
# set_property description [string tolower $display_name] [ipx::current_core]
# return 





# # return
# # 4.
# # save ip and close
# # what would happen by GUI way so we get the new files
# ipx::create_xgui_files [ipx::current_core]
# ipx::update_checksums [ipx::current_core]
# update_ip_catalog -rebuild

# # weirdly there is no way to have a new gtcl file created (as in with a new version name), so we just deal. It will get updated but it just won't chagne the version name...seems once you make one for a project that is the name you get forevermore...seems like an oversite...

# # should i replace with:
# # before doing this rename the xgui file? nope, just remakes the old name one
# # what if i DELETE it?, nope
# # ipx::create_default_gui_files [ipx::current_core]
# # instead lets rename the file, then change the contents of the xgui file, then update checksums, then update ip, then save_core, then check if the gtcl reference gets updated? nOPE
# # so instead: 
# # copy the gtcl file, save the name of the file (just the name, not the path), create new xgui file, change the contents of the xgui file, change the contents of the .xml file based on the string search for the gtcl file, then update checksums, then update ip, then save_core, then check the gtcl ref in the xml file
# # rename, no hold on COPY the file
# # file copy /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/gui/Side_Stream_Scrambler_Descrambler_v2_2.gtcl /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/gui/Side_Stream_Scrambler_Descrambler_v2_3.gtcl
# # # save the name of the file (just the name, not the path)...is something returned from file cmd??
# # set temp Side_Stream_Scrambler_Descrambler_v2_3.gtcl
# # # generate new xgui file
# # ipx::create_xgui_files [ipx::current_core]
# # # change the contents of the xgui file...should make both these replacements be the same mapping...second one
# # set mapping [list _v${major_version_guess_on_client}_$minor_version_guess_on_client _v${major_version_from_server}_$minor_version_from_server]
# # fileutil::updateInPlace /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/xgui/Side_Stream_Scrambler_Descrambler_v2_3.tcl [list string map $mapping]
# # # change the contents of the .xml file based on the string search for the gtcl file
# # fileutil::updateInPlace /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/component.xml [list string map {Side_Stream_Scrambler_Descrambler_v2_2.gtcl Side_Stream_Scrambler_Descrambler_v2_3.gtcl}]
# # # update checksums
# # ipx::update_checksums [ipx::current_core]

# # save_core
# ipx::save_core [ipx::current_core]
# # update ip
# # update_ip_catalog -rebuild

# # # for every file replace the vx_x part in both the name and the contents
# # foreach filename $filenames_to_change {
# #     set new_file_name [string map $mapping $filename]
# #     file rename $filename $new_file_name
# #     fileutil::updateInPlace $new_file_name [list string map $mapping]

# # }


# # ipx::save_core [ipx::current_core]
# ipx::unload_core [ipx::current_core]
# # TEST skip to here
# # 5. 
# # rename #old_ip_orig_loc directory to #new_ip_loc directory
# file rename $old_ip_dir_name $new_ip_dir_name

# # 6.
# # rename $old_ip_new_loc direcetory to $old_ip_orig_loc directory
# file rename $old_ip_copy_dir $old_ip_dir_name

# # 7.
# # update ip catalog and rebuild
# # don't yet
# update_ip_catalog -rebuild

# # 7.a
# # update_files
# set new_ipxact $new_ip_dir_name/component.xml
# update_files -from_files $new_ipxact -to_files $prior_ipxact

# # 8.
# # reopen new IP def so user can continue process
# # won't need to
# ipx::open_ipxact_file $new_ipxact

# # TODO consider removing the old xgui files...don't think they are needed

# return

# # TODO should i close the loaded core first?

# # try above again, but then don't close the new one before doing the merge thing below
# # TODO
# # run the IP packagere THEN replace all except the component.xml...
# # this worked:
# # ipx::package_project -root_dir $ip_repos_dir/$display_name -vendor $vendor -library $library -taxonomy /UserIP -import_files \
# #     -version $major_version_from_server.$minor_version_from_server -name $name_from_server

# # set unsaved_ipxact [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == IP-XACT}]

# # # there is danger in doing it this way....if lots has changed
# # file delete -force -- [file dirname $unsaved_ipxact]/xgui
# # file delete -force -- [file dirname $unsaved_ipxact]/src
# # file delete -force -- [file dirname $unsaved_ipxact]/gui

# # # TODO figure out how to not have to hard code the directories
# # file copy $ip_repos_dir/$display_name_prev/gui $ip_repos_dir/$display_name
# # file copy $ip_repos_dir/$display_name_prev/xgui $ip_repos_dir/$display_name
# # file copy $ip_repos_dir/$display_name_prev/src $ip_repos_dir/$display_name

# # set filenames_to_change [fileutil::findByPattern $ip_repos_dir/$display_name *v${major_version_guess_on_client}_$minor_version_guess_on_client*]
# # set mapping [list _v${major_version_guess_on_client}_$minor_version_guess_on_client _v${major_version_from_server}_$minor_version_from_server]
# # foreach filename $filenames_to_change {
# #     set new_file_name [string map $mapping $filename]
# #     file rename $filename $new_file_name
# #     fileutil::updateInPlace $new_file_name [list string map $mapping]

# # }

# # # do i need this one? doesn't seem like it
# # # ipx::merge_project_changes hdl_parameters [ipx::current_core]
# # # try run to here:
# # ipx::unload_core $unsaved_ipxact
# # ipx::open_core $unsaved_ipxact
# # # this only gets the tooltip stuff (maybe some other stuff)
# # ipx::merge_project_changes hdl_parameters [ipx::current_core]
# # # TODO figure out the gtcl file...


# # # run to here then look at parameters
# # set_property vendor_display_name $vendor_display_name [ipx::current_core]
# # set_property company_url $url [ipx::current_core]
# # # set_property display_name $display_name [ipx::current_core] # apparently not needed
# # set_property description [string tolower $display_name] [ipx::current_core]

# # update_ip_catalog -rebuild
# # # think this is it


# # # # then close with save
# # # ipx::save_core [ipx::current_core]
# # # # do i need to manually update the ip catalog?

# # # # close
# # # ipx::unload_core $unsaved_ipxact
# # # ipx::open_core $unsaved_ipxact
# # # ipx::merge_project_changes hdl_parameters [ipx::current_core]
# # # ipx::save_core [ipx::current_core]

# # # then check the Customization parameters...



# # # try this:
# # # maybe just save (or not) then update ip catalog, then unload core, then reopen

# # # will this update the component.xml?
# # ipx::update_checksums [ipx::current_core] 
# # # do i do this before above?
# # ipx::merge_project_changes hdl_parameters [ipx::current_core]
# # # do i need to:
# # update_ip_catalog -rebuild -repo_path /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages


# # ############

# # # TODO instead of setting this manually, just copy the files then update version
# # file copy [file dirname $prior_ipxact] $ip_repos_dir/$display_name
# # # what if i don't copy the .xml file and just change the name of the v2_2 files to new vx_x?
# # file delete $ip_repos_dir/$display_name/component.xml

# # # get all files in directory
# # set filenames_to_change [fileutil::findByPattern $ip_repos_dir/$display_name *v${major_version_guess_on_client}_$minor_version_guess_on_client*]
# # set mapping [list _v${major_version_guess_on_client}_$minor_version_guess_on_client _v${major_version_from_server}_$minor_version_from_server]
# # # for every file replace the vx_x part in both the name and the contents
# # foreach filename $filenames_to_change {
# #     set new_file_name [string map $mapping $filename]
# #     file rename $filename $new_file_name
# #     fileutil::updateInPlace $new_file_name [list string map $mapping]

# # }

# # # TODO close the ip instance (old)


# # # what vivado runs when you click Tools > Create and Package New IP... (except with some additions in library and everything after -import_files)
# # # ipx::package_project -root_dir /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/delme -vendor unh.edu -library user -taxonomy /UserIP -import_files
# # ipx::package_project -root_dir $ip_repos_dir/$display_name -vendor $vendor -library $library -taxonomy /UserIP -import_files \
# #     -version $major_version_from_server.$minor_version_from_server -name $name_from_server


# # # set other things
# # # current_core is automatically reset to this new one
# # set_property vendor_display_name $vendor_display_name [ipx::current_core]
# # set_property company_url $url [ipx::current_core]
# # # set_property display_name $display_name [ipx::current_core] # apparently not needed
# # set_property description [string tolower $display_name] [ipx::current_core]

# # return

# # # TODO figure out how to do this dynamically:
# # set_property tooltip {Seed for the scrambler, should never be all zeros} [ipgui::get_guiparamspec -name "SEED" -component [ipx::current_core] ]
# # set_property widget {hexEdit} [ipgui::get_guiparamspec -name "SEED" -component [ipx::current_core] ]
# # set_property enablement_tcl_expr {expr $SEED > 0} [ipx::get_user_parameters SEED -of_objects [ipx::current_core]]
# # ipx::update_dependency [ipx::get_user_parameters SEED -of_objects [ipx::current_core]]

# # # TODO get all tooltips

# # # TODO get all parameter names:
# # set user_params_from_tool [ipx::get_user_parameters -of_objects $from_core]
# # set user_params [list]
# # foreach param $user_params_from_tool {
# #     # puts $param
# #     foreach item $param {
# #         if {!([string equal $item user_parameter] || [regexp ^component_[0-9]+$ $item] || [string equal $item Component_Name])} {
# #             # add to a list
# #             lappend user_params $item
# #             # puts $item
# #         }
# #         # puts $item
# #     }
# # }
# # puts $user_params
# # foreach param $user_params {
# #     set curr_obj [ipx::get_user_parameters $param -of_objects $from_core]
# #     set curr_props [list_property $curr_obj]
# #     puts "\nPARAM: $param"
# #     # for each property get the current value
# #     foreach prop $curr_props {
# #         puts "PROPERTY: $prop:"
# #         puts "VALUE: [get_property $prop $curr_obj]"
# #         # set the new one to that

# #     }
# # }

# # # for each parameter name get all the info about it:
# # # tooltips:




# # if you decide not to save changes the files will still exist in the directory...

# # TODO figure out why if you copy paste this into vivado tcl console it works fine but if you source the tcl file it doesn't....
# # might be related to the fact that ipx::unload_core doesn't delete the folder and ALSO doesn't set the component.xml file in the project to refer to the prior one before the aborting of changes...
# # unload_core apparently has nothing to do with saving or not saving....thats werid its run whether you save or not

# # how i recovered recently: gui ran:
# # export_ip_user_files -of_objects  [get_files /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/_v_/component.xml] -no_script -reset -force -quiet
# # remove_files  /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/_v_/component.xml
# # # I ran:
# # add_files /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/component.xml
# # # gui ran:
# # set_property file_type IP-XACT [get_files  /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/component.xml]

# # set prior_ipxact "/home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/component.xml"
# # set unsaved_ipxact "/home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/SIde_Stream_Scrambler_Descrambler_fresh/side-stream-scrambler-descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_3/component.xml"

# # for some reason running all 4 (or just the first 3) of these crashes vivado TODO figure out way to wait until things are done
# # set unsaved_ipxact [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == IP-XACT}]
# # remove_files $unsaved_ipxact
# # # this doesn't work, crashed vivado
# # # after idle add_files $prior_ipxact 
# # after 1000
# # # seems i can run the following 2 together
# # add_files $prior_ipxact
# # set_property file_type IP-XACT [get_files $prior_ipxact]

# # # file delete -force -- [file dirname $unsaved_ipxact]

# # file delete $unsaved_ipxact
# # file delete -force -- [file dirname $unsaved_ipxact]/xgui
# # file delete -force -- [file dirname $unsaved_ipxact]/src
# # file delete -force -- [file dirname $unsaved_ipxact]/gui
# # file delete -- [file dirname $unsaved_ipxact]

# instead use:
# this will recover from inadvertant creation of new IP
# OR just right click the component.xml and replace the file with the old one, go delete the directory, and then run update_ip_catalog -rebuild
# TODO make this into a proc that is defined so that the person can easily undo what they did
set unsaved_ipxact [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == IP-XACT}]

update_files -from_files /$prior_ipxact -to_files $unsaved_ipxact -filesets [get_filesets sources_1]

file delete $unsaved_ipxact
file delete -force -- [file dirname $unsaved_ipxact]/xgui
file delete -force -- [file dirname $unsaved_ipxact]/src
file delete -force -- [file dirname $unsaved_ipxact]/gui
# TODO add check if directory empty instead of relying on tcl to do it for you
file delete -- [file dirname $unsaved_ipxact]

update_ip_catalog -rebuild


# if you accidentally disable an IP you can run this to enable it
# update_ip_catalog -enable_ip /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages/Side_Stream_Scrambler_Descrambler_v2_2/component.xml -repo_path /home/charity/Programs/Xilinx/Projects/BitBucketRepos/T1L_Thesis/Side_Stream_Scrambler_Descrambler/packages
# update_ip_catalog -enable_ip <path_to_repo>/<version_folder>/component.xml <path_to_repo>

# commands to set IP variables, that I want to reverse engineer the get versions
# set_property vendor unh.edu.c [ipx::current_core]
# set_property display_name Side_Stream_Scrambler_Descrambler_v2_2e [ipx::current_core]
# set_property description side_stream_scrambler_descrambler_v2_2e [ipx::current_core]
# set_property vendor_display_name {UNH - Charity C Reed} [ipx::current_core]
# set_property company_url https://www.unh.edu [ipx::current_core]

# other helpful things
# convert string to lower case
# string tolower $name

# ############################

# wmctrl -lGp | awk '/287323/ { print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7}'

# where $1 = window id
# $2 = desktop number
# $3 = pid
# $4 = x-offset: 1920
# $5 = y-offset: 74
# $6 = width: 1920
# $7 = height: 1043

# wmctrl -lp | awk '/287323/ { print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7}'
# where:
# $1 = window id
# $2 = desktop number
# $3 = pid
# $4 = client machine name
# $5 = window title


# 1742 so this must be the x without padding...(but *2 is 3484...no where near 1920 width..., but not *2 it is...)
# 519 this is the y without padding (*2 is 1038 pretty close to 1043 height)

# screenwidth: 3840, this is twice the x-offset and twice the width
# reqwidth: 356
# vrootx of parent: 0
# screenheight: 1080, 
# reqheight: 42
# vrooty of parent: 0
# so I think if I modified the computation above to use the vivado vivado_screenwidth and vivado_screenheight instead of screenwidth and screenheight it might work...

# See working above...

# keeping for reference: 
        # proc create_frame_and_label {parent id text} { \
        #     variable ${id}_frame [frame $parent.${id}_frame]; \
        #     pack [subst $[subst ${id}_frame]]; \
        #     variable ${id}_label [label [subst $[subst ${id}_frame]].${id}_label -text $text];  \
        #     pack [subst $[subst ${id}_label]]; \
        #     variable ret [list frame [subst $[subst ${id}_frame]] label [subst $[subst ${id}_label]]]; \
        #     return $ret; \
        # }; \